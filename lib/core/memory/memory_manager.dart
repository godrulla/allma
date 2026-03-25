import 'dart:convert';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../../shared/services/storage_service.dart';
import '../../shared/services/encryption_service.dart';
import 'models/memory_item.dart';

class MemoryManager {
  final StorageService _storageService;
  final EncryptionService _encryptionService;
  final Uuid _uuid = const Uuid();

  // Memory configuration
  static const int maxMemoryItems = 1000;
  static const double defaultDecayRate = 0.05; // 5% decay per day
  static const Duration memoryRetentionPeriod = Duration(days: 365);

  MemoryManager({
    required StorageService storageService,
    required EncryptionService encryptionService,
  })  : _storageService = storageService,
        _encryptionService = encryptionService;

  /// Initialize memory storage for a new companion
  Future<void> initializeCompanionMemory(String companionId) async {
    // Create initial system memory
    await storeMemory(
      companionId: companionId,
      content: 'Companion created and ready for conversations.',
      type: MemoryType.factual,
      importance: 0.5,
      tags: ['system', 'creation'],
    );
  }

  /// Store a new memory item
  Future<void> storeMemory({
    required String companionId,
    required String content,
    required MemoryType type,
    required double importance,
    List<String> tags = const [],
  }) async {
    try {
      final memory = MemoryItem(
        id: _uuid.v4(),
        companionId: companionId,
        content: content,
        type: type,
        importance: importance,
        timestamp: DateTime.now(),
        tags: tags,
      );

      await _saveMemoryItem(memory);
      
      // Clean up old memories if we exceed the limit
      await _cleanupOldMemories(companionId);
    } catch (e) {
      throw MemoryException('Failed to store memory: $e');
    }
  }

  /// Store a conversation turn
  Future<void> storeConversation({
    required String companionId,
    required String userMessage,
    required String companionResponse,
  }) async {
    final timestamp = DateTime.now();
    
    // Store user message memory
    await storeMemory(
      companionId: companionId,
      content: 'User said: "$userMessage"',
      type: MemoryType.conversation,
      importance: _calculateMessageImportance(userMessage),
      tags: ['conversation', 'user_message'],
    );

    // Store companion response memory
    await storeMemory(
      companionId: companionId,
      content: 'I responded: "$companionResponse"',
      type: MemoryType.conversation,
      importance: 0.6, // Companion responses have moderate importance
      tags: ['conversation', 'companion_response'],
    );

    // Extract and store any personal information from the conversation
    await _extractPersonalInformation(companionId, userMessage);
  }

  /// Retrieve relevant memories for a query
  Future<List<MemoryItem>> retrieveRelevantMemories({
    required String companionId,
    required String query,
    int limit = 5,
  }) async {
    try {
      final allMemories = await _getCompanionMemories(companionId);
      
      // Calculate relevance scores
      final scoredMemories = allMemories.map((memory) {
        final relevanceScore = _calculateRelevanceScore(memory, query);
        return _ScoredMemory(memory, relevanceScore);
      }).toList();

      // Sort by relevance score and return top results
      scoredMemories.sort((a, b) => b.score.compareTo(a.score));
      return scoredMemories
          .take(limit)
          .map((scored) => scored.memory)
          .toList();
    } catch (e) {
      throw MemoryException('Failed to retrieve memories: $e');
    }
  }

  /// Get all memories for a companion
  Future<List<MemoryItem>> getCompanionMemories(String companionId) async {
    return await _getCompanionMemories(companionId);
  }

  /// Get memory count for a companion
  Future<int> getMemoryCount(String companionId) async {
    try {
      final database = await _storageService.database;
      final result = await database.rawQuery(
        'SELECT COUNT(*) as count FROM memory_items WHERE companion_id = ?',
        [companionId],
      );
      return result.first['count'] as int;
    } catch (e) {
      throw MemoryException('Failed to get memory count: $e');
    }
  }

  /// Delete all memories for a companion
  Future<void> deleteCompanionMemory(String companionId) async {
    try {
      final database = await _storageService.database;
      await database.delete(
        'memory_items',
        where: 'companion_id = ?',
        whereArgs: [companionId],
      );
    } catch (e) {
      throw MemoryException('Failed to delete companion memory: $e');
    }
  }

  /// Update memory importance (memory reinforcement)
  Future<void> reinforceMemory(String memoryId, double reinforcement) async {
    try {
      final database = await _storageService.database;
      final result = await database.query(
        'memory_items',
        where: 'id = ?',
        whereArgs: [memoryId],
        limit: 1,
      );

      if (result.isEmpty) return;

      final memory = await _decryptMemoryItem(result.first);
      if (memory == null) return;

      // Increase importance with diminishing returns
      final newImportance = math.min(1.0, memory.importance + reinforcement * 0.1);
      final updatedMemory = memory.copyWith(importance: newImportance);
      
      await _updateMemoryItem(updatedMemory);
    } catch (e) {
      throw MemoryException('Failed to reinforce memory: $e');
    }
  }

  /// Apply memory decay to reduce importance over time
  Future<void> applyMemoryDecay(String companionId) async {
    try {
      final memories = await _getCompanionMemories(companionId);
      final now = DateTime.now();

      for (final memory in memories) {
        final daysSince = now.difference(memory.timestamp).inDays;
        final decayAmount = daysSince * defaultDecayRate;
        final newImportance = math.max(0.0, memory.importance - decayAmount);

        if (newImportance != memory.importance) {
          final updatedMemory = memory.copyWith(importance: newImportance);
          await _updateMemoryItem(updatedMemory);
        }
      }
    } catch (e) {
      throw MemoryException('Failed to apply memory decay: $e');
    }
  }

  /// Save memory item to database
  Future<void> _saveMemoryItem(MemoryItem memory) async {
    final database = await _storageService.database;
    final encryptedContent = await _encryptionService.encrypt(memory.content);

    await database.insert(
      'memory_items',
      {
        'id': memory.id,
        'companion_id': memory.companionId,
        'encrypted_content': encryptedContent,
        'type': memory.type.name,
        'importance': memory.importance,
        'timestamp': memory.timestamp.millisecondsSinceEpoch,
        'tags': json.encode(memory.tags),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update existing memory item
  Future<void> _updateMemoryItem(MemoryItem memory) async {
    final database = await _storageService.database;
    final encryptedContent = await _encryptionService.encrypt(memory.content);

    await database.update(
      'memory_items',
      {
        'encrypted_content': encryptedContent,
        'importance': memory.importance,
        'tags': json.encode(memory.tags),
      },
      where: 'id = ?',
      whereArgs: [memory.id],
    );
  }

  /// Get all memories for a companion from database
  Future<List<MemoryItem>> _getCompanionMemories(String companionId) async {
    final database = await _storageService.database;
    final result = await database.query(
      'memory_items',
      where: 'companion_id = ?',
      whereArgs: [companionId],
      orderBy: 'timestamp DESC',
    );

    final memories = <MemoryItem>[];
    for (final row in result) {
      final memory = await _decryptMemoryItem(row);
      if (memory != null) {
        memories.add(memory);
      }
    }

    return memories;
  }

  /// Decrypt memory item from database row
  Future<MemoryItem?> _decryptMemoryItem(Map<String, dynamic> row) async {
    try {
      final encryptedContent = row['encrypted_content'] as List<int>;
      final decryptedContent = await _encryptionService.decrypt(encryptedContent);
      final tags = (json.decode(row['tags'] as String) as List<dynamic>)
          .cast<String>();

      return MemoryItem(
        id: row['id'] as String,
        companionId: row['companion_id'] as String,
        content: decryptedContent,
        type: MemoryType.values.firstWhere(
          (t) => t.name == row['type'] as String,
        ),
        importance: row['importance'] as double,
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        tags: tags,
      );
    } catch (e) {
      print('Failed to decrypt memory item: $e');
      return null;
    }
  }

  /// Calculate relevance score for a memory given a query
  double _calculateRelevanceScore(MemoryItem memory, String query) {
    final queryLower = query.toLowerCase();
    final contentLower = memory.content.toLowerCase();
    
    // Keyword matching
    double keywordScore = 0.0;
    final queryWords = queryLower.split(' ');
    for (final word in queryWords) {
      if (contentLower.contains(word)) {
        keywordScore += 1.0 / queryWords.length;
      }
    }

    // Tag matching
    double tagScore = 0.0;
    for (final tag in memory.tags) {
      if (queryLower.contains(tag.toLowerCase())) {
        tagScore += 0.2;
      }
    }

    // Recency boost
    final daysSince = DateTime.now().difference(memory.timestamp).inDays;
    final recencyScore = math.exp(-daysSince / 30.0); // Decay over 30 days

    // Combine scores
    final baseScore = (keywordScore * 0.6) + (tagScore * 0.2) + (recencyScore * 0.2);
    return baseScore * memory.importance; // Weight by importance
  }

  /// Calculate importance of a message based on content
  double _calculateMessageImportance(String message) {
    final messageLower = message.toLowerCase();
    double importance = 0.4; // Base importance

    // Personal information indicators
    final personalKeywords = [
      'my name', 'i am', 'i work', 'i live', 'my job', 'my family',
      'i like', 'i love', 'i hate', 'i feel', 'my birthday'
    ];
    
    for (final keyword in personalKeywords) {
      if (messageLower.contains(keyword)) {
        importance += 0.2;
      }
    }

    // Emotional content
    final emotionalKeywords = [
      'sad', 'happy', 'angry', 'excited', 'worried', 'scared',
      'love', 'hate', 'depressed', 'anxious', 'grateful'
    ];
    
    for (final keyword in emotionalKeywords) {
      if (messageLower.contains(keyword)) {
        importance += 0.1;
      }
    }

    // Questions get moderate importance
    if (message.contains('?')) {
      importance += 0.1;
    }

    return math.min(1.0, importance);
  }

  /// Extract personal information from user messages
  Future<void> _extractPersonalInformation(String companionId, String message) async {
    final messageLower = message.toLowerCase();
    
    // Extract name
    final namePattern = RegExp(r'my name is (\w+)', caseSensitive: false);
    final nameMatch = namePattern.firstMatch(message);
    if (nameMatch != null) {
      await storeMemory(
        companionId: companionId,
        content: 'User\'s name is ${nameMatch.group(1)}',
        type: MemoryType.personal,
        importance: 0.9,
        tags: ['name', 'personal_info'],
      );
    }

    // Extract preferences
    final likePattern = RegExp(r'i (like|love|enjoy) (.+)', caseSensitive: false);
    final likeMatch = likePattern.firstMatch(messageLower);
    if (likeMatch != null) {
      await storeMemory(
        companionId: companionId,
        content: 'User ${likeMatch.group(1)}s ${likeMatch.group(2)}',
        type: MemoryType.preference,
        importance: 0.7,
        tags: ['preference', 'likes'],
      );
    }

    // Extract dislikes
    final dislikePattern = RegExp(r"i (hate|dislike|don't like) (.+)", caseSensitive: false);
    final dislikeMatch = dislikePattern.firstMatch(messageLower);
    if (dislikeMatch != null) {
      await storeMemory(
        companionId: companionId,
        content: 'User ${dislikeMatch.group(1)}s ${dislikeMatch.group(2)}',
        type: MemoryType.preference,
        importance: 0.7,
        tags: ['preference', 'dislikes'],
      );
    }
  }

  /// Clean up old or low-importance memories
  Future<void> _cleanupOldMemories(String companionId) async {
    final memories = await _getCompanionMemories(companionId);
    
    if (memories.length <= maxMemoryItems) return;

    // Sort by importance (ascending) to remove least important first
    memories.sort((a, b) => a.importance.compareTo(b.importance));
    
    final memoriesToRemove = memories.take(memories.length - maxMemoryItems);
    
    for (final memory in memoriesToRemove) {
      await _deleteMemoryItem(memory.id);
    }
  }

  /// Delete a memory item
  Future<void> _deleteMemoryItem(String memoryId) async {
    final database = await _storageService.database;
    await database.delete(
      'memory_items',
      where: 'id = ?',
      whereArgs: [memoryId],
    );
  }
}

/// Helper class for scored memories
class _ScoredMemory {
  final MemoryItem memory;
  final double score;

  _ScoredMemory(this.memory, this.score);
}

/// Extension to add copyWith method to MemoryItem
extension MemoryItemExtension on MemoryItem {
  MemoryItem copyWith({
    String? id,
    String? companionId,
    String? content,
    MemoryType? type,
    double? importance,
    DateTime? timestamp,
    List<String>? tags,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      companionId: companionId ?? this.companionId,
      content: content ?? this.content,
      type: type ?? this.type,
      importance: importance ?? this.importance,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
    );
  }
}

/// Exception thrown by memory operations
class MemoryException implements Exception {
  final String message;

  const MemoryException(this.message);

  @override
  String toString() => 'MemoryException: $message';
}