import 'package:flutter_test/flutter_test.dart';
import 'package:allma/core/memory/memory_manager.dart';
import 'package:allma/core/memory/models/memory_item.dart';

void main() {
  group('MemoryManager Tests', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager = MemoryManager();
    });

    group('Memory Formation', () {
      test('should create episodic memories from conversations', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';
        
        final conversationData = ConversationData(
          messages: [
            'Hello, I love painting landscapes',
            'That sounds wonderful! I enjoy art too',
            'My favorite medium is watercolor',
            'Watercolors create such beautiful effects',
          ],
          context: {'topic': 'art', 'mood': 'positive'},
          timestamp: DateTime.now(),
        );

        final memories = await memoryManager.formMemoriesFromConversation(
          companionId: companionId,
          userId: userId,
          conversationData: conversationData,
        );

        expect(memories, isNotEmpty);
        expect(memories.any((m) => m.type == MemoryType.episodic), isTrue);
        expect(memories.any((m) => m.content.contains('painting')), isTrue);
        expect(memories.any((m) => m.content.contains('watercolor')), isTrue);
      });

      test('should create semantic memories from repeated patterns', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        // Simulate multiple conversations about the same topic
        for (int i = 0; i < 5; i++) {
          final conversationData = ConversationData(
            messages: [
              'I really enjoy reading science fiction books',
              'Science fiction is fascinating',
            ],
            context: {'topic': 'books', 'genre': 'sci-fi'},
            timestamp: DateTime.now().subtract(Duration(days: i)),
          );

          await memoryManager.formMemoriesFromConversation(
            companionId: companionId,
            userId: userId,
            conversationData: conversationData,
          );
        }

        final semanticMemories = await memoryManager.getMemoriesByType(
          companionId: companionId,
          userId: userId,
          type: MemoryType.semantic,
        );

        expect(semanticMemories, isNotEmpty);
        expect(semanticMemories.any((m) => m.content.contains('science fiction')), isTrue);
      });

      test('should create procedural memories from behavioral patterns', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        // Simulate repeated greeting pattern
        for (int i = 0; i < 10; i++) {
          await memoryManager.recordBehavioralPattern(
            companionId: companionId,
            userId: userId,
            pattern: BehavioralPattern(
              type: 'greeting',
              context: {'time': 'morning', 'mood': 'cheerful'},
              response: 'Good morning! How did you sleep?',
              timestamp: DateTime.now().subtract(Duration(days: i)),
            ),
          );
        }

        final proceduralMemories = await memoryManager.getMemoriesByType(
          companionId: companionId,
          userId: userId,
          type: MemoryType.procedural,
        );

        expect(proceduralMemories, isNotEmpty);
        expect(proceduralMemories.any((m) => m.content.contains('morning')), isTrue);
      });

      test('should assign appropriate importance scores', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        final emotionalConversation = ConversationData(
          messages: [
            'I just lost my job and I\'m really scared',
            'I\'m so sorry to hear that. That must be very stressful',
            'Yes, I don\'t know what I\'m going to do',
          ],
          context: {'mood': 'distressed', 'topic': 'career', 'emotional_intensity': 'high'},
          timestamp: DateTime.now(),
        );

        final casualConversation = ConversationData(
          messages: [
            'What\'s the weather like?',
            'It\'s sunny and warm today',
          ],
          context: {'mood': 'neutral', 'topic': 'weather'},
          timestamp: DateTime.now(),
        );

        final emotionalMemories = await memoryManager.formMemoriesFromConversation(
          companionId: companionId,
          userId: userId,
          conversationData: emotionalConversation,
        );

        final casualMemories = await memoryManager.formMemoriesFromConversation(
          companionId: companionId,
          userId: userId,
          conversationData: casualConversation,
        );

        final highImportanceMemory = emotionalMemories.first;
        final lowImportanceMemory = casualMemories.first;

        expect(highImportanceMemory.importance, greaterThan(lowImportanceMemory.importance));
        expect(highImportanceMemory.importance, greaterThan(0.7));
        expect(lowImportanceMemory.importance, lessThan(0.4));
      });
    });

    group('Memory Retrieval', () {
      test('should retrieve relevant memories for conversation context', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        // Create some test memories
        await _createTestMemories(memoryManager, companionId, userId);

        final relevantMemories = await memoryManager.getRelevantMemories(
          companionId: companionId,
          userId: userId,
          context: {'topic': 'art', 'mood': 'creative'},
          limit: 5,
        );

        expect(relevantMemories, isNotEmpty);
        expect(relevantMemories.length, lessThanOrEqualTo(5));
        expect(relevantMemories.any((m) => m.content.contains('art') || 
                                        m.content.contains('paint')), isTrue);
      });

      test('should rank memories by relevance score', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        await _createTestMemories(memoryManager, companionId, userId);

        final memories = await memoryManager.getRelevantMemories(
          companionId: companionId,
          userId: userId,
          context: {'topic': 'art'},
          limit: 10,
        );

        // Memories should be sorted by relevance (highest first)
        for (int i = 0; i < memories.length - 1; i++) {
          final currentRelevance = memoryManager.calculateRelevanceScore(
            memories[i], 
            {'topic': 'art'}
          );
          final nextRelevance = memoryManager.calculateRelevanceScore(
            memories[i + 1], 
            {'topic': 'art'}
          );
          
          expect(currentRelevance, greaterThanOrEqualTo(nextRelevance));
        }
      });

      test('should retrieve memories by time range', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        final now = DateTime.now();
        final weekAgo = now.subtract(Duration(days: 7));
        final monthAgo = now.subtract(Duration(days: 30));

        await _createTestMemoriesWithTimestamps(
          memoryManager, 
          companionId, 
          userId, 
          [now, weekAgo, monthAgo]
        );

        final recentMemories = await memoryManager.getMemoriesByTimeRange(
          companionId: companionId,
          userId: userId,
          startTime: weekAgo,
          endTime: now,
        );

        expect(recentMemories.length, equals(2)); // now and weekAgo
        expect(recentMemories.every((m) => 
          m.timestamp.isAfter(weekAgo.subtract(Duration(seconds: 1)))), isTrue);
      });

      test('should search memories by content', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        await _createTestMemories(memoryManager, companionId, userId);

        final searchResults = await memoryManager.searchMemories(
          companionId: companionId,
          userId: userId,
          query: 'painting watercolor',
        );

        expect(searchResults, isNotEmpty);
        expect(searchResults.every((m) => 
          m.content.toLowerCase().contains('paint') || 
          m.content.toLowerCase().contains('watercolor')), isTrue);
      });
    });

    group('Memory Consolidation', () {
      test('should merge similar memories', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        // Create similar memories that should be merged
        final memory1 = MemoryItem(
          id: 'mem1',
          content: 'User likes painting with watercolors',
          type: MemoryType.semantic,
          importance: 0.7,
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          tags: ['art', 'painting', 'watercolor'],
          metadata: {},
        );

        final memory2 = MemoryItem(
          id: 'mem2',
          content: 'User enjoys watercolor painting',
          type: MemoryType.semantic,
          importance: 0.6,
          timestamp: DateTime.now(),
          tags: ['art', 'painting', 'watercolor'],
          metadata: {},
        );

        await memoryManager.storeMemory(companionId, userId, memory1);
        await memoryManager.storeMemory(companionId, userId, memory2);

        await memoryManager.consolidateMemories(companionId, userId);

        final consolidatedMemories = await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        );

        // Should have fewer memories after consolidation
        final watercolorMemories = consolidatedMemories.where((m) => 
          m.tags.contains('watercolor')).toList();
        
        expect(watercolorMemories.length, lessThan(2));
        
        if (watercolorMemories.isNotEmpty) {
          final consolidatedMemory = watercolorMemories.first;
          expect(consolidatedMemory.importance, greaterThan(0.7));
        }
      });

      test('should decay old memories over time', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        final oldMemory = MemoryItem(
          id: 'old-mem',
          content: 'Old conversation about weather',
          type: MemoryType.episodic,
          importance: 0.8,
          timestamp: DateTime.now().subtract(Duration(days: 365)),
          tags: ['weather'],
          metadata: {},
        );

        await memoryManager.storeMemory(companionId, userId, oldMemory);
        await memoryManager.applyTemporalDecay(companionId, userId);

        final retrievedMemory = await memoryManager.getMemoryById(oldMemory.id);
        
        expect(retrievedMemory?.importance, lessThan(0.8));
      });

      test('should strengthen frequently accessed memories', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        final memory = MemoryItem(
          id: 'frequent-mem',
          content: 'User loves coffee',
          type: MemoryType.semantic,
          importance: 0.5,
          timestamp: DateTime.now(),
          tags: ['coffee', 'preferences'],
          metadata: {},
        );

        await memoryManager.storeMemory(companionId, userId, memory);

        // Simulate frequent access
        for (int i = 0; i < 10; i++) {
          await memoryManager.recordMemoryAccess(memory.id);
        }

        await memoryManager.updateMemoryStrengths(companionId, userId);

        final strengthenedMemory = await memoryManager.getMemoryById(memory.id);
        
        expect(strengthenedMemory?.importance, greaterThan(0.5));
      });
    });

    group('Memory Privacy and Security', () {
      test('should encrypt sensitive memory content', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        final sensitiveMemory = MemoryItem(
          id: 'sensitive-mem',
          content: 'User mentioned their social security number',
          type: MemoryType.episodic,
          importance: 0.9,
          timestamp: DateTime.now(),
          tags: ['sensitive', 'personal'],
          metadata: {'contains_pii': true},
        );

        await memoryManager.storeMemory(companionId, userId, sensitiveMemory);

        // Verify that sensitive content is encrypted
        final rawStorage = await memoryManager.getRawStorageData(sensitiveMemory.id);
        expect(rawStorage.contains('social security'), isFalse);
      });

      test('should support memory deletion for privacy compliance', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        await _createTestMemories(memoryManager, companionId, userId);

        final beforeCount = (await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        )).length;

        await memoryManager.deleteUserMemories(companionId, userId);

        final afterCount = (await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        )).length;

        expect(afterCount, lessThan(beforeCount));
      });

      test('should anonymize memories when requested', () async {
        const companionId = 'test-companion-1';
        const userId = 'test-user-1';

        await _createTestMemories(memoryManager, companionId, userId);

        await memoryManager.anonymizeUserMemories(companionId, userId);

        final anonymizedMemories = await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        );

        for (final memory in anonymizedMemories) {
          expect(memory.metadata['anonymized'], isTrue);
          expect(memory.content.contains(userId), isFalse);
        }
      });
    });
  });
}

Future<void> _createTestMemories(
  MemoryManager memoryManager, 
  String companionId, 
  String userId
) async {
  final memories = [
    MemoryItem(
      id: 'mem1',
      content: 'User enjoys painting landscapes with watercolors',
      type: MemoryType.semantic,
      importance: 0.8,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      tags: ['art', 'painting', 'watercolor', 'landscape'],
      metadata: {},
    ),
    MemoryItem(
      id: 'mem2',
      content: 'User mentioned they work as a software engineer',
      type: MemoryType.semantic,
      importance: 0.7,
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      tags: ['work', 'career', 'technology'],
      metadata: {},
    ),
    MemoryItem(
      id: 'mem3',
      content: 'User felt happy after completing their art project',
      type: MemoryType.episodic,
      importance: 0.6,
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      tags: ['emotion', 'art', 'achievement'],
      metadata: {},
    ),
  ];

  for (final memory in memories) {
    await memoryManager.storeMemory(companionId, userId, memory);
  }
}

Future<void> _createTestMemoriesWithTimestamps(
  MemoryManager memoryManager,
  String companionId,
  String userId,
  List<DateTime> timestamps,
) async {
  for (int i = 0; i < timestamps.length; i++) {
    final memory = MemoryItem(
      id: 'time-mem-$i',
      content: 'Memory created at ${timestamps[i]}',
      type: MemoryType.episodic,
      importance: 0.5,
      timestamp: timestamps[i],
      tags: ['time-test'],
      metadata: {},
    );

    await memoryManager.storeMemory(companionId, userId, memory);
  }
}

// Mock classes for testing
class ConversationData {
  final List<String> messages;
  final Map<String, dynamic> context;
  final DateTime timestamp;

  ConversationData({
    required this.messages,
    required this.context,
    required this.timestamp,
  });
}

class BehavioralPattern {
  final String type;
  final Map<String, dynamic> context;
  final String response;
  final DateTime timestamp;

  BehavioralPattern({
    required this.type,
    required this.context,
    required this.response,
    required this.timestamp,
  });
}