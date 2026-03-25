import { Router, Response, NextFunction } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth.middleware';
import { db, collections, toFirestoreTimestamp } from '../config/firebase';
import { AppError } from '../middleware/errorHandler';
import { User } from '../models/user.model';
import Joi from 'joi';

const router = Router();

const updatePreferencesSchema = Joi.object({
  theme: Joi.string().valid('light', 'dark', 'system').optional(),
  language: Joi.string().optional(),
  notifications: Joi.object({
    push: Joi.boolean().optional(),
    email: Joi.boolean().optional(),
    inApp: Joi.boolean().optional()
  }).optional(),
  privacy: Joi.object({
    shareAnalytics: Joi.boolean().optional(),
    allowDataCollection: Joi.boolean().optional()
  }).optional()
});

router.get('/profile', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    
    const userDoc = await db().collection(collections.users).doc(userId).get();
    
    if (!userDoc.exists) {
      throw new AppError('User not found', 404);
    }

    const userData = userDoc.data() as User;
    
    const { passwordHash, ...userProfile } = userData as any;

    res.json({
      success: true,
      data: userProfile
    });
  } catch (error) {
    next(error);
  }
});

router.put('/profile', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { displayName, photoURL } = req.body;

    const updateData: Partial<User> = {
      updatedAt: new Date()
    };

    if (displayName) {
      updateData.displayName = displayName;
    }

    if (photoURL !== undefined) {
      updateData.photoURL = photoURL;
    }

    await db().collection(collections.users).doc(userId).update({
      ...updateData,
      updatedAt: toFirestoreTimestamp(updateData.updatedAt!)
    });

    const userDoc = await db().collection(collections.users).doc(userId).get();
    const userData = userDoc.data() as User;
    
    const { passwordHash, ...userProfile } = userData as any;

    res.json({
      success: true,
      data: userProfile
    });
  } catch (error) {
    next(error);
  }
});

router.put('/preferences', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { error, value } = updatePreferencesSchema.validate(req.body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const userId = req.userId!;

    const userDoc = await db().collection(collections.users).doc(userId).get();
    
    if (!userDoc.exists) {
      throw new AppError('User not found', 404);
    }

    const currentUser = userDoc.data() as User;
    
    const updatedPreferences = {
      ...currentUser.preferences,
      ...value
    };

    await userDoc.ref.update({
      preferences: updatedPreferences,
      updatedAt: toFirestoreTimestamp(new Date())
    });

    res.json({
      success: true,
      data: { preferences: updatedPreferences }
    });
  } catch (error) {
    next(error);
  }
});

router.get('/stats', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    const [charactersSnapshot, conversationsSnapshot] = await Promise.all([
      db().collection(collections.characters).where('userId', '==', userId).get(),
      db().collection(collections.conversations).where('userId', '==', userId).get()
    ]);

    let totalMessages = 0;
    for (const conversationDoc of conversationsSnapshot.docs) {
      const messagesSnapshot = await conversationDoc.ref.collection('messages').get();
      totalMessages += messagesSnapshot.size;
    }

    const stats = {
      totalCharacters: charactersSnapshot.size,
      totalConversations: conversationsSnapshot.size,
      totalMessages,
      joinDate: null as Date | null
    };

    const userDoc = await db().collection(collections.users).doc(userId).get();
    if (userDoc.exists) {
      const userData = userDoc.data() as User;
      stats.joinDate = userData.createdAt;
    }

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
});

router.delete('/account', authenticate, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { password } = req.body;

    if (!password) {
      throw new AppError('Password confirmation required', 400);
    }

    const batch = db().batch();

    const [charactersSnapshot, conversationsSnapshot] = await Promise.all([
      db().collection(collections.characters).where('userId', '==', userId).get(),
      db().collection(collections.conversations).where('userId', '==', userId).get()
    ]);

    charactersSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    for (const conversationDoc of conversationsSnapshot.docs) {
      const messagesSnapshot = await conversationDoc.ref.collection('messages').get();
      messagesSnapshot.docs.forEach(messageDoc => {
        batch.delete(messageDoc.ref);
      });
      batch.delete(conversationDoc.ref);
    }

    const userRef = db().collection(collections.users).doc(userId);
    batch.delete(userRef);

    await batch.commit();

    res.json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

export default router;