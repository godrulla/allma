import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../shared/models/message.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/services/encryption_service.dart';

/// Service for persisting and retrieving conversations
class ConversationStorage {
  final StorageService _storageService;
  final EncryptionService _encryptionService;

  ConversationStorage({
    required StorageService storageService,
    required EncryptionService encryptionService,
  })  : _storageService = storageService,
        _encryptionService = encryptionService;

  /// Save a message to the conversation history
  Future<void> saveMessage(Message message, String companionId) async {
    try {
      final database = await _storageService.database;
      final encryptedContent = await _encryptionService.encrypt(message.content);

      await database.insert(
        'conversation_messages',
        {
          'id': message.id,
          'companion_id': companionId,
          'encrypted_content': encryptedContent,
          'type': message.type.name,
          'role': message.role.name,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
          'metadata': json.encode(message.metadata),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw ConversationStorageException('Failed to save message: $e');
    }
  }

  /// Save multiple messages in a batch
  Future<void> saveMessages(List<Message> messages, String companionId) async {
    try {
      final database = await _storageService.database;
      final batch = database.batch();

      for (final message in messages) {
        final encryptedContent = await _encryptionService.encrypt(message.content);
        
        batch.insert(
          'conversation_messages',
          {
            'id': message.id,
            'companion_id': companionId,
            'encrypted_content': encryptedContent,
            'type': message.type.name,
            'role': message.role.name,
            'timestamp': message.timestamp.millisecondsSinceEpoch,
            'metadata': json.encode(message.metadata),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw ConversationStorageException('Failed to save messages: $e');
    }
  }

  /// Load conversation history for a companion
  Future<List<Message>> loadConversation(String companionId, {
    int? limit,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      final database = await _storageService.database;
      
      String whereClause = 'companion_id = ?';
      List<dynamic> whereArgs = [companionId];

      if (before != null) {
        whereClause += ' AND timestamp < ?';
        whereArgs.add(before.millisecondsSinceEpoch);
      }

      if (after != null) {
        whereClause += ' AND timestamp > ?';
        whereArgs.add(after.millisecondsSinceEpoch);
      }

      final result = await database.query(
        'conversation_messages',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp ASC',
        limit: limit,
      );

      final messages = <Message>[];
      for (final row in result) {
        final message = await _decryptMessage(row);
        if (message != null) {
          messages.add(message);
        }
      }

      return messages;
    } catch (e) {
      throw ConversationStorageException('Failed to load conversation: $e');
    }
  }

  /// Load recent messages for a companion
  Future<List<Message>> loadRecentMessages(String companionId, {int limit = 50}) async {
    try {
      final database = await _storageService.database;
      
      final result = await database.query(
        'conversation_messages',
        where: 'companion_id = ?',
        whereArgs: [companionId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      final messages = <Message>[];
      for (final row in result.reversed) { // Reverse to get chronological order
        final message = await _decryptMessage(row);
        if (message != null) {
          messages.add(message);
        }
      }

      return messages;
    } catch (e) {
      throw ConversationStorageException('Failed to load recent messages: $e');
    }
  }

  /// Get conversation statistics
  Future<ConversationStats> getConversationStats(String companionId) async {
    try {
      final database = await _storageService.database;
      
      // Total message count
      final totalResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM conversation_messages WHERE companion_id = ?',
        [companionId],
      );
      final totalMessages = totalResult.first['count'] as int;

      // User message count
      final userResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM conversation_messages WHERE companion_id = ? AND role = ?',
        [companionId, MessageRole.user.name],
      );
      final userMessages = userResult.first['count'] as int;

      // Companion message count
      final companionResult = await database.rawQuery(
        'SELECT COUNT(*) as count FROM conversation_messages WHERE companion_id = ? AND role = ?',
        [companionId, MessageRole.companion.name],
      );
      final companionMessages = companionResult.first['count'] as int;

      // First and last message timestamps
      DateTime? firstMessageAt;
      DateTime? lastMessageAt;

      if (totalMessages > 0) {
        final firstResult = await database.query(
          'conversation_messages',
          where: 'companion_id = ?',
          whereArgs: [companionId],
          orderBy: 'timestamp ASC',
          limit: 1,
        );
        
        final lastResult = await database.query(
          'conversation_messages',
          where: 'companion_id = ?',
          whereArgs: [companionId],
          orderBy: 'timestamp DESC',
          limit: 1,
        );

        if (firstResult.isNotEmpty) {
          firstMessageAt = DateTime.fromMillisecondsSinceEpoch(
            firstResult.first['timestamp'] as int,
          );
        }

        if (lastResult.isNotEmpty) {
          lastMessageAt = DateTime.fromMillisecondsSinceEpoch(
            lastResult.first['timestamp'] as int,
          );
        }
      }

      return ConversationStats(
        totalMessages: totalMessages,
        userMessages: userMessages,
        companionMessages: companionMessages,
        firstMessageAt: firstMessageAt,
        lastMessageAt: lastMessageAt,
      );
    } catch (e) {
      throw ConversationStorageException('Failed to get conversation stats: $e');
    }
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      final database = await _storageService.database;
      await database.delete(
        'conversation_messages',
        where: 'id = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      throw ConversationStorageException('Failed to delete message: $e');
    }
  }

  /// Clear all conversation history for a companion
  Future<void> clearConversation(String companionId) async {
    try {
      final database = await _storageService.database;
      await database.delete(
        'conversation_messages',
        where: 'companion_id = ?',
        whereArgs: [companionId],
      );
    } catch (e) {
      throw ConversationStorageException('Failed to clear conversation: $e');
    }
  }

  /// Delete old messages (older than specified duration)
  Future<int> deleteOldMessages(String companionId, Duration maxAge) async {
    try {
      final database = await _storageService.database;
      final cutoffTime = DateTime.now().subtract(maxAge);
      
      final deletedCount = await database.delete(
        'conversation_messages',
        where: 'companion_id = ? AND timestamp < ?',
        whereArgs: [companionId, cutoffTime.millisecondsSinceEpoch],
      );

      return deletedCount;
    } catch (e) {
      throw ConversationStorageException('Failed to delete old messages: $e');
    }
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String companionId, String query, {
    int limit = 20,
  }) async {
    try {
      // Note: This is a simple implementation. For production, consider using FTS (Full-Text Search)
      final messages = await loadConversation(companionId);
      final queryLower = query.toLowerCase();
      
      final matchingMessages = messages.where((message) {
        return message.content.toLowerCase().contains(queryLower);
      }).take(limit).toList();

      return matchingMessages;
    } catch (e) {
      throw ConversationStorageException('Failed to search messages: $e');
    }
  }

  /// Export conversation to JSON
  Future<Map<String, dynamic>> exportConversation(String companionId) async {
    try {
      final messages = await loadConversation(companionId);
      final stats = await getConversationStats(companionId);

      return {
        'companion_id': companionId,
        'exported_at': DateTime.now().toIso8601String(),
        'stats': {
          'total_messages': stats.totalMessages,
          'user_messages': stats.userMessages,
          'companion_messages': stats.companionMessages,
          'first_message_at': stats.firstMessageAt?.toIso8601String(),
          'last_message_at': stats.lastMessageAt?.toIso8601String(),
        },
        'messages': messages.map((message) => {
          'id': message.id,
          'content': message.content,
          'type': message.type.name,
          'role': message.role.name,
          'timestamp': message.timestamp.toIso8601String(),
          'metadata': message.metadata,
        }).toList(),
      };
    } catch (e) {
      throw ConversationStorageException('Failed to export conversation: $e');
    }
  }

  /// Get message count for a specific date range
  Future<int> getMessageCount(String companionId, {
    DateTime? startDate,
    DateTime? endDate,
    MessageRole? role,
  }) async {
    try {
      final database = await _storageService.database;
      
      String whereClause = 'companion_id = ?';
      List<dynamic> whereArgs = [companionId];

      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      if (role != null) {
        whereClause += ' AND role = ?';
        whereArgs.add(role.name);
      }

      final result = await database.rawQuery(
        'SELECT COUNT(*) as count FROM conversation_messages WHERE $whereClause',
        whereArgs,
      );

      return result.first['count'] as int;
    } catch (e) {
      throw ConversationStorageException('Failed to get message count: $e');
    }
  }

  /// Decrypt and convert database row to Message
  Future<Message?> _decryptMessage(Map<String, dynamic> row) async {
    try {
      final encryptedContent = row['encrypted_content'] as List<int>;
      final decryptedContent = await _encryptionService.decrypt(encryptedContent);
      final metadata = json.decode(row['metadata'] as String) as Map<String, dynamic>;

      return Message(
        id: row['id'] as String,
        content: decryptedContent,
        type: MessageType.values.firstWhere(
          (t) => t.name == row['type'] as String,
        ),
        role: MessageRole.values.firstWhere(
          (r) => r.name == row['role'] as String,
        ),
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        metadata: metadata,
      );
    } catch (e) {
      print('Failed to decrypt message: $e');
      return null;
    }
  }
}

/// Conversation statistics
class ConversationStats {
  final int totalMessages;
  final int userMessages;
  final int companionMessages;
  final DateTime? firstMessageAt;
  final DateTime? lastMessageAt;

  const ConversationStats({
    required this.totalMessages,
    required this.userMessages,
    required this.companionMessages,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  /// Get the conversation duration
  Duration? get conversationDuration {
    if (firstMessageAt == null || lastMessageAt == null) return null;
    return lastMessageAt!.difference(firstMessageAt!);
  }

  /// Get average messages per day
  double get averageMessagesPerDay {
    final duration = conversationDuration;
    if (duration == null || duration.inDays == 0) return 0.0;
    return totalMessages / duration.inDays;
  }

  /// Check if conversation is active (has recent messages)
  bool get isActive {
    if (lastMessageAt == null) return false;
    final daysSinceLastMessage = DateTime.now().difference(lastMessageAt!).inDays;
    return daysSinceLastMessage < 7; // Active if messaged within last week
  }

  /// Get conversation age in days
  int get ageInDays {
    if (firstMessageAt == null) return 0;
    return DateTime.now().difference(firstMessageAt!).inDays;
  }
}

/// Exception thrown by conversation storage operations
class ConversationStorageException implements Exception {
  final String message;

  const ConversationStorageException(this.message);

  @override
  String toString() => 'ConversationStorageException: $message';
}