import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:allma/core/ai/gemini_service.dart';
import 'package:allma/core/companions/services/companion_service.dart';
import 'package:allma/core/memory/memory_manager.dart';
import 'package:allma/core/companions/models/companion.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI System Integration Tests', () {
    late GeminiService geminiService;
    late CompanionService companionService;
    late MemoryManager memoryManager;

    setUpAll(() async {
      geminiService = GeminiService();
      memoryManager = MemoryManager();
      companionService = CompanionService(
        geminiService: geminiService,
        memoryManager: memoryManager,
      );
      
      // Initialize services
      await geminiService.initialize();
      await memoryManager.initialize();
    });

    group('Companion-AI Integration', () {
      testWidgets('should generate personality-consistent responses', 
          (WidgetTester tester) async {
        // Test extroverted companion
        final extrovertedCompanion = _createTestCompanion(
          personality: const CompanionPersonality(
            extraversion: 0.9,
            agreeableness: 0.8,
            conscientiousness: 0.6,
            neuroticism: 0.2,
            openness: 0.7,
            traits: ['energetic', 'social', 'enthusiastic'],
          ),
        );

        // Test introverted companion
        final introvertedCompanion = _createTestCompanion(
          personality: const CompanionPersonality(
            extraversion: 0.2,
            agreeableness: 0.7,
            conscientiousness: 0.8,
            neuroticism: 0.4,
            openness: 0.6,
            traits: ['thoughtful', 'reserved', 'careful'],
          ),
        );

        const testMessage = 'Tell me about your favorite activities';

        final extrovertResponse = await companionService.generateCompanionResponse(
          companionId: extrovertedCompanion.id,
          userMessage: testMessage,
          conversationHistory: [],
          userId: 'test-user',
        );

        final introvertResponse = await companionService.generateCompanionResponse(
          companionId: introvertedCompanion.id,
          userMessage: testMessage,
          conversationHistory: [],
          userId: 'test-user',
        );

        // Responses should be different and reflect personality
        expect(extrovertResponse.response, isNot(equals(introvertResponse.response)));
        
        // Extroverted response should be more energetic/social
        expect(extrovertResponse.response.toLowerCase(), 
               anyOf(contains('love'), contains('exciting'), contains('people'), 
                     contains('social'), contains('energy')));
        
        // Introverted response should be more thoughtful/reserved
        expect(introvertResponse.response.toLowerCase(),
               anyOf(contains('enjoy'), contains('peaceful'), contains('quiet'),
                     contains('thoughtful'), contains('reflection')));
      });

      testWidgets('should maintain conversation context across multiple messages', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';
        
        final conversationFlow = [
          'Hi, I love reading science fiction books',
          'What are some of your favorite sci-fi authors?',
          'Have you read any books by that author recently?',
          'What did you think about the plot?',
        ];

        List<Message> conversationHistory = [];
        
        for (int i = 0; i < conversationFlow.length; i++) {
          final result = await companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: conversationFlow[i],
            conversationHistory: conversationHistory,
            userId: userId,
          );

          expect(result.response, isNotEmpty);
          
          // Add messages to history
          conversationHistory.addAll([
            Message(
              id: 'user-${i + 1}',
              content: conversationFlow[i],
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
            Message(
              id: 'assistant-${i + 1}',
              content: result.response,
              role: MessageRole.assistant,
              timestamp: DateTime.now(),
            ),
          ]);

          // Later responses should reference earlier context
          if (i >= 2) {
            expect(result.response.toLowerCase(), 
                   anyOf(contains('book'), contains('author'), contains('read'),
                         contains('sci'), contains('fiction')));
          }
        }
      });

      testWidgets('should adapt responses based on conversation history and memory', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        // First conversation - establish user preferences
        final firstResponse = await companionService.generateCompanionResponse(
          companionId: companion.id,
          userMessage: 'I absolutely love painting watercolor landscapes',
          conversationHistory: [],
          userId: userId,
        );

        expect(firstResponse.response, isNotEmpty);

        // Wait a bit to allow memory formation
        await Future.delayed(Duration(milliseconds: 100));

        // Second conversation - should remember the preference
        final secondResponse = await companionService.generateCompanionResponse(
          companionId: companion.id,
          userMessage: 'What should I do this weekend?',
          conversationHistory: [],
          userId: userId,
        );

        // Should reference the previously mentioned interest in art/painting
        expect(secondResponse.response.toLowerCase(),
               anyOf(contains('paint'), contains('art'), contains('watercolor'),
                     contains('landscape'), contains('creative')));
      });
    });

    group('Memory-AI Integration', () {
      testWidgets('should incorporate relevant memories into responses', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        // Create some memories first
        await _createTestMemories(memoryManager, companion.id, userId);

        final result = await companionService.generateCompanionResponse(
          companionId: companion.id,
          userMessage: 'I want to start a new creative hobby',
          conversationHistory: [],
          userId: userId,
        );

        // Should incorporate the painting/art memory
        expect(result.response.toLowerCase(),
               anyOf(contains('paint'), contains('art'), contains('watercolor'),
                     contains('creative'), contains('drawing')));
      });

      testWidgets('should form new memories from AI conversations', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        await companionService.generateCompanionResponse(
          companionId: companion.id,
          userMessage: 'I just started learning to play the guitar and I love it!',
          conversationHistory: [],
          userId: userId,
        );

        // Wait for memory formation
        await Future.delayed(Duration(milliseconds: 200));

        // Check that memory was formed
        final memories = await memoryManager.searchMemories(
          companionId: companion.id,
          userId: userId,
          query: 'guitar',
        );

        expect(memories, isNotEmpty);
        expect(memories.any((m) => m.content.toLowerCase().contains('guitar')), isTrue);
      });

      testWidgets('should handle memory retrieval failures gracefully', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'non-existent-user';

        // Try to generate response for user with no memories
        final result = await companionService.generateCompanionResponse(
          companionId: companion.id,
          userMessage: 'Hello, how are you today?',
          conversationHistory: [],
          userId: userId,
        );

        // Should still generate a response even without memories
        expect(result.response, isNotEmpty);
        expect(result.status, equals(CompanionResponseStatus.success));
      });
    });

    group('AI Performance and Reliability', () {
      testWidgets('should handle API rate limiting gracefully', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        // Make multiple rapid requests
        final futures = List.generate(20, (index) =>
          companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: 'Test message $index',
            conversationHistory: [],
            userId: userId,
          )
        );

        final results = await Future.wait(futures);

        // All requests should eventually succeed or be handled gracefully
        expect(results.length, equals(20));
        expect(results.every((r) => r.status != CompanionResponseStatus.error), isTrue);
      });

      testWidgets('should maintain response quality under load', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const numberOfRequests = 10;

        final futures = List.generate(numberOfRequests, (index) =>
          companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: 'Tell me something interesting about space exploration',
            conversationHistory: [],
            userId: 'user-$index',
          )
        );

        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(futures);
        stopwatch.stop();

        // All responses should be meaningful and non-empty
        expect(results.length, equals(numberOfRequests));
        expect(results.every((r) => r.response.length > 20), isTrue);
        expect(results.every((r) => r.response.toLowerCase().contains('space') ||
                                   r.response.toLowerCase().contains('explore')), isTrue);

        // Should complete within reasonable time (30 seconds for 10 requests)
        expect(stopwatch.elapsedSeconds, lessThan(30));
      });

      testWidgets('should handle network interruptions', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        // This would need to be mocked to simulate network issues
        // For now, we test that the system handles errors gracefully
        try {
          final result = await companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: 'This might fail due to network issues',
            conversationHistory: [],
            userId: userId,
          );

          // Should either succeed or fail gracefully
          expect(result, isNotNull);
          
        } catch (e) {
          // Should not throw unhandled exceptions
          fail('Should handle network errors gracefully, but threw: $e');
        }
      });
    });

    group('Response Quality and Consistency', () {
      testWidgets('should generate appropriate length responses', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        final testCases = [
          {
            'input': 'Hi',
            'expectedMinLength': 10,
            'expectedMaxLength': 100,
          },
          {
            'input': 'Can you tell me a detailed story about space exploration?',
            'expectedMinLength': 100,
            'expectedMaxLength': 1000,
          },
          {
            'input': 'Yes',
            'expectedMinLength': 5,
            'expectedMaxLength': 50,
          },
        ];

        for (final testCase in testCases) {
          final result = await companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: testCase['input'] as String,
            conversationHistory: [],
            userId: userId,
          );

          expect(result.response.length, 
                 greaterThanOrEqualTo(testCase['expectedMinLength'] as int));
          expect(result.response.length, 
                 lessThanOrEqualTo(testCase['expectedMaxLength'] as int));
        }
      });

      testWidgets('should avoid repetitive responses', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        final responses = <String>[];
        
        // Ask the same question multiple times
        for (int i = 0; i < 5; i++) {
          final result = await companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: 'What\'s your favorite color?',
            conversationHistory: [],
            userId: userId,
          );

          responses.add(result.response);
        }

        // Responses should not be identical
        final uniqueResponses = responses.toSet();
        expect(uniqueResponses.length, greaterThan(1));
      });

      testWidgets('should maintain conversational flow', 
          (WidgetTester tester) async {
        final companion = _createTestCompanion();
        const userId = 'test-user';

        final conversationSteps = [
          'Hi there! How are you doing today?',
          'That\'s great to hear! What are your plans for today?',
          'That sounds really interesting. Can you tell me more about it?',
          'Wow, that\'s fascinating! Have you always been interested in that?',
        ];

        List<Message> conversationHistory = [];
        
        for (int i = 0; i < conversationSteps.length; i++) {
          final result = await companionService.generateCompanionResponse(
            companionId: companion.id,
            userMessage: conversationSteps[i],
            conversationHistory: conversationHistory,
            userId: userId,
          );

          expect(result.response, isNotEmpty);
          
          // Response should acknowledge the conversation flow
          if (i > 0) {
            expect(result.response.toLowerCase(),
                   anyOf(contains('thank'), contains('yes'), contains('sure'),
                         contains('i'), contains('that')));
          }

          conversationHistory.addAll([
            Message(
              id: 'user-${i + 1}',
              content: conversationSteps[i],
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
            Message(
              id: 'assistant-${i + 1}',
              content: result.response,
              role: MessageRole.assistant,
              timestamp: DateTime.now(),
            ),
          ]);
        }
      });
    });
  });
}

Companion _createTestCompanion({CompanionPersonality? personality}) {
  return Companion(
    id: 'test-companion-${DateTime.now().millisecondsSinceEpoch}',
    name: 'Test Companion',
    description: 'A friendly AI companion for testing',
    appearance: const CompanionAppearance(
      avatar: '🤖',
      primaryColor: 0xFF2196F3,
      secondaryColor: 0xFF03DAC6,
      style: CompanionStyle.modern,
    ),
    personality: personality ?? const CompanionPersonality(
      extraversion: 0.7,
      agreeableness: 0.8,
      conscientiousness: 0.6,
      neuroticism: 0.3,
      openness: 0.9,
      traits: ['friendly', 'helpful', 'curious'],
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Future<void> _createTestMemories(
  MemoryManager memoryManager,
  String companionId,
  String userId,
) async {
  final memories = [
    MemoryItem(
      id: 'test-mem-1',
      content: 'User enjoys painting watercolor landscapes',
      type: MemoryType.semantic,
      importance: 0.8,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      tags: ['art', 'painting', 'watercolor', 'hobby'],
      metadata: {},
    ),
    MemoryItem(
      id: 'test-mem-2',
      content: 'User mentioned they work in software development',
      type: MemoryType.semantic,
      importance: 0.7,
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      tags: ['work', 'career', 'software', 'technology'],
      metadata: {},
    ),
  ];

  for (final memory in memories) {
    await memoryManager.storeMemory(companionId, userId, memory);
  }
}

// Mock classes for integration testing
enum CompanionResponseStatus {
  success,
  blocked,
  interventionNeeded,
  regenerated,
  error,
}

enum MessageRole {
  user,
  assistant,
  system,
}

enum MemoryType {
  episodic,
  semantic,
  procedural,
}

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });
}

class MemoryItem {
  final String id;
  final String content;
  final MemoryType type;
  final double importance;
  final DateTime timestamp;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  MemoryItem({
    required this.id,
    required this.content,
    required this.type,
    required this.importance,
    required this.timestamp,
    required this.tags,
    required this.metadata,
  });
}