// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Companion _$CompanionFromJson(Map<String, dynamic> json) => Companion(
      id: json['id'] as String,
      name: json['name'] as String,
      appearance: CompanionAppearance.fromJson(
          json['appearance'] as Map<String, dynamic>),
      personality: CompanionPersonality.fromJson(
          json['personality'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastInteraction: DateTime.parse(json['lastInteraction'] as String),
      totalInteractions: (json['totalInteractions'] as num?)?.toInt() ?? 0,
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CompanionToJson(Companion instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'appearance': instance.appearance,
      'personality': instance.personality,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastInteraction': instance.lastInteraction.toIso8601String(),
      'totalInteractions': instance.totalInteractions,
      'preferences': instance.preferences,
    };

CompanionAppearance _$CompanionAppearanceFromJson(Map<String, dynamic> json) =>
    CompanionAppearance(
      avatarUrl: json['avatarUrl'] as String?,
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      ageRange: $enumDecode(_$AgeRangeEnumMap, json['ageRange']),
      hairStyle: json['hairStyle'] as String,
      eyeColor: json['eyeColor'] as String,
      clothingStyle: json['clothingStyle'] as String,
      customFeatures:
          json['customFeatures'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CompanionAppearanceToJson(
        CompanionAppearance instance) =>
    <String, dynamic>{
      'avatarUrl': instance.avatarUrl,
      'gender': _$GenderEnumMap[instance.gender]!,
      'ageRange': _$AgeRangeEnumMap[instance.ageRange]!,
      'hairStyle': instance.hairStyle,
      'eyeColor': instance.eyeColor,
      'clothingStyle': instance.clothingStyle,
      'customFeatures': instance.customFeatures,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.nonBinary: 'non_binary',
};

const _$AgeRangeEnumMap = {
  AgeRange.young: 'young',
  AgeRange.adult: 'adult',
  AgeRange.mature: 'mature',
};

CompanionPersonality _$CompanionPersonalityFromJson(
        Map<String, dynamic> json) =>
    CompanionPersonality(
      openness: (json['openness'] as num).toDouble(),
      conscientiousness: (json['conscientiousness'] as num).toDouble(),
      extraversion: (json['extraversion'] as num).toDouble(),
      agreeableness: (json['agreeableness'] as num).toDouble(),
      neuroticism: (json['neuroticism'] as num).toDouble(),
      formalityLevel: (json['formalityLevel'] as num).toDouble(),
      humorLevel: (json['humorLevel'] as num).toDouble(),
      empathyLevel: (json['empathyLevel'] as num).toDouble(),
      background: json['background'] as String,
      interests:
          (json['interests'] as List<dynamic>).map((e) => e as String).toList(),
      expertiseAreas: (json['expertiseAreas'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      speakingStyle: json['speakingStyle'] as String,
    );

Map<String, dynamic> _$CompanionPersonalityToJson(
        CompanionPersonality instance) =>
    <String, dynamic>{
      'openness': instance.openness,
      'conscientiousness': instance.conscientiousness,
      'extraversion': instance.extraversion,
      'agreeableness': instance.agreeableness,
      'neuroticism': instance.neuroticism,
      'formalityLevel': instance.formalityLevel,
      'humorLevel': instance.humorLevel,
      'empathyLevel': instance.empathyLevel,
      'background': instance.background,
      'interests': instance.interests,
      'expertiseAreas': instance.expertiseAreas,
      'speakingStyle': instance.speakingStyle,
    };
