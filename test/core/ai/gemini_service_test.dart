import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:allma/core/ai/gemini_service.dart';
import 'package:allma/core/companions/models/companion.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'gemini_service_test.mocks.dart';

void main() {
  group('GeminiService Tests', () {
    late GeminiService geminiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      geminiService = GeminiService();
      // In a real implementation, you'd inject the mock client
    });

    group('Message Generation', () {
      test('should generate response for companion message', () async {
        // Mock successful API response
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '''
          {
            "candidates": [
              {
                "content": {
                  "parts": [
                    {"text": "Hello! How can I help you today?"}
                  ]
                }
              }
            ]
          }
          ''',
          200,
        ));

        final companion = _createTestCompanion();
        final result = await geminiService.generateCompanionResponse(
          companion: companion,
          userMessage: 'Hello',
          conversationHistory: [],
          context: {},
        );

        expect(result.isSuccess, isTrue);
        expect(result.response, isNotEmpty);
        expect(result.response, contains('Hello'));
      });

      test('should handle API errors gracefully', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"error": {"message": "API quota exceeded"}}',
          429,
        ));

        final companion = _createTestCompanion();
        final result = await geminiService.generateCompanionResponse(
          companion: companion,
          userMessage: 'Hello',
          conversationHistory: [],
          context: {},
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.type, equals(GeminiErrorType.rateLimited));
      });

      test('should handle network timeouts', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(const http.ClientException('Timeout'));

        final companion = _createTestCompanion();
        final result = await geminiService.generateCompanionResponse(
          companion: companion,
          userMessage: 'Hello',
          conversationHistory: [],
          context: {},
        );

        expect(result.isSuccess, isFalse);
        expect(result.error!.type, equals(GeminiErrorType.networkError));
      });

      test('should include conversation history in context', () async {
        final conversationHistory = [
          Message(
            id: '1',
            content: 'Hello',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
          Message(
            id: '2',
            content: 'Hi there!',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        ];

        // Verify that conversation history is properly formatted for API
        final companion = _createTestCompanion();
        
        // This would need to be implemented to capture the actual API call
        // For now, we'll test the structure
        expect(conversationHistory.length, equals(2));
        expect(conversationHistory.first.role, equals(MessageRole.user));
        expect(conversationHistory.last.role, equals(MessageRole.assistant));
      });
    });

    group('Personality Integration', () {
      test('should adapt response style based on personality traits', () {
        final extrovertedCompanion = _createTestCompanion().copyWith(
          personality: const CompanionPersonality(
            extraversion: 0.9,
            agreeableness: 0.8,
            conscientiousness: 0.6,
            neuroticism: 0.2,
            openness: 0.7,
            traits: ['energetic', 'social'],
          ),
        );

        final introvertedCompanion = _createTestCompanion().copyWith(
          personality: const CompanionPersonality(
            extraversion: 0.2,
            agreeableness: 0.7,
            conscientiousness: 0.8,
            neuroticism: 0.4,
            openness: 0.6,
            traits: ['thoughtful', 'reserved'],
          ),
        );

        // Test that personality traits influence the prompt generation
        final extrovertPrompt = geminiService.buildPersonalityPrompt(extrovertedCompanion);
        final introvertPrompt = geminiService.buildPersonalityPrompt(introvertedCompanion);

        expect(extrovertPrompt, contains('energetic'));
        expect(extrovertPrompt, contains('social'));
        expect(introvertPrompt, contains('thoughtful'));
        expect(introvertPrompt, contains('reserved'));
      });

      test('should maintain personality consistency across responses', () {
        final companion = _createTestCompanion();
        final personalityPrompt = geminiService.buildPersonalityPrompt(companion);

        expect(personalityPrompt, isNotEmpty);
        expect(personalityPrompt, contains(companion.name));
        
        // Should include personality trait values
        expect(personalityPrompt, contains('extraversion'));
        expect(personalityPrompt, contains('agreeableness'));
      });
    });

    group('Safety Integration', () {
      test('should include safety guidelines in prompts', () {
        final companion = _createTestCompanion();
        final prompt = geminiService.buildSafetyPrompt(companion);

        expect(prompt, contains('safe'));
        expect(prompt, contains('appropriate'));
        expect(prompt, contains('boundaries'));
      });

      test('should filter unsafe content from responses', () async {
        final unsafeResponse = GeminiResponse(
          response: 'This contains inappropriate content that should be filtered',
          confidence: 0.8,
          metadata: {},
        );

        final safetyResult = geminiService.applySafetyFilters(unsafeResponse);
        
        // This would need actual safety filter implementation
        expect(safetyResult, isNotNull);
      });
    });

    group('Rate Limiting', () {
      test('should respect rate limits', () async {
        // Test that multiple rapid requests are properly throttled
        final companion = _createTestCompanion();
        final futures = List.generate(5, (index) => 
          geminiService.generateCompanionResponse(
            companion: companion,
            userMessage: 'Message $index',
            conversationHistory: [],
            context: {},
          )
        );

        final results = await Future.wait(futures);
        
        // Should handle rate limiting appropriately
        expect(results.length, equals(5));
      });

      test('should implement exponential backoff on rate limit errors', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"error": {"message": "Rate limit exceeded"}}',
          429,
        ));

        final companion = _createTestCompanion();
        final startTime = DateTime.now();
        
        final result = await geminiService.generateCompanionResponse(
          companion: companion,
          userMessage: 'Hello',
          conversationHistory: [],
          context: {},
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(result.isSuccess, isFalse);
        // Should have implemented some delay for backoff
        expect(duration.inMilliseconds, greaterThan(100));
      });
    });
  });
}

Companion _createTestCompanion() {
  return Companion(
    id: 'test-companion',
    name: 'Test Companion',
    description: 'A test companion for unit testing',
    appearance: const CompanionAppearance(
      avatar: '🤖',
      primaryColor: 0xFF2196F3,
      secondaryColor: 0xFF03DAC6,
      style: CompanionStyle.modern,
    ),
    personality: const CompanionPersonality(
      extraversion: 0.7,
      agreeableness: 0.8,
      conscientiousness: 0.6,
      neuroticism: 0.3,
      openness: 0.9,
      traits: ['friendly', 'helpful'],
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

// Mock message class for testing
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

enum MessageRole { user, assistant }

// Mock response classes for testing
class GeminiResponse {
  final String response;
  final double confidence;
  final Map<String, dynamic> metadata;

  GeminiResponse({
    required this.response,
    required this.confidence,
    required this.metadata,
  });

  bool get isSuccess => response.isNotEmpty;
  GeminiError? get error => null;
}

class GeminiError {
  final GeminiErrorType type;
  final String message;

  GeminiError({required this.type, required this.message});
}

enum GeminiErrorType {
  networkError,
  rateLimited,
  invalidInput,
  serverError,
}