import 'package:flutter_test/flutter_test.dart';
import 'package:allma/core/memory/memory_manager.dart';
import 'package:allma/core/memory/models/memory_item.dart';

void main() {
  group('Memory System Performance Tests', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager = MemoryManager();
    });

    group('Memory Storage Performance', () {
      test('should store large numbers of memories efficiently', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';
        const numberOfMemories = 1000;

        final stopwatch = Stopwatch()..start();

        // Store many memories
        for (int i = 0; i < numberOfMemories; i++) {
          final memory = MemoryItem(
            id: 'memory-$i',
            content: 'Test memory content number $i with some additional text to make it realistic',
            type: MemoryType.episodic,
            importance: (i % 10) / 10.0,
            timestamp: DateTime.now().subtract(Duration(minutes: i)),
            tags: ['test', 'performance', 'memory-$i'],
            metadata: {'index': i, 'batch': 'performance-test'},
          );

          await memoryManager.storeMemory(companionId, userId, memory);

          // Log progress every 100 memories
          if (i % 100 == 0) {
            print('Stored ${i + 1} memories...');
          }
        }

        stopwatch.stop();

        print('Stored $numberOfMemories memories in ${stopwatch.elapsedMilliseconds}ms');
        
        // Should store 1000 memories within 10 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
        
        // Verify all memories were stored
        final allMemories = await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        );
        
        expect(allMemories.length, equals(numberOfMemories));
      });

      test('should handle concurrent memory operations', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';
        const numberOfConcurrentOps = 50;

        final stopwatch = Stopwatch()..start();

        // Perform concurrent memory operations
        final futures = List.generate(numberOfConcurrentOps, (index) async {
          final memory = MemoryItem(
            id: 'concurrent-memory-$index',
            content: 'Concurrent memory operation $index',
            type: MemoryType.semantic,
            importance: 0.5,
            timestamp: DateTime.now(),
            tags: ['concurrent', 'test'],
            metadata: {'index': index},
          );

          await memoryManager.storeMemory(companionId, userId, memory);
          
          // Also perform a retrieval operation
          await memoryManager.getRelevantMemories(
            companionId: companionId,
            userId: userId,
            context: {'topic': 'test'},
            limit: 5,
          );
        });

        await Future.wait(futures);
        stopwatch.stop();

        print('Completed $numberOfConcurrentOps concurrent operations in ${stopwatch.elapsedMilliseconds}ms');
        
        // Should complete concurrent operations within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });

    group('Memory Retrieval Performance', () {
      test('should retrieve relevant memories quickly from large dataset', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';
        const datasetSize = 10000;

        // First, create a large dataset
        print('Creating large memory dataset...');
        await _createLargeMemoryDataset(memoryManager, companionId, userId, datasetSize);

        final stopwatch = Stopwatch()..start();

        // Perform memory retrieval
        final relevantMemories = await memoryManager.getRelevantMemories(
          companionId: companionId,
          userId: userId,
          context: {'topic': 'art', 'mood': 'creative'},
          limit: 10,
        );

        stopwatch.stop();

        print('Retrieved ${relevantMemories.length} memories from $datasetSize dataset in ${stopwatch.elapsedMilliseconds}ms');
        
        // Should retrieve memories within 500ms even from large dataset
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(relevantMemories.length, lessThanOrEqualTo(10));
      });

      test('should handle complex search queries efficiently', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';

        // Create diverse memories
        await _createDiverseMemories(memoryManager, companionId, userId);

        final searchQueries = [
          'painting watercolor landscapes',
          'music guitar learning',
          'work software development',
          'travel adventure mountains',
          'cooking recipes italian',
        ];

        final stopwatch = Stopwatch()..start();

        for (final query in searchQueries) {
          final results = await memoryManager.searchMemories(
            companionId: companionId,
            userId: userId,
            query: query,
          );

          expect(results, isNotEmpty);
        }

        stopwatch.stop();

        print('Completed ${searchQueries.length} complex searches in ${stopwatch.elapsedMilliseconds}ms');
        
        // Should complete all searches within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('should maintain performance with temporal queries', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';

        // Create memories across different time periods
        await _createTimeBasedMemories(memoryManager, companionId, userId);

        final stopwatch = Stopwatch()..start();

        final timeRanges = [
          (DateTime.now().subtract(Duration(days: 7)), DateTime.now()),
          (DateTime.now().subtract(Duration(days: 30)), DateTime.now().subtract(Duration(days: 7))),
          (DateTime.now().subtract(Duration(days: 90)), DateTime.now().subtract(Duration(days: 30))),
        ];

        for (final (startTime, endTime) in timeRanges) {
          final memories = await memoryManager.getMemoriesByTimeRange(
            companionId: companionId,
            userId: userId,
            startTime: startTime,
            endTime: endTime,
          );

          expect(memories, isNotEmpty);
        }

        stopwatch.stop();

        print('Completed temporal queries in ${stopwatch.elapsedMilliseconds}ms');
        
        // Should complete temporal queries within 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Memory Consolidation Performance', () {
      test('should consolidate memories efficiently', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';

        // Create many similar memories that can be consolidated
        await _createSimilarMemories(memoryManager, companionId, userId);

        final beforeCount = (await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        )).length;

        final stopwatch = Stopwatch()..start();

        await memoryManager.consolidateMemories(companionId, userId);

        stopwatch.stop();

        final afterCount = (await memoryManager.getAllMemories(
          companionId: companionId,
          userId: userId,
        )).length;

        print('Consolidated memories from $beforeCount to $afterCount in ${stopwatch.elapsedMilliseconds}ms');
        
        // Consolidation should complete within 3 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
        
        // Should have reduced the number of memories
        expect(afterCount, lessThan(beforeCount));
      });

      test('should apply temporal decay efficiently', () async {
        const companionId = 'test-companion';
        const userId = 'test-user';

        // Create memories with various ages
        await _createAgedMemories(memoryManager, companionId, userId);

        final stopwatch = Stopwatch()..start();

        await memoryManager.applyTemporalDecay(companionId, userId);

        stopwatch.stop();

        print('Applied temporal decay in ${stopwatch.elapsedMilliseconds}ms');
        
        // Temporal decay should complete within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('Stress Testing', () {
      test('should handle memory system under extreme load', () async {
        const companionId = 'stress-test-companion';
        const userId = 'stress-test-user';
        const extremeLoad = 50000;

        print('Starting extreme load test with $extremeLoad operations...');

        final stopwatch = Stopwatch()..start();

        // Perform mixed operations under extreme load
        final futures = <Future>[];

        // 60% storage operations
        for (int i = 0; i < (extremeLoad * 0.6); i++) {
          futures.add(_storeTestMemory(memoryManager, companionId, userId, i));
        }

        // 30% retrieval operations
        for (int i = 0; i < (extremeLoad * 0.3); i++) {
          futures.add(_retrieveTestMemories(memoryManager, companionId, userId));
        }

        // 10% search operations
        for (int i = 0; i < (extremeLoad * 0.1); i++) {
          futures.add(_searchTestMemories(memoryManager, companionId, userId, i));
        }

        await Future.wait(futures);
        stopwatch.stop();

        print('Completed extreme load test in ${stopwatch.elapsedSeconds} seconds');
        
        // Should complete extreme load within 60 seconds
        expect(stopwatch.elapsedSeconds, lessThan(60));
      });

      test('should maintain consistency under concurrent access', () async {
        const companionId = 'concurrent-test-companion';
        const userId = 'concurrent-test-user';
        const concurrentUsers = 10;
        const operationsPerUser = 100;

        final stopwatch = Stopwatch()..start();

        final userFutures = List.generate(concurrentUsers, (userIndex) async {
          final currentUserId = '$userId-$userIndex';
          
          for (int opIndex = 0; opIndex < operationsPerUser; opIndex++) {
            // Mix of operations for each user
            await _storeTestMemory(memoryManager, companionId, currentUserId, opIndex);
            
            if (opIndex % 5 == 0) {
              await _retrieveTestMemories(memoryManager, companionId, currentUserId);
            }
            
            if (opIndex % 10 == 0) {
              await _searchTestMemories(memoryManager, companionId, currentUserId, opIndex);
            }
          }
        });

        await Future.wait(userFutures);
        stopwatch.stop();

        print('Completed concurrent access test with $concurrentUsers users in ${stopwatch.elapsedSeconds} seconds');
        
        // Should handle concurrent access within 30 seconds
        expect(stopwatch.elapsedSeconds, lessThan(30));

        // Verify data consistency
        for (int userIndex = 0; userIndex < concurrentUsers; userIndex++) {
          final currentUserId = '$userId-$userIndex';
          final userMemories = await memoryManager.getAllMemories(
            companionId: companionId,
            userId: currentUserId,
          );
          
          expect(userMemories.length, equals(operationsPerUser));
        }
      });
    });
  });
}

// Helper functions for memory performance testing

Future<void> _createLargeMemoryDataset(
  MemoryManager memoryManager,
  String companionId,
  String userId,
  int size,
) async {
  final topics = ['art', 'music', 'work', 'travel', 'food', 'sports', 'books', 'movies'];
  final moods = ['happy', 'sad', 'excited', 'calm', 'creative', 'focused'];

  for (int i = 0; i < size; i++) {
    final topic = topics[i % topics.length];
    final mood = moods[i % moods.length];
    
    final memory = MemoryItem(
      id: 'large-dataset-$i',
      content: 'This is memory $i about $topic when feeling $mood',
      type: MemoryType.values[i % MemoryType.values.length],
      importance: (i % 10) / 10.0,
      timestamp: DateTime.now().subtract(Duration(hours: i)),
      tags: [topic, mood, 'dataset'],
      metadata: {'index': i, 'topic': topic, 'mood': mood},
    );

    await memoryManager.storeMemory(companionId, userId, memory);

    if (i % 1000 == 0) {
      print('Created ${i + 1} memories...');
    }
  }
}

Future<void> _createDiverseMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
) async {
  final memories = [
    'User loves painting watercolor landscapes in the morning',
    'User is learning to play guitar and practices daily',
    'User works as a software developer and enjoys coding',
    'User dreams of traveling to mountain ranges for hiking',
    'User enjoys cooking Italian recipes on weekends',
    'User reads science fiction novels before bed',
    'User plays tennis every Tuesday evening',
    'User collects vintage postcards from around the world',
  ];

  for (int i = 0; i < memories.length; i++) {
    final memory = MemoryItem(
      id: 'diverse-$i',
      content: memories[i],
      type: MemoryType.semantic,
      importance: 0.7 + (i * 0.1) % 0.3,
      timestamp: DateTime.now().subtract(Duration(days: i)),
      tags: memories[i].split(' ').where((w) => w.length > 3).take(3).toList(),
      metadata: {'category': 'diverse'},
    );

    await memoryManager.storeMemory(companionId, userId, memory);
  }
}

Future<void> _createTimeBasedMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
) async {
  final now = DateTime.now();
  final timePoints = [
    now.subtract(Duration(days: 1)),
    now.subtract(Duration(days: 7)),
    now.subtract(Duration(days: 14)),
    now.subtract(Duration(days: 30)),
    now.subtract(Duration(days: 60)),
    now.subtract(Duration(days: 90)),
  ];

  for (int i = 0; i < timePoints.length; i++) {
    for (int j = 0; j < 10; j++) {
      final memory = MemoryItem(
        id: 'time-based-$i-$j',
        content: 'Memory from ${timePoints[i].day}/${timePoints[i].month} - event $j',
        type: MemoryType.episodic,
        importance: 0.5,
        timestamp: timePoints[i].add(Duration(hours: j)),
        tags: ['temporal', 'test'],
        metadata: {'timePoint': i, 'event': j},
      );

      await memoryManager.storeMemory(companionId, userId, memory);
    }
  }
}

Future<void> _createSimilarMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
) async {
  final baseMemories = [
    'User likes painting',
    'User enjoys painting',
    'User loves to paint',
    'User is interested in painting',
    'User paints often',
  ];

  for (int i = 0; i < baseMemories.length; i++) {
    for (int j = 0; j < 5; j++) {
      final memory = MemoryItem(
        id: 'similar-$i-$j',
        content: '${baseMemories[i]} variation $j',
        type: MemoryType.semantic,
        importance: 0.6 + (j * 0.05),
        timestamp: DateTime.now().subtract(Duration(hours: i * 5 + j)),
        tags: ['painting', 'art', 'hobby'],
        metadata: {'base': i, 'variation': j},
      );

      await memoryManager.storeMemory(companionId, userId, memory);
    }
  }
}

Future<void> _createAgedMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
) async {
  final ages = [1, 7, 30, 90, 180, 365]; // days

  for (final age in ages) {
    for (int i = 0; i < 10; i++) {
      final memory = MemoryItem(
        id: 'aged-$age-$i',
        content: 'Memory that is $age days old - instance $i',
        type: MemoryType.episodic,
        importance: 0.8, // Start with high importance
        timestamp: DateTime.now().subtract(Duration(days: age)),
        tags: ['aged', 'decay-test'],
        metadata: {'age': age, 'instance': i},
      );

      await memoryManager.storeMemory(companionId, userId, memory);
    }
  }
}

Future<void> _storeTestMemory(
  MemoryManager memoryManager,
  String companionId,
  String userId,
  int index,
) async {
  final memory = MemoryItem(
    id: 'stress-test-$index',
    content: 'Stress test memory $index with some content',
    type: MemoryType.values[index % MemoryType.values.length],
    importance: (index % 10) / 10.0,
    timestamp: DateTime.now().subtract(Duration(seconds: index)),
    tags: ['stress', 'test', 'memory-$index'],
    metadata: {'index': index},
  );

  await memoryManager.storeMemory(companionId, userId, memory);
}

Future<void> _retrieveTestMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
) async {
  await memoryManager.getRelevantMemories(
    companionId: companionId,
    userId: userId,
    context: {'topic': 'test'},
    limit: 5,
  );
}

Future<void> _searchTestMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
  int index,
) async {
  await memoryManager.searchMemories(
    companionId: companionId,
    userId: userId,
    query: 'stress test $index',
  );
}

enum MemoryType {
  episodic,
  semantic,
  procedural,
}