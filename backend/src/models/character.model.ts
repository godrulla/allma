export interface Character {
  id: string;
  userId: string;
  name: string;
  avatar: string;
  personality: Personality;
  currentMood?: string;
  relationshipLevel?: number;
  memories?: Memory[];
  createdAt: Date;
  updatedAt: Date;
  isPublic: boolean;
  tags: string[];
}

export interface Personality {
  traits: string[];
  interests: string[];
  backstory: string;
  voiceStyle: string;
  emotionalRange: string;
  quirks?: string[];
  values?: string[];
  goals?: string[];
}

export interface Memory {
  id: string;
  content: string;
  importance: number;
  timestamp: Date;
  emotionalContext?: string;
  topics: string[];
}