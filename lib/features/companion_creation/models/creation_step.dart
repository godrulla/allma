import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'creation_step.g.dart';

/// Represents a step in the companion creation process
@JsonSerializable()
class CreationStep extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? subtitle;
  final CreationStepType type;
  final bool isRequired;
  final bool isCompleted;
  final Map<String, dynamic> data;
  final List<String> validationErrors;

  const CreationStep({
    required this.id,
    required this.title,
    required this.description,
    this.subtitle,
    required this.type,
    this.isRequired = true,
    this.isCompleted = false,
    this.data = const {},
    this.validationErrors = const [],
  });

  factory CreationStep.fromJson(Map<String, dynamic> json) =>
      _$CreationStepFromJson(json);

  Map<String, dynamic> toJson() => _$CreationStepToJson(this);

  CreationStep copyWith({
    String? id,
    String? title,
    String? description,
    String? subtitle,
    CreationStepType? type,
    bool? isRequired,
    bool? isCompleted,
    Map<String, dynamic>? data,
    List<String>? validationErrors,
  }) {
    return CreationStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      data: data ?? this.data,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        subtitle,
        type,
        isRequired,
        isCompleted,
        data,
        validationErrors,
      ];
}

/// Types of creation steps
enum CreationStepType {
  @JsonValue('basic_info')
  basicInfo,
  @JsonValue('appearance')
  appearance,
  @JsonValue('personality')
  personality,
  @JsonValue('background')
  background,
  @JsonValue('review')
  review,
}

/// Complete companion creation workflow data
@JsonSerializable()
class CompanionCreationWorkflow extends Equatable {
  final String id;
  final List<CreationStep> steps;
  final int currentStepIndex;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isCompleted;

  const CompanionCreationWorkflow({
    required this.id,
    required this.steps,
    this.currentStepIndex = 0,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
  });

  factory CompanionCreationWorkflow.fromJson(Map<String, dynamic> json) =>
      _$CompanionCreationWorkflowFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionCreationWorkflowToJson(this);

  /// Create default companion creation workflow
  factory CompanionCreationWorkflow.createDefault(String id) {
    return CompanionCreationWorkflow(
      id: id,
      createdAt: DateTime.now(),
      steps: [
        const CreationStep(
          id: 'basic_info',
          title: 'Basic Information',
          description: 'Tell us about your companion',
          subtitle: 'Name and basic details',
          type: CreationStepType.basicInfo,
        ),
        const CreationStep(
          id: 'appearance',
          title: 'Appearance',
          description: 'Design how your companion looks',
          subtitle: 'Visual characteristics and style',
          type: CreationStepType.appearance,
        ),
        const CreationStep(
          id: 'personality',
          title: 'Personality',
          description: 'Define their personality traits',
          subtitle: 'Traits, communication style, and behavior',
          type: CreationStepType.personality,
        ),
        const CreationStep(
          id: 'background',
          title: 'Background',
          description: 'Create their backstory and interests',
          subtitle: 'History, interests, and expertise',
          type: CreationStepType.background,
        ),
        const CreationStep(
          id: 'review',
          title: 'Review & Create',
          description: 'Review and finalize your companion',
          subtitle: 'Final review before creation',
          type: CreationStepType.review,
          isRequired: false,
        ),
      ],
    );
  }

  /// Get current step
  CreationStep get currentStep => steps[currentStepIndex];

  /// Check if can go to next step
  bool get canGoNext => 
      currentStepIndex < steps.length - 1 && 
      (!currentStep.isRequired || currentStep.isCompleted);

  /// Check if can go to previous step
  bool get canGoPrevious => currentStepIndex > 0;

  /// Get progress percentage
  double get progress => currentStepIndex / (steps.length - 1);

  /// Get completed steps count
  int get completedStepsCount => 
      steps.where((step) => step.isCompleted).length;

  /// Check if all required steps are completed
  bool get allRequiredStepsCompleted =>
      steps.where((step) => step.isRequired).every((step) => step.isCompleted);

  CompanionCreationWorkflow copyWith({
    String? id,
    List<CreationStep>? steps,
    int? currentStepIndex,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return CompanionCreationWorkflow(
      id: id ?? this.id,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Update a specific step
  CompanionCreationWorkflow updateStep(String stepId, CreationStep updatedStep) {
    final updatedSteps = steps.map((step) {
      return step.id == stepId ? updatedStep : step;
    }).toList();

    return copyWith(steps: updatedSteps);
  }

  /// Move to next step
  CompanionCreationWorkflow nextStep() {
    if (canGoNext) {
      return copyWith(currentStepIndex: currentStepIndex + 1);
    }
    return this;
  }

  /// Move to previous step
  CompanionCreationWorkflow previousStep() {
    if (canGoPrevious) {
      return copyWith(currentStepIndex: currentStepIndex - 1);
    }
    return this;
  }

  /// Go to specific step
  CompanionCreationWorkflow goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < steps.length) {
      return copyWith(currentStepIndex: stepIndex);
    }
    return this;
  }

  /// Mark workflow as completed
  CompanionCreationWorkflow complete() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        steps,
        currentStepIndex,
        createdAt,
        completedAt,
        isCompleted,
      ];
}