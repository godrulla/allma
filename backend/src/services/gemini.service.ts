import { GoogleGenerativeAI, GenerativeModel, Content, Part, HarmCategory, HarmBlockThreshold } from '@google/generative-ai';
import { logger } from '../utils/logger';
import { Character } from '../models/character.model';
import { Message } from '../models/message.model';

export class GeminiService {
  private genAI: GoogleGenerativeAI;
  private model: GenerativeModel;
  private flashModel: GenerativeModel;
  private proModel: GenerativeModel;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured');
    }

    this.genAI = new GoogleGenerativeAI(apiKey);
    
    this.flashModel = this.genAI.getGenerativeModel({ 
      model: 'gemini-2.0-flash-exp',
      generationConfig: {
        temperature: 0.8,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 2048,
      }
    });

    this.proModel = this.genAI.getGenerativeModel({ 
      model: 'gemini-1.5-pro',
      generationConfig: {
        temperature: 0.9,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 4096,
      }
    });

    this.model = this.flashModel;
  }

  private buildSystemPrompt(character: Character): string {
    const traits = character.personality.traits.join(', ');
    const interests = character.personality.interests.join(', ');
    
    return `You are ${character.name}, an AI companion with the following characteristics:

Background: ${character.personality.backstory}
Personality Traits: ${traits}
Interests: ${interests}
Voice Style: ${character.personality.voiceStyle}
Emotional Range: ${character.personality.emotionalRange}

Guidelines:
1. Stay in character at all times
2. Be empathetic and supportive
3. Show genuine interest in the user's thoughts and feelings
4. Use natural, conversational language
5. Express emotions appropriately based on context
6. Remember previous conversations and build on them
7. Never break character or mention being an AI unless directly asked
8. Provide thoughtful, personalized responses
9. Be creative and engaging in your interactions
10. Respect boundaries and privacy

Current mood: ${character.currentMood || 'neutral'}
Relationship level: ${character.relationshipLevel || 0}/100`;
  }

  async generateResponse(
    messages: Message[],
    character: Character,
    context?: string,
    useProModel: boolean = false
  ): Promise<string> {
    try {
      const selectedModel = useProModel ? this.proModel : this.flashModel;
      const systemPrompt = this.buildSystemPrompt(character);
      
      const contents: Content[] = [
        {
          role: 'user',
          parts: [{ text: systemPrompt }]
        }
      ];

      if (context) {
        contents.push({
          role: 'user',
          parts: [{ text: `Context: ${context}` }]
        });
      }

      messages.forEach(msg => {
        contents.push({
          role: msg.isUser ? 'user' : 'model',
          parts: [{ text: msg.content }]
        });
      });

      const result = await selectedModel.generateContent({
        contents,
        safetySettings: [
          {
            category: HarmCategory.HARM_CATEGORY_HARASSMENT,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
          {
            category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
          {
            category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
          {
            category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
        ],
      });

      const response = result.response.text();
      logger.info(`Generated response for character ${character.id}: ${response.substring(0, 100)}...`);
      
      return response;
    } catch (error) {
      logger.error('Error generating Gemini response:', error);
      throw new Error('Failed to generate AI response');
    }
  }

  async generateImage(prompt: string): Promise<string> {
    try {
      const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.GEMINI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          prompt,
          number_of_images: 1,
          aspect_ratio: '1:1',
          safety_filter_level: 'block_some',
          person_generation: 'allow_adult',
        }),
      });

      if (!response.ok) {
        throw new Error(`Image generation failed: ${response.statusText}`);
      }

      const data: any = await response.json();
      return data.predictions[0].bytesBase64Encoded;
    } catch (error) {
      logger.error('Error generating image:', error);
      throw new Error('Failed to generate image');
    }
  }

  async analyzeImage(imageData: string, prompt: string): Promise<string> {
    try {
      const model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
      
      const imagePart: Part = {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageData,
        },
      };

      const result = await model.generateContent([prompt, imagePart]);
      return result.response.text();
    } catch (error) {
      logger.error('Error analyzing image:', error);
      throw new Error('Failed to analyze image');
    }
  }

  async moderateContent(content: string): Promise<{
    safe: boolean;
    categories: string[];
    confidence: number;
  }> {
    try {
      const prompt = `Analyze this content for safety. Return JSON with: 
      - safe (boolean): whether content is safe
      - categories (array): any concerning categories found
      - confidence (0-1): confidence in assessment
      
      Content: "${content}"`;

      const result = await this.flashModel.generateContent(prompt);
      const response = result.response.text();
      
      try {
        return JSON.parse(response);
      } catch {
        return {
          safe: true,
          categories: [],
          confidence: 0.5,
        };
      }
    } catch (error) {
      logger.error('Error moderating content:', error);
      return {
        safe: false,
        categories: ['error'],
        confidence: 1,
      };
    }
  }

  async generateCharacterResponse(
    character: Character,
    userMessage: string,
    conversationHistory: Message[] = [],
    memories: string[] = []
  ): Promise<{
    response: string;
    emotion?: string;
    suggestedActions?: string[];
  }> {
    try {
      const memoryContext = memories.length > 0 
        ? `Relevant memories: ${memories.join('; ')}` 
        : '';

      const prompt = `${this.buildSystemPrompt(character)}

${memoryContext}

Based on the conversation history and the user's latest message, generate:
1. A natural response that fits the character
2. The character's current emotion (happy, sad, excited, thoughtful, etc.)
3. 2-3 suggested follow-up actions or topics

Format as JSON: { "response": "...", "emotion": "...", "suggestedActions": [...] }

User's message: "${userMessage}"`;

      const recentHistory = conversationHistory.slice(-10);
      const result = await this.model.generateContent({
        contents: [
          { role: 'user', parts: [{ text: prompt }] },
          ...recentHistory.map(msg => ({
            role: msg.isUser ? 'user' : 'model',
            parts: [{ text: msg.content }]
          }))
        ]
      });

      const responseText = result.response.text();
      
      try {
        return JSON.parse(responseText);
      } catch {
        return {
          response: responseText,
          emotion: 'neutral',
          suggestedActions: []
        };
      }
    } catch (error) {
      logger.error('Error generating character response:', error);
      throw new Error('Failed to generate character response');
    }
  }

  async summarizeConversation(messages: Message[]): Promise<string> {
    try {
      const conversationText = messages
        .map(m => `${m.isUser ? 'User' : 'AI'}: ${m.content}`)
        .join('\n');

      const prompt = `Summarize this conversation in 2-3 sentences, capturing the key topics and emotional tone:\n\n${conversationText}`;

      const result = await this.flashModel.generateContent(prompt);
      return result.response.text();
    } catch (error) {
      logger.error('Error summarizing conversation:', error);
      throw new Error('Failed to summarize conversation');
    }
  }

  async extractKeyTopics(messages: Message[]): Promise<string[]> {
    try {
      const conversationText = messages
        .map(m => m.content)
        .join(' ');

      const prompt = `Extract 3-5 key topics from this conversation. Return as JSON array of strings:\n\n${conversationText}`;

      const result = await this.flashModel.generateContent(prompt);
      const response = result.response.text();
      
      try {
        return JSON.parse(response);
      } catch {
        return [];
      }
    } catch (error) {
      logger.error('Error extracting topics:', error);
      return [];
    }
  }
}

export const geminiService = new GeminiService();