import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth.middleware';
import { db, collections, toFirestoreTimestamp } from '../config/firebase';
import { AppError } from '../middleware/errorHandler';
import { Character } from '../models/character.model';
import { v4 as uuidv4 } from 'uuid';
import Joi from 'joi';

const router = Router();

const createCharacterSchema = Joi.object({
  name: Joi.string().min(2).max(50).required(),
  avatar: Joi.string().uri().optional(),
  personality: Joi.object({
    traits: Joi.array().items(Joi.string()).min(3).required(),
    interests: Joi.array().items(Joi.string()).min(3).required(),
    backstory: Joi.string().min(50).max(1000).required(),
    voiceStyle: Joi.string().required(),
    emotionalRange: Joi.string().required(),
    quirks: Joi.array().items(Joi.string()).optional(),
    values: Joi.array().items(Joi.string()).optional(),
    goals: Joi.array().items(Joi.string()).optional()
  }).required(),
  isPublic: Joi.boolean().default(false),
  tags: Joi.array().items(Joi.string()).default([])
});

router.post('/create', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { error, value } = createCharacterSchema.validate(req.body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const userId = req.userId!;
    const characterId = uuidv4();

    const character: Character = {
      id: characterId,
      userId,
      name: value.name,
      avatar: value.avatar || `https://api.dicebear.com/7.x/personas/svg?seed=${characterId}`,
      personality: value.personality,
      currentMood: 'neutral',
      relationshipLevel: 0,
      memories: [],
      createdAt: new Date(),
      updatedAt: new Date(),
      isPublic: value.isPublic,
      tags: value.tags
    };

    await db().collection(collections.characters).doc(characterId).set({
      ...character,
      createdAt: toFirestoreTimestamp(character.createdAt),
      updatedAt: toFirestoreTimestamp(character.updatedAt)
    });

    res.status(201).json({
      success: true,
      data: character
    });
  } catch (error) {
    next(error);
  }
});

router.get('/my-characters', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    
    const charactersSnapshot = await db()
      .collection(collections.characters)
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    const characters = charactersSnapshot.docs.map(doc => doc.data() as Character);

    res.json({
      success: true,
      data: characters
    });
  } catch (error) {
    next(error);
  }
});

router.get('/public', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { tags, limit = 20, offset = 0 } = req.query;
    
    let query = db()
      .collection(collections.characters)
      .where('isPublic', '==', true);

    if (tags && typeof tags === 'string') {
      const tagArray = tags.split(',');
      query = query.where('tags', 'array-contains-any', tagArray);
    }

    const charactersSnapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(Number(limit))
      .offset(Number(offset))
      .get();

    const characters = charactersSnapshot.docs.map(doc => {
      const data = doc.data() as Character;
      const { memories, ...publicData } = data;
      return publicData;
    });

    res.json({
      success: true,
      data: characters
    });
  } catch (error) {
    next(error);
  }
});

router.get('/:id', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const characterDoc = await db().collection(collections.characters).doc(id).get();
    
    if (!characterDoc.exists) {
      throw new AppError('Character not found', 404);
    }

    const character = characterDoc.data() as Character;
    
    if (!character.isPublic && character.userId !== userId) {
      throw new AppError('Unauthorized access to character', 403);
    }

    res.json({
      success: true,
      data: character
    });
  } catch (error) {
    next(error);
  }
});

router.put('/:id', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const characterDoc = await db().collection(collections.characters).doc(id).get();
    
    if (!characterDoc.exists) {
      throw new AppError('Character not found', 404);
    }

    const character = characterDoc.data() as Character;
    
    if (character.userId !== userId) {
      throw new AppError('Unauthorized to edit this character', 403);
    }

    const updateData = {
      ...req.body,
      updatedAt: toFirestoreTimestamp(new Date())
    };

    delete updateData.id;
    delete updateData.userId;
    delete updateData.createdAt;

    await characterDoc.ref.update(updateData);

    res.json({
      success: true,
      data: { ...character, ...updateData }
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const characterDoc = await db().collection(collections.characters).doc(id).get();
    
    if (!characterDoc.exists) {
      throw new AppError('Character not found', 404);
    }

    const character = characterDoc.data() as Character;
    
    if (character.userId !== userId) {
      throw new AppError('Unauthorized to delete this character', 403);
    }

    await characterDoc.ref.delete();

    res.json({
      success: true,
      message: 'Character deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

router.post('/:id/clone', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const userId = req.userId!;

    const characterDoc = await db().collection(collections.characters).doc(id).get();
    
    if (!characterDoc.exists) {
      throw new AppError('Character not found', 404);
    }

    const originalCharacter = characterDoc.data() as Character;
    
    if (!originalCharacter.isPublic && originalCharacter.userId !== userId) {
      throw new AppError('Cannot clone private character', 403);
    }

    const newCharacterId = uuidv4();
    const clonedCharacter: Character = {
      ...originalCharacter,
      id: newCharacterId,
      userId,
      name: `${originalCharacter.name} (Clone)`,
      memories: [],
      relationshipLevel: 0,
      currentMood: 'neutral',
      createdAt: new Date(),
      updatedAt: new Date(),
      isPublic: false
    };

    await db().collection(collections.characters).doc(newCharacterId).set({
      ...clonedCharacter,
      createdAt: toFirestoreTimestamp(clonedCharacter.createdAt),
      updatedAt: toFirestoreTimestamp(clonedCharacter.updatedAt)
    });

    res.status(201).json({
      success: true,
      data: clonedCharacter
    });
  } catch (error) {
    next(error);
  }
});

export default router;