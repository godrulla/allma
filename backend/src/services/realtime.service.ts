import { Server } from 'socket.io';
import { db, collections } from '../config/firebase';
import { logger } from '../utils/logger';
import { authService } from './auth.service';

export class RealtimeService {
  private io: Server;

  constructor(io: Server) {
    this.io = io;
    this.setupEventHandlers();
  }

  private setupEventHandlers() {
    this.io.on('connection', (socket) => {
      logger.info(`Socket connected: ${socket.id}`);

      socket.on('authenticate', async (token: string) => {
        try {
          const userId = await authService.verifyToken(token);
          socket.data.userId = userId;
          socket.emit('authenticated', { success: true });
          logger.info(`Socket authenticated: ${socket.id} for user: ${userId}`);
        } catch (error) {
          socket.emit('authentication_error', { message: 'Invalid token' });
          socket.disconnect();
        }
      });

      socket.on('join_conversation', (data: { conversationId: string }) => {
        const { conversationId } = data;
        if (!socket.data.userId) {
          socket.emit('error', { message: 'Not authenticated' });
          return;
        }

        socket.join(`conversation:${conversationId}`);
        logger.info(`User ${socket.data.userId} joined conversation: ${conversationId}`);
      });

      socket.on('leave_conversation', (data: { conversationId: string }) => {
        const { conversationId } = data;
        socket.leave(`conversation:${conversationId}`);
        logger.info(`User ${socket.data.userId} left conversation: ${conversationId}`);
      });

      socket.on('typing_start', (data: { conversationId: string }) => {
        const { conversationId } = data;
        if (!socket.data.userId) return;

        socket.to(`conversation:${conversationId}`).emit('user_typing', {
          userId: socket.data.userId,
          isTyping: true,
          timestamp: new Date().toISOString()
        });
      });

      socket.on('typing_stop', (data: { conversationId: string }) => {
        const { conversationId } = data;
        if (!socket.data.userId) return;

        socket.to(`conversation:${conversationId}`).emit('user_typing', {
          userId: socket.data.userId,
          isTyping: false,
          timestamp: new Date().toISOString()
        });
      });

      socket.on('message_reaction', async (data: {
        conversationId: string;
        messageId: string;
        emoji: string;
        action: 'add' | 'remove';
      }) => {
        try {
          const { conversationId, messageId, emoji, action } = data;
          if (!socket.data.userId) return;

          const messageRef = db()
            .collection(collections.conversations)
            .doc(conversationId)
            .collection('messages')
            .doc(messageId);

          const messageDoc = await messageRef.get();
          if (!messageDoc.exists) return;

          const messageData = messageDoc.data();
          const reactions = messageData?.metadata?.reactions || [];

          const existingReactionIndex = reactions.findIndex(
            (r: any) => r.userId === socket.data.userId && r.emoji === emoji
          );

          if (action === 'add' && existingReactionIndex === -1) {
            reactions.push({
              emoji,
              userId: socket.data.userId,
              timestamp: new Date()
            });
          } else if (action === 'remove' && existingReactionIndex !== -1) {
            reactions.splice(existingReactionIndex, 1);
          }

          await messageRef.update({
            'metadata.reactions': reactions
          });

          this.io.to(`conversation:${conversationId}`).emit('message_reaction_updated', {
            messageId,
            reactions
          });
        } catch (error) {
          logger.error('Error handling message reaction:', error);
        }
      });

      socket.on('disconnect', () => {
        logger.info(`Socket disconnected: ${socket.id}`);
      });
    });
  }

  public emitToUser(userId: string, event: string, data: any) {
    this.io.sockets.sockets.forEach((socket) => {
      if (socket.data.userId === userId) {
        socket.emit(event, data);
      }
    });
  }

  public emitToConversation(conversationId: string, event: string, data: any) {
    this.io.to(`conversation:${conversationId}`).emit(event, data);
  }

  public broadcastNotification(notification: {
    type: string;
    title: string;
    message: string;
    userId?: string;
    data?: any;
  }) {
    if (notification.userId) {
      this.emitToUser(notification.userId, 'notification', notification);
    } else {
      this.io.emit('notification', notification);
    }
  }
}

export let realtimeService: RealtimeService;