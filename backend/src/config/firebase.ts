import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

export const initializeFirebase = () => {
  try {
    const serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    });

    logger.info('Firebase Admin SDK initialized successfully');
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK:', error);
    throw error;
  }
};

export const db = () => admin.firestore();
export const auth = () => admin.auth();
export const storage = () => admin.storage();
export const messaging = () => admin.messaging();

export const collections = {
  users: 'users',
  characters: 'characters',
  conversations: 'conversations',
  messages: 'messages',
  memories: 'memories',
  feedback: 'feedback',
  analytics: 'analytics',
} as const;

export interface FirestoreTimestamp {
  _seconds: number;
  _nanoseconds: number;
}

export const toFirestoreTimestamp = (date: Date = new Date()): admin.firestore.Timestamp => {
  return admin.firestore.Timestamp.fromDate(date);
};

export const fromFirestoreTimestamp = (timestamp: admin.firestore.Timestamp | FirestoreTimestamp): Date => {
  if ('toDate' in timestamp) {
    return timestamp.toDate();
  }
  return new Date(timestamp._seconds * 1000 + timestamp._nanoseconds / 1000000);
};