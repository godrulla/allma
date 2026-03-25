import { auth, db, collections } from '../config/firebase';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { logger } from '../utils/logger';
import { User } from '../models/user.model';

export class AuthService {
  private readonly jwtSecret: string;
  private readonly jwtExpiry: string;

  constructor() {
    this.jwtSecret = process.env.JWT_SECRET || 'default-secret-change-in-production';
    this.jwtExpiry = process.env.JWT_EXPIRY || '7d';
  }

  async createUser(email: string, password: string, displayName: string): Promise<User> {
    try {
      const userRecord = await auth().createUser({
        email,
        password,
        displayName,
        emailVerified: false,
      });

      const hashedPassword = await bcrypt.hash(password, 10);

      const userData: User = {
        id: userRecord.uid,
        email,
        displayName,
        photoURL: null,
        createdAt: new Date(),
        updatedAt: new Date(),
        preferences: {
          theme: 'light',
          language: 'en',
          notifications: {
            push: true,
            email: true,
            inApp: true,
          },
          privacy: {
            shareAnalytics: true,
            allowDataCollection: true,
          },
        },
        subscription: {
          tier: 'free',
          status: 'active',
          startDate: new Date(),
          endDate: null,
        },
      };

      await db().collection(collections.users).doc(userRecord.uid).set({
        ...userData,
        passwordHash: hashedPassword,
      });

      logger.info(`User created: ${userRecord.uid}`);
      return userData;
    } catch (error) {
      logger.error('Error creating user:', error);
      throw error;
    }
  }

  async signIn(email: string, password: string): Promise<{ user: User; token: string }> {
    try {
      const userSnapshot = await db()
        .collection(collections.users)
        .where('email', '==', email)
        .limit(1)
        .get();

      if (userSnapshot.empty) {
        throw new Error('Invalid credentials');
      }

      const userDoc = userSnapshot.docs[0];
      const userData = userDoc.data() as User & { passwordHash: string };

      const isPasswordValid = await bcrypt.compare(password, userData.passwordHash);
      if (!isPasswordValid) {
        throw new Error('Invalid credentials');
      }

      const token = this.generateToken(userData.id);

      const { passwordHash, ...user } = userData;

      logger.info(`User signed in: ${userData.id}`);
      return { user, token };
    } catch (error) {
      logger.error('Error signing in:', error);
      throw error;
    }
  }

  async signInWithFirebaseToken(idToken: string): Promise<{ user: User; token: string }> {
    try {
      const decodedToken = await auth().verifyIdToken(idToken);
      const uid = decodedToken.uid;

      const userDoc = await db().collection(collections.users).doc(uid).get();
      
      if (!userDoc.exists) {
        const userRecord = await auth().getUser(uid);
        
        const userData: User = {
          id: uid,
          email: userRecord.email || '',
          displayName: userRecord.displayName || 'User',
          photoURL: userRecord.photoURL || null,
          createdAt: new Date(),
          updatedAt: new Date(),
          preferences: {
            theme: 'light',
            language: 'en',
            notifications: {
              push: true,
              email: true,
              inApp: true,
            },
            privacy: {
              shareAnalytics: true,
              allowDataCollection: true,
            },
          },
          subscription: {
            tier: 'free',
            status: 'active',
            startDate: new Date(),
            endDate: null,
          },
        };

        await db().collection(collections.users).doc(uid).set(userData);
        
        const token = this.generateToken(uid);
        return { user: userData, token };
      }

      const userData = userDoc.data() as User;
      const token = this.generateToken(uid);

      logger.info(`User signed in with Firebase token: ${uid}`);
      return { user: userData, token };
    } catch (error) {
      logger.error('Error verifying Firebase token:', error);
      throw error;
    }
  }

  async verifyToken(token: string): Promise<string> {
    try {
      const decoded = jwt.verify(token, this.jwtSecret) as { userId: string };
      return decoded.userId;
    } catch (error) {
      logger.error('Error verifying token:', error);
      throw new Error('Invalid token');
    }
  }

  async updatePassword(userId: string, oldPassword: string, newPassword: string): Promise<void> {
    try {
      const userDoc = await db().collection(collections.users).doc(userId).get();
      
      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data() as { passwordHash: string };
      
      const isPasswordValid = await bcrypt.compare(oldPassword, userData.passwordHash);
      if (!isPasswordValid) {
        throw new Error('Invalid old password');
      }

      const hashedPassword = await bcrypt.hash(newPassword, 10);
      
      await auth().updateUser(userId, { password: newPassword });
      
      await db().collection(collections.users).doc(userId).update({
        passwordHash: hashedPassword,
        updatedAt: new Date(),
      });

      logger.info(`Password updated for user: ${userId}`);
    } catch (error) {
      logger.error('Error updating password:', error);
      throw error;
    }
  }

  async resetPassword(email: string): Promise<void> {
    try {
      await auth().generatePasswordResetLink(email);
      
      logger.info(`Password reset link generated for: ${email}`);
      
    } catch (error) {
      logger.error('Error resetting password:', error);
      throw error;
    }
  }

  async deleteUser(userId: string): Promise<void> {
    try {
      await auth().deleteUser(userId);
      
      await db().collection(collections.users).doc(userId).delete();
      
      const batch = db().batch();
      
      const conversationsSnapshot = await db()
        .collection(collections.conversations)
        .where('userId', '==', userId)
        .get();
      
      conversationsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();

      logger.info(`User deleted: ${userId}`);
    } catch (error) {
      logger.error('Error deleting user:', error);
      throw error;
    }
  }

  private generateToken(userId: string): string {
    return jwt.sign(
      { userId, timestamp: Date.now() },
      this.jwtSecret,
      { expiresIn: this.jwtExpiry } as jwt.SignOptions
    );
  }
}

export const authService = new AuthService();