import 'package:flutter_test/flutter_test.dart';
import 'package:allma/core/companions/models/companion.dart';

void main() {
  group('Companion Model Tests', () {
    late Companion testCompanion;

    setUp(() {
      testCompanion = Companion(
        id: 'test-companion-1',
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
          traits: ['friendly', 'helpful', 'creative'],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite: false,
        isActive: true,
      );
    });

    test('should create companion with valid properties', () {
      expect(testCompanion.id, equals('test-companion-1'));
      expect(testCompanion.name, equals('Test Companion'));
      expect(testCompanion.description, equals('A test companion for unit testing'));
      expect(testCompanion.isFavorite, isFalse);
      expect(testCompanion.isActive, isTrue);
    });

    test('should have valid personality traits', () {
      expect(testCompanion.personality.extraversion, equals(0.7));
      expect(testCompanion.personality.agreeableness, equals(0.8));
      expect(testCompanion.personality.conscientiousness, equals(0.6));
      expect(testCompanion.personality.neuroticism, equals(0.3));
      expect(testCompanion.personality.openness, equals(0.9));
      expect(testCompanion.personality.traits, contains('friendly'));
      expect(testCompanion.personality.traits, contains('helpful'));
      expect(testCompanion.personality.traits, contains('creative'));
    });

    test('should have valid appearance properties', () {
      expect(testCompanion.appearance.avatar, equals('🤖'));
      expect(testCompanion.appearance.primaryColor, equals(0xFF2196F3));
      expect(testCompanion.appearance.secondaryColor, equals(0xFF03DAC6));
      expect(testCompanion.appearance.style, equals(CompanionStyle.modern));
    });

    test('should support serialization to/from JSON', () {
      final json = testCompanion.toJson();
      final reconstructed = Companion.fromJson(json);

      expect(reconstructed.id, equals(testCompanion.id));
      expect(reconstructed.name, equals(testCompanion.name));
      expect(reconstructed.description, equals(testCompanion.description));
      expect(reconstructed.personality.extraversion, equals(testCompanion.personality.extraversion));
      expect(reconstructed.appearance.avatar, equals(testCompanion.appearance.avatar));
    });

    test('should support copyWith functionality', () {
      final updated = testCompanion.copyWith(
        name: 'Updated Companion',
        isFavorite: true,
      );

      expect(updated.name, equals('Updated Companion'));
      expect(updated.isFavorite, isTrue);
      expect(updated.id, equals(testCompanion.id)); // Should remain the same
      expect(updated.description, equals(testCompanion.description)); // Should remain the same
    });

    test('should validate personality trait ranges', () {
      expect(testCompanion.personality.extraversion, greaterThanOrEqualTo(0.0));
      expect(testCompanion.personality.extraversion, lessThanOrEqualTo(1.0));
      expect(testCompanion.personality.agreeableness, greaterThanOrEqualTo(0.0));
      expect(testCompanion.personality.agreeableness, lessThanOrEqualTo(1.0));
      expect(testCompanion.personality.conscientiousness, greaterThanOrEqualTo(0.0));
      expect(testCompanion.personality.conscientiousness, lessThanOrEqualTo(1.0));
      expect(testCompanion.personality.neuroticism, greaterThanOrEqualTo(0.0));
      expect(testCompanion.personality.neuroticism, lessThanOrEqualTo(1.0));
      expect(testCompanion.personality.openness, greaterThanOrEqualTo(0.0));
      expect(testCompanion.personality.openness, lessThanOrEqualTo(1.0));
    });

    test('should generate unique IDs for different companions', () {
      final companion1 = Companion.create(
        name: 'Companion 1',
        description: 'First companion',
        appearance: testCompanion.appearance,
        personality: testCompanion.personality,
      );

      final companion2 = Companion.create(
        name: 'Companion 2',
        description: 'Second companion',
        appearance: testCompanion.appearance,
        personality: testCompanion.personality,
      );

      expect(companion1.id, isNot(equals(companion2.id)));
    });

    test('should handle equality correctly', () {
      final identical = testCompanion.copyWith();
      final different = testCompanion.copyWith(name: 'Different Name');

      expect(testCompanion, equals(identical));
      expect(testCompanion, isNot(equals(different)));
    });
  });

  group('CompanionPersonality Tests', () {
    test('should calculate personality dominance correctly', () {
      const personality = CompanionPersonality(
        extraversion: 0.9,
        agreeableness: 0.3,
        conscientiousness: 0.5,
        neuroticism: 0.2,
        openness: 0.7,
        traits: [],
      );

      expect(personality.dominantTrait, equals('extraversion'));
    });

    test('should categorize personality types correctly', () {
      const extrovert = CompanionPersonality(
        extraversion: 0.8,
        agreeableness: 0.5,
        conscientiousness: 0.5,
        neuroticism: 0.3,
        openness: 0.5,
        traits: [],
      );

      const introvert = CompanionPersonality(
        extraversion: 0.2,
        agreeableness: 0.5,
        conscientiousness: 0.5,
        neuroticism: 0.3,
        openness: 0.5,
        traits: [],
      );

      expect(extrovert.isExtroverted, isTrue);
      expect(introvert.isExtroverted, isFalse);
    });
  });

  group('CompanionAppearance Tests', () {
    test('should validate color values', () {
      const appearance = CompanionAppearance(
        avatar: '🤖',
        primaryColor: 0xFF2196F3,
        secondaryColor: 0xFF03DAC6,
        style: CompanionStyle.modern,
      );

      expect(appearance.primaryColor, isA<int>());
      expect(appearance.secondaryColor, isA<int>());
      expect(appearance.primaryColor.toUnsigned(32), equals(0xFF2196F3));
      expect(appearance.secondaryColor.toUnsigned(32), equals(0xFF03DAC6));
    });

    test('should handle different companion styles', () {
      for (final style in CompanionStyle.values) {
        final appearance = CompanionAppearance(
          avatar: '🤖',
          primaryColor: 0xFF2196F3,
          secondaryColor: 0xFF03DAC6,
          style: style,
        );

        expect(appearance.style, equals(style));
      }
    });
  });
}