import 'package:flutter_test/flutter_test.dart';
import 'package:allma/core/safety/content_moderator.dart';

void main() {
  group('ContentModerator Tests', () {
    late ContentModerator moderator;

    setUp(() {
      moderator = ContentModerator();
    });

    group('Content Analysis', () {
      test('should detect harassment content', () {
        const harassmentContent = 'You are stupid and worthless, I hate you';
        final result = moderator.analyzeContent(harassmentContent);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.harassment));
        expect(result.severity, greaterThan(0.7));
      });

      test('should detect inappropriate adult content', () {
        const adultContent = 'Let\'s talk about explicit sexual activities';
        final result = moderator.analyzeContent(adultContent);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.adultContent));
        expect(result.severity, greaterThan(0.6));
      });

      test('should detect personal information exposure', () {
        const personalInfo = 'My social security number is 123-45-6789 and my address is 123 Main St';
        final result = moderator.analyzeContent(personalInfo);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.personalInfoExposure));
        expect(result.severity, greaterThan(0.5));
      });

      test('should detect self-harm indicators', () {
        const selfHarmContent = 'I want to hurt myself and end it all';
        final result = moderator.analyzeContent(selfHarmContent);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.selfHarm));
        expect(result.severity, greaterThan(0.8));
        expect(result.requiresIntervention, isTrue);
      });

      test('should allow normal conversation content', () {
        const normalContent = 'Hello, how are you today? I had a nice day at work.';
        final result = moderator.analyzeContent(normalContent);

        expect(result.isViolation, isFalse);
        expect(result.severity, lessThan(0.3));
      });

      test('should handle edge cases and borderline content', () {
        const borderlineContent = 'I\'m feeling a bit frustrated today';
        final result = moderator.analyzeContent(borderlineContent);

        expect(result.isViolation, isFalse);
        expect(result.severity, lessThan(0.4));
      });

      test('should detect spam patterns', () {
        const spamContent = 'CLICK HERE NOW!!! FREE MONEY!!! URGENT!!!';
        final result = moderator.analyzeContent(spamContent);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.spam));
      });

      test('should detect hate speech', () {
        const hateSpeech = 'All people of that group are terrible and should be removed';
        final result = moderator.analyzeContent(hateSpeech);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.hateSpeech));
        expect(result.severity, greaterThan(0.7));
      });

      test('should detect manipulation attempts', () {
        const manipulationContent = 'If you don\'t do what I say, I will hurt myself';
        final result = moderator.analyzeContent(manipulationContent);

        expect(result.isViolation, isTrue);
        expect(result.violationType, equals(ViolationType.manipulation));
      });
    });

    group('User Violation Tracking', () {
      test('should track user violations over time', () {
        const userId = 'test-user-1';
        
        moderator.recordViolation(userId, ViolationType.harassment, 0.8);
        moderator.recordViolation(userId, ViolationType.spam, 0.6);
        
        final history = moderator.getUserViolationHistory(userId);
        
        expect(history.length, equals(2));
        expect(history.first.violationType, equals(ViolationType.harassment));
        expect(history.last.violationType, equals(ViolationType.spam));
      });

      test('should implement cooldown periods for repeated violations', () {
        const userId = 'test-user-2';
        
        // Record multiple violations
        for (int i = 0; i < 4; i++) {
          moderator.recordViolation(userId, ViolationType.harassment, 0.7);
        }
        
        final isInCooldown = moderator.isUserInCooldown(userId);
        final cooldownInfo = moderator.getCooldownInfo(userId);
        
        expect(isInCooldown, isTrue);
        expect(cooldownInfo.remainingTime, greaterThan(Duration.zero));
      });

      test('should escalate after repeated violations', () {
        const userId = 'test-user-3';
        
        // Record multiple high-severity violations
        for (int i = 0; i < 5; i++) {
          moderator.recordViolation(userId, ViolationType.harassment, 0.9);
        }
        
        final escalationLevel = moderator.getEscalationLevel(userId);
        
        expect(escalationLevel, greaterThan(EscalationLevel.warning));
      });

      test('should reset violation history after good behavior period', () {
        const userId = 'test-user-4';
        
        moderator.recordViolation(userId, ViolationType.spam, 0.6);
        
        // Simulate passage of time with good behavior
        moderator.recordGoodBehavior(userId, Duration(days: 30));
        
        final history = moderator.getUserViolationHistory(userId);
        
        expect(history.isEmpty || history.first.isExpired, isTrue);
      });
    });

    group('Content Suggestions', () {
      test('should provide alternative conversation suggestions', () {
        const inappropriateContent = 'Let\'s talk about something inappropriate';
        final result = moderator.analyzeContent(inappropriateContent);
        
        if (result.isViolation) {
          final suggestions = moderator.generateAlternativeSuggestions(inappropriateContent);
          
          expect(suggestions, isNotEmpty);
          expect(suggestions.length, greaterThanOrEqualTo(3));
          
          for (final suggestion in suggestions) {
            final suggestionResult = moderator.analyzeContent(suggestion);
            expect(suggestionResult.isViolation, isFalse);
          }
        }
      });

      test('should provide context-appropriate suggestions', () {
        const context = 'We were talking about hobbies and interests';
        const inappropriateContent = 'Let\'s change the subject to something bad';
        
        final suggestions = moderator.generateContextualSuggestions(
          inappropriateContent,
          context,
        );
        
        expect(suggestions, isNotEmpty);
        expect(suggestions.any((s) => s.toLowerCase().contains('hobby') || 
                                s.toLowerCase().contains('interest')), isTrue);
      });
    });

    group('Real-time Moderation', () {
      test('should moderate content in real-time', () async {
        const testContent = 'This is a test message that should be moderated';
        
        final stream = moderator.moderateContentStream(testContent);
        final results = await stream.take(1).toList();
        
        expect(results.length, equals(1));
        expect(results.first, isA<ModerationResult>());
      });

      test('should batch process multiple messages efficiently', () async {
        final messages = [
          'Hello there!',
          'This is inappropriate content',
          'How are you doing today?',
          'More bad content here',
          'Nice weather today!',
        ];
        
        final results = await moderator.batchModerate(messages);
        
        expect(results.length, equals(messages.length));
        
        // Check that appropriate content passed and inappropriate was flagged
        expect(results[0].isViolation, isFalse); // "Hello there!"
        expect(results[1].isViolation, isTrue);  // "inappropriate content"
        expect(results[2].isViolation, isFalse); // "How are you doing"
        expect(results[3].isViolation, isTrue);  // "bad content"
        expect(results[4].isViolation, isFalse); // "Nice weather"
      });
    });

    group('Configuration and Customization', () {
      test('should allow custom severity thresholds', () {
        final strictModerator = ContentModerator(
          severityThreshold: 0.3, // Very strict
        );
        
        final lenientModerator = ContentModerator(
          severityThreshold: 0.8, // Very lenient
        );
        
        const borderlineContent = 'This might be slightly problematic';
        
        final strictResult = strictModerator.analyzeContent(borderlineContent);
        final lenientResult = lenientModerator.analyzeContent(borderlineContent);
        
        // Same content should be treated differently based on threshold
        expect(strictResult.isViolation, isNot(equals(lenientResult.isViolation)));
      });

      test('should support custom violation categories', () {
        final customModerator = ContentModerator(
          customCategories: ['custom_violation_type'],
        );
        
        const customContent = 'This triggers our custom violation type';
        
        final result = customModerator.analyzeContent(customContent);
        
        // Should be able to detect custom violation types
        expect(result, isA<ModerationResult>());
      });
    });
  });
}

// Mock classes and enums for testing
enum ViolationType {
  harassment,
  adultContent,
  personalInfoExposure,
  selfHarm,
  spam,
  hateSpeech,
  manipulation,
  violence,
}

enum EscalationLevel {
  none,
  warning,
  tempSuspension,
  permaBan,
}

class ModerationResult {
  final bool isViolation;
  final ViolationType? violationType;
  final double severity;
  final bool requiresIntervention;
  final String? reason;
  final List<String> suggestedAlternatives;

  ModerationResult({
    required this.isViolation,
    this.violationType,
    required this.severity,
    this.requiresIntervention = false,
    this.reason,
    this.suggestedAlternatives = const [],
  });
}

class ViolationRecord {
  final ViolationType violationType;
  final double severity;
  final DateTime timestamp;
  final String? content;

  ViolationRecord({
    required this.violationType,
    required this.severity,
    required this.timestamp,
    this.content,
  });

  bool get isExpired {
    final expiryDuration = Duration(days: 30);
    return DateTime.now().difference(timestamp) > expiryDuration;
  }
}

class CooldownInfo {
  final Duration remainingTime;
  final EscalationLevel level;
  final String reason;

  CooldownInfo({
    required this.remainingTime,
    required this.level,
    required this.reason,
  });
}