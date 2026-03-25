import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

import 'companion_enums.dart';

part 'companion.g.dart';

@JsonSerializable()
class Companion extends Equatable {
  final String id;
  final String name;
  final CompanionAppearance appearance;
  final CompanionPersonality personality;
  final DateTime createdAt;
  final DateTime lastInteraction;
  final int totalInteractions;
  final Map<String, dynamic> preferences;

  const Companion({
    required this.id,
    required this.name,
    required this.appearance,
    required this.personality,
    required this.createdAt,
    required this.lastInteraction,
    this.totalInteractions = 0,
    this.preferences = const {},
  });

  factory Companion.fromJson(Map<String, dynamic> json) =>
      _$CompanionFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionToJson(this);

  Companion copyWith({
    String? id,
    String? name,
    CompanionAppearance? appearance,
    CompanionPersonality? personality,
    DateTime? createdAt,
    DateTime? lastInteraction,
    int? totalInteractions,
    Map<String, dynamic>? preferences,
  }) {
    return Companion(
      id: id ?? this.id,
      name: name ?? this.name,
      appearance: appearance ?? this.appearance,
      personality: personality ?? this.personality,
      createdAt: createdAt ?? this.createdAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      totalInteractions: totalInteractions ?? this.totalInteractions,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        appearance,
        personality,
        createdAt,
        lastInteraction,
        totalInteractions,
        preferences,
      ];
}

@JsonSerializable()
class CompanionAppearance extends Equatable {
  final String? avatarUrl;
  final Gender gender;
  final AgeRange ageRange;
  final String hairStyle;
  final String eyeColor;
  final String clothingStyle;
  final Map<String, dynamic> customFeatures;

  const CompanionAppearance({
    this.avatarUrl,
    required this.gender,
    required this.ageRange,
    required this.hairStyle,
    required this.eyeColor,
    required this.clothingStyle,
    this.customFeatures = const {},
  });

  factory CompanionAppearance.fromJson(Map<String, dynamic> json) =>
      _$CompanionAppearanceFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionAppearanceToJson(this);

  factory CompanionAppearance.defaults() {
    return const CompanionAppearance(
      gender: Gender.nonBinary,
      ageRange: AgeRange.adult,
      hairStyle: 'medium length',
      eyeColor: 'brown',
      clothingStyle: 'casual',
    );
  }

  String toImagePrompt() {
    final genderStr = gender == Gender.male
        ? 'male'
        : gender == Gender.female
            ? 'female'
            : 'person';
    
    final ageStr = ageRange == AgeRange.young
        ? 'young adult'
        : ageRange == AgeRange.adult
            ? 'adult'
            : 'mature adult';

    return 'A $genderStr $ageStr person with $hairStyle hair, '
           '$eyeColor eyes, wearing $clothingStyle clothing, '
           'friendly and approachable expression, portrait style';
  }

  @override
  List<Object?> get props => [
        avatarUrl,
        gender,
        ageRange,
        hairStyle,
        eyeColor,
        clothingStyle,
        customFeatures,
      ];
}

@JsonSerializable()
class CompanionPersonality extends Equatable {
  // Big Five personality traits (0.0 - 1.0)
  final double openness;
  final double conscientiousness;
  final double extraversion;
  final double agreeableness;
  final double neuroticism;

  // Communication style
  final double formalityLevel; // 0.0 (casual) - 1.0 (formal)
  final double humorLevel; // 0.0 (serious) - 1.0 (humorous)
  final double empathyLevel; // 0.0 (logical) - 1.0 (emotional)

  // Background and context
  final String background;
  final List<String> interests;
  final List<String> expertiseAreas;
  final String speakingStyle;

  const CompanionPersonality({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
    required this.formalityLevel,
    required this.humorLevel,
    required this.empathyLevel,
    required this.background,
    required this.interests,
    required this.expertiseAreas,
    required this.speakingStyle,
  });

  factory CompanionPersonality.fromJson(Map<String, dynamic> json) =>
      _$CompanionPersonalityFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionPersonalityToJson(this);

  factory CompanionPersonality.friendly() {
    return const CompanionPersonality(
      openness: 0.7,
      conscientiousness: 0.6,
      extraversion: 0.9,
      agreeableness: 0.9,
      neuroticism: 0.2,
      formalityLevel: 0.3,
      humorLevel: 0.8,
      empathyLevel: 0.9,
      background: 'A warm and welcoming companion who loves meeting new people and making friends.',
      interests: ['socializing', 'helping others', 'music', 'movies'],
      expertiseAreas: ['friendship', 'emotional support', 'social skills'],
      speakingStyle: 'Warm, encouraging, and genuinely interested in others',
    );
  }

  String generateSystemPrompt() {
    return '''
You are an AI companion with the following personality traits:

PERSONALITY TRAITS:
- Openness: ${(openness * 100).round()}% (${_getTraitDescription('openness', openness)})
- Conscientiousness: ${(conscientiousness * 100).round()}% (${_getTraitDescription('conscientiousness', conscientiousness)})
- Extraversion: ${(extraversion * 100).round()}% (${_getTraitDescription('extraversion', extraversion)})
- Agreeableness: ${(agreeableness * 100).round()}% (${_getTraitDescription('agreeableness', agreeableness)})
- Neuroticism: ${(neuroticism * 100).round()}% (${_getTraitDescription('neuroticism', neuroticism)})

COMMUNICATION STYLE:
- Formality: ${_getFormalityDescription(formalityLevel)}
- Humor: ${_getHumorDescription(humorLevel)}
- Empathy: ${_getEmpathyDescription(empathyLevel)}

BACKGROUND:
$background

INTERESTS: ${interests.join(', ')}
EXPERTISE: ${expertiseAreas.join(', ')}

SPEAKING STYLE: $speakingStyle

Remember these traits in all your responses. Be consistent with your personality and maintain this character throughout the conversation.
''';
  }

  String _getTraitDescription(String trait, double value) {
    switch (trait) {
      case 'openness':
        if (value < 0.3) return 'practical and traditional';
        if (value < 0.7) return 'balanced between traditional and creative';
        return 'creative and open to new experiences';
      case 'conscientiousness':
        if (value < 0.3) return 'flexible and spontaneous';
        if (value < 0.7) return 'moderately organized';
        return 'highly organized and disciplined';
      case 'extraversion':
        if (value < 0.3) return 'introverted and reserved';
        if (value < 0.7) return 'ambivert with social balance';
        return 'extraverted and outgoing';
      case 'agreeableness':
        if (value < 0.3) return 'competitive and challenging';
        if (value < 0.7) return 'balanced cooperation';
        return 'compassionate and cooperative';
      case 'neuroticism':
        if (value < 0.3) return 'emotionally stable and calm';
        if (value < 0.7) return 'moderate emotional responses';
        return 'emotionally sensitive';
      default:
        return 'balanced';
    }
  }

  String _getFormalityDescription(double level) {
    if (level < 0.3) return 'Very casual and relaxed';
    if (level < 0.7) return 'Balanced between casual and formal';
    return 'Formal and professional';
  }

  String _getHumorDescription(double level) {
    if (level < 0.3) return 'Serious and focused';
    if (level < 0.7) return 'Occasional light humor';
    return 'Frequent humor and playfulness';
  }

  String _getEmpathyDescription(double level) {
    if (level < 0.3) return 'Logical and analytical approach';
    if (level < 0.7) return 'Balanced logic and emotion';
    return 'Highly empathetic and emotional';
  }

  @override
  List<Object?> get props => [
        openness,
        conscientiousness,
        extraversion,
        agreeableness,
        neuroticism,
        formalityLevel,
        humorLevel,
        empathyLevel,
        background,
        interests,
        expertiseAreas,
        speakingStyle,
      ];
}

enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('non_binary')
  nonBinary,
}

enum AgeRange {
  @JsonValue('young')
  young, // 18-25
  @JsonValue('adult')
  adult, // 26-45
  @JsonValue('mature')
  mature, // 46+
}