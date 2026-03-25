import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth.middleware';
import { geminiService } from '../services/gemini.service';
import { db, collections, toFirestoreTimestamp } from '../config/firebase';
import { AppError } from '../middleware/errorHandler';
import { Message, Conversation } from '../models/message.model';
import { Character } from '../models/character.model';
import { io } from '../index';
import { v4 as uuidv4 } from 'uuid';
import Joi from 'joi';

const router = Router();

const sendMessageSchema = Joi.object({
  conversationId: Joi.string().required(),
  characterId: Joi.string().required(),
  message: Joi.string().min(1).max(5000).required(),
  attachments: Joi.array().items(Joi.object({
    type: Joi.string().valid('image', 'audio', 'file'),
    url: Joi.string().uri(),
    mimeType: Joi.string(),
    size: Joi.number()
  })).optional()
});

router.post('/send', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { error, value } = sendMessageSchema.validate(req.body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const { conversationId, characterId, message, attachments } = value;
    const userId = req.userId!;

    let conversation: Conversation;
    const conversationRef = db().collection(collections.conversations).doc(conversationId);
    const conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      conversation = {
        id: conversationId,
        userId,
        characterId,
        messages: [],
        startedAt: new Date(),
        lastMessageAt: new Date(),
        isActive: true
      };
      await conversationRef.set(conversation);
    } else {
      conversation = conversationDoc.data() as Conversation;
      
      if (conversation.userId !== userId) {
        throw new AppError('Unauthorized access to conversation', 403);
      }
    }

    const characterDoc = await db().collection(collections.characters).doc(characterId).get();
    if (!characterDoc.exists) {
      throw new AppError('Character not found', 404);
    }
    const character = characterDoc.data() as Character;

    const userMessage: Message = {
      id: uuidv4(),
      conversationId,
      content: message,
      isUser: true,
      timestamp: new Date(),
      attachments
    };

    await conversationRef.collection('messages').doc(userMessage.id).set({
      ...userMessage,
      timestamp: toFirestoreTimestamp(userMessage.timestamp)
    });

    io.to(`conversation:${conversationId}`).emit('new_message', userMessage);

    const recentMessages = await conversationRef
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .limit(20)
      .get();

    const messageHistory = recentMessages.docs
      .map(doc => doc.data() as Message)
      .reverse();

    const aiResponse = await geminiService.generateCharacterResponse(
      character,
      message,
      messageHistory
    );

    const aiMessage: Message = {
      id: uuidv4(),
      conversationId,
      content: aiResponse.response,
      isUser: false,
      timestamp: new Date(),
      emotion: aiResponse.emotion
    };

    await conversationRef.collection('messages').doc(aiMessage.id).set({
      ...aiMessage,
      timestamp: toFirestoreTimestamp(aiMessage.timestamp)
    });

    await conversationRef.update({
      lastMessageAt: toFirestoreTimestamp(new Date()),
      mood: aiResponse.emotion
    });

    io.to(`conversation:${conversationId}`).emit('new_message', aiMessage);

    res.json({
      success: true,
      data: {
        userMessage,
        aiMessage,
        suggestedActions: aiResponse.suggestedActions
      }
    });
  } catch (error) {
    next(error);
  }
});

router.get('/conversations', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    
    const conversationsSnapshot = await db()
      .collection(collections.conversations)
      .where('userId', '==', userId)
      .orderBy('lastMessageAt', 'desc')
      .limit(50)
      .get();

    const conversations = await Promise.all(
      conversationsSnapshot.docs.map(async (doc) => {
        const data = doc.data() as Conversation;
        
        const messagesSnapshot = await doc.ref
          .collection('messages')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();

        const lastMessage = messagesSnapshot.empty 
          ? null 
          : messagesSnapshot.docs[0].data();

        return {
          ...data,
          lastMessage
        };
      })
    );

    res.json({
      success: true,
      data: conversations
    });
  } catch (error) {
    next(error);
  }
});

router.get('/conversation/:id/messages', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;
    const { limit = 50, before } = req.query;

    const conversationDoc = await db().collection(collections.conversations).doc(id).get();
    
    if (!conversationDoc.exists) {
      throw new AppError('Conversation not found', 404);
    }

    const conversation = conversationDoc.data() as Conversation;
    
    if (conversation.userId !== userId) {
      throw new AppError('Unauthorized access to conversation', 403);
    }

    let query = conversationDoc.ref
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .limit(Number(limit));

    if (before) {
      query = query.startAfter(before);
    }

    const messagesSnapshot = await query.get();
    const messages = messagesSnapshot.docs
      .map(doc => doc.data() as Message)
      .reverse();

    res.json({
      success: true,
      data: messages
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/conversation/:id', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const conversationRef = db().collection(collections.conversations).doc(id);
    const conversationDoc = await conversationRef.get();
    
    if (!conversationDoc.exists) {
      throw new AppError('Conversation not found', 404);
    }

    const conversation = conversationDoc.data() as Conversation;
    
    if (conversation.userId !== userId) {
      throw new AppError('Unauthorized access to conversation', 403);
    }

    const messagesSnapshot = await conversationRef.collection('messages').get();
    const batch = db().batch();
    
    messagesSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    batch.delete(conversationRef);
    await batch.commit();

    res.json({
      success: true,
      message: 'Conversation deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

export default router;