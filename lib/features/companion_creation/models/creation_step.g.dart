// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creation_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreationStep _$CreationStepFromJson(Map<String, dynamic> json) => CreationStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      subtitle: json['subtitle'] as String?,
      type: $enumDecode(_$CreationStepTypeEnumMap, json['type']),
      isRequired: json['isRequired'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      validationErrors: (json['validationErrors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CreationStepToJson(CreationStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'subtitle': instance.subtitle,
      'type': _$CreationStepTypeEnumMap[instance.type]!,
      'isRequired': instance.isRequired,
      'isCompleted': instance.isCompleted,
      'data': instance.data,
      'validationErrors': instance.validationErrors,
    };

const _$CreationStepTypeEnumMap = {
  CreationStepType.basicInfo: 'basic_info',
  CreationStepType.appearance: 'appearance',
  CreationStepType.personality: 'personality',
  CreationStepType.background: 'background',
  CreationStepType.review: 'review',
};

CompanionCreationWorkflow _$CompanionCreationWorkflowFromJson(
        Map<String, dynamic> json) =>
    CompanionCreationWorkflow(
      id: json['id'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => CreationStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentStepIndex: (json['currentStepIndex'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$CompanionCreationWorkflowToJson(
        CompanionCreationWorkflow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'steps': instance.steps,
      'currentStepIndex': instance.currentStepIndex,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'isCompleted': instance.isCompleted,
    };
