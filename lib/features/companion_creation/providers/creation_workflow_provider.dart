import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/creation_step.dart';
import '../../../core/companions/models/companion.dart';
import '../../../core/companions/services/companion_service.dart';

/// State notifier for managing companion creation workflow
class CreationWorkflowNotifier extends StateNotifier<CompanionCreationWorkflow> {
  final CompanionService? _companionService;
  final Uuid _uuid = const Uuid();

  CreationWorkflowNotifier(this._companionService)
      : super(CompanionCreationWorkflow.createDefault(''));

  /// Constructor for loading state
  CreationWorkflowNotifier.loading()
      : _companionService = null,
        super(CompanionCreationWorkflow.createDefault(''));

  /// Constructor for error state
  CreationWorkflowNotifier.error(Object error)
      : _companionService = null,
        super(CompanionCreationWorkflow.createDefault(''));

  /// Initialize new workflow
  void initializeWorkflow() {
    state = CompanionCreationWorkflow.createDefault(_uuid.v4());
  }

  /// Update basic information step
  void updateBasicInfo({
    required String name,
    String? description,
  }) {
    final currentStep = state.currentStep;
    final updatedData = Map<String, dynamic>.from(currentStep.data);
    updatedData['name'] = name;
    if (description != null) updatedData['description'] = description;

    final validationErrors = _validateBasicInfo(updatedData);
    final isCompleted = validationErrors.isEmpty && name.isNotEmpty;

    final updatedStep = currentStep.copyWith(
      data: updatedData,
      validationErrors: validationErrors,
      isCompleted: isCompleted,
    );

    state = state.updateStep(currentStep.id, updatedStep);
  }

  /// Update appearance step
  void updateAppearance({
    Gender? gender,
    AgeRange? ageRange,
    String? hairStyle,
    String? eyeColor,
    String? clothingStyle,
    String? avatarUrl,
  }) {
    final currentStep = state.currentStep;
    final updatedData = Map<String, dynamic>.from(currentStep.data);
    
    if (gender != null) updatedData['gender'] = gender.name;
    if (ageRange != null) updatedData['ageRange'] = ageRange.name;
    if (hairStyle != null) updatedData['hairStyle'] = hairStyle;
    if (eyeColor != null) updatedData['eyeColor'] = eyeColor;
    if (clothingStyle != null) updatedData['clothingStyle'] = clothingStyle;
    if (avatarUrl != null) updatedData['avatarUrl'] = avatarUrl;

    final validationErrors = _validateAppearance(updatedData);
    final isCompleted = validationErrors.isEmpty;

    final updatedStep = currentStep.copyWith(
      data: updatedData,
      validationErrors: validationErrors,
      isCompleted: isCompleted,
    );

    state = state.updateStep(currentStep.id, updatedStep);
  }

  /// Update personality step
  void updatePersonality({
    double? openness,
    double? conscientiousness,
    double? extraversion,
    double? agreeableness,
    double? neuroticism,
    double? formalityLevel,
    double? humorLevel,
    double? empathyLevel,
    String? speakingStyle,
  }) {
    final currentStep = state.currentStep;
    final updatedData = Map<String, dynamic>.from(currentStep.data);
    
    if (openness != null) updatedData['openness'] = openness;
    if (conscientiousness != null) updatedData['conscientiousness'] = conscientiousness;
    if (extraversion != null) updatedData['extraversion'] = extraversion;
    if (agreeableness != null) updatedData['agreeableness'] = agreeableness;
    if (neuroticism != null) updatedData['neuroticism'] = neuroticism;
    if (formalityLevel != null) updatedData['formalityLevel'] = formalityLevel;
    if (humorLevel != null) updatedData['humorLevel'] = humorLevel;
    if (empathyLevel != null) updatedData['empathyLevel'] = empathyLevel;
    if (speakingStyle != null) updatedData['speakingStyle'] = speakingStyle;

    final validationErrors = _validatePersonality(updatedData);
    final isCompleted = validationErrors.isEmpty;

    final updatedStep = currentStep.copyWith(
      data: updatedData,
      validationErrors: validationErrors,
      isCompleted: isCompleted,
    );

    state = state.updateStep(currentStep.id, updatedStep);
  }

  /// Update background step
  void updateBackground({
    String? background,
    List<String>? interests,
    List<String>? expertiseAreas,
  }) {
    final currentStep = state.currentStep;
    final updatedData = Map<String, dynamic>.from(currentStep.data);
    
    if (background != null) updatedData['background'] = background;
    if (interests != null) updatedData['interests'] = interests;
    if (expertiseAreas != null) updatedData['expertiseAreas'] = expertiseAreas;

    final validationErrors = _validateBackground(updatedData);
    final isCompleted = validationErrors.isEmpty;

    final updatedStep = currentStep.copyWith(
      data: updatedData,
      validationErrors: validationErrors,
      isCompleted: isCompleted,
    );

    state = state.updateStep(currentStep.id, updatedStep);
  }

  /// Apply personality preset
  void applyPersonalityPreset(PersonalityPreset preset) {
    final personality = PersonalityPresets.getPreset(preset);
    
    updatePersonality(
      openness: personality.openness,
      conscientiousness: personality.conscientiousness,
      extraversion: personality.extraversion,
      agreeableness: personality.agreeableness,
      neuroticism: personality.neuroticism,
      formalityLevel: personality.formalityLevel,
      humorLevel: personality.humorLevel,
      empathyLevel: personality.empathyLevel,
      speakingStyle: personality.speakingStyle,
    );

    // Also update background if it's empty
    final backgroundStep = state.steps.firstWhere(
      (step) => step.type == CreationStepType.background,
    );
    
    if (backgroundStep.data['background'] == null || 
        (backgroundStep.data['background'] as String).isEmpty) {
      updateBackground(
        background: personality.background,
        interests: personality.interests,
        expertiseAreas: personality.expertiseAreas,
      );
    }
  }

  /// Navigate to next step
  void nextStep() {
    state = state.nextStep();
  }

  /// Navigate to previous step
  void previousStep() {
    state = state.previousStep();
  }

  /// Go to specific step
  void goToStep(int stepIndex) {
    state = state.goToStep(stepIndex);
  }

  /// Create companion from workflow data
  Future<Companion?> createCompanion() async {
    if (!state.allRequiredStepsCompleted) {
      return null;
    }

    // If companion service is not available, return null
    if (_companionService == null) {
      return null;
    }

    try {
      // Extract data from all steps
      final basicInfoData = _getStepData(CreationStepType.basicInfo);
      final appearanceData = _getStepData(CreationStepType.appearance);
      final personalityData = _getStepData(CreationStepType.personality);
      final backgroundData = _getStepData(CreationStepType.background);

      // Create appearance
      final appearance = CompanionAppearance(
        avatarUrl: appearanceData['avatarUrl'] as String?,
        gender: Gender.values.firstWhere(
          (g) => g.name == (appearanceData['gender'] ?? 'nonBinary'),
        ),
        ageRange: AgeRange.values.firstWhere(
          (a) => a.name == (appearanceData['ageRange'] ?? 'adult'),
        ),
        hairStyle: appearanceData['hairStyle'] as String? ?? 'medium length',
        eyeColor: appearanceData['eyeColor'] as String? ?? 'brown',
        clothingStyle: appearanceData['clothingStyle'] as String? ?? 'casual',
      );

      // Create personality
      final personality = CompanionPersonality(
        openness: personalityData['openness'] as double? ?? 0.5,
        conscientiousness: personalityData['conscientiousness'] as double? ?? 0.5,
        extraversion: personalityData['extraversion'] as double? ?? 0.5,
        agreeableness: personalityData['agreeableness'] as double? ?? 0.5,
        neuroticism: personalityData['neuroticism'] as double? ?? 0.5,
        formalityLevel: personalityData['formalityLevel'] as double? ?? 0.5,
        humorLevel: personalityData['humorLevel'] as double? ?? 0.5,
        empathyLevel: personalityData['empathyLevel'] as double? ?? 0.5,
        background: backgroundData['background'] as String? ?? '',
        interests: (backgroundData['interests'] as List<dynamic>?)?.cast<String>() ?? [],
        expertiseAreas: (backgroundData['expertiseAreas'] as List<dynamic>?)?.cast<String>() ?? [],
        speakingStyle: personalityData['speakingStyle'] as String? ?? 'Friendly and approachable',
      );

      // Create companion
      final companion = await _companionService!.createCompanion(
        name: basicInfoData['name'] as String,
        appearance: appearance,
        personality: personality,
      );

      // Mark workflow as completed
      state = state.complete();

      return companion;
    } catch (e) {
      // Handle error - could add error state to workflow
      return null;
    }
  }

  /// Get data from specific step type
  Map<String, dynamic> _getStepData(CreationStepType stepType) {
    final step = state.steps.firstWhere((step) => step.type == stepType);
    return step.data;
  }

  /// Validation methods
  List<String> _validateBasicInfo(Map<String, dynamic> data) {
    final errors = <String>[];
    
    final name = data['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      errors.add('Name is required');
    } else if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters');
    } else if (name.trim().length > 30) {
      errors.add('Name must be less than 30 characters');
    }

    return errors;
  }

  List<String> _validateAppearance(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // All appearance fields are optional with defaults
    // Could add specific validation rules here if needed
    
    return errors;
  }

  List<String> _validatePersonality(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Validate trait values are between 0 and 1
    final traits = [
      'openness', 'conscientiousness', 'extraversion', 
      'agreeableness', 'neuroticism', 'formalityLevel', 
      'humorLevel', 'empathyLevel'
    ];
    
    for (final trait in traits) {
      final value = data[trait] as double?;
      if (value != null && (value < 0.0 || value > 1.0)) {
        errors.add('$trait must be between 0 and 1');
      }
    }

    return errors;
  }

  List<String> _validateBackground(Map<String, dynamic> data) {
    final errors = <String>[];
    
    final background = data['background'] as String?;
    if (background != null && background.length > 500) {
      errors.add('Background must be less than 500 characters');
    }

    return errors;
  }
}

/// Personality presets for quick setup
enum PersonalityPreset {
  friendly,
  intellectual,
  creative,
  supportive,
  adventurous,
  professional,
}

class PersonalityPresets {
  static CompanionPersonality getPreset(PersonalityPreset preset) {
    switch (preset) {
      case PersonalityPreset.friendly:
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
      
      case PersonalityPreset.intellectual:
        return const CompanionPersonality(
          openness: 0.9,
          conscientiousness: 0.8,
          extraversion: 0.4,
          agreeableness: 0.6,
          neuroticism: 0.3,
          formalityLevel: 0.7,
          humorLevel: 0.4,
          empathyLevel: 0.6,
          background: 'A thoughtful and knowledgeable companion who enjoys deep discussions and learning.',
          interests: ['science', 'philosophy', 'books', 'research'],
          expertiseAreas: ['analysis', 'problem-solving', 'education'],
          speakingStyle: 'Thoughtful, precise, and intellectually curious',
        );
      
      case PersonalityPreset.creative:
        return const CompanionPersonality(
          openness: 0.95,
          conscientiousness: 0.4,
          extraversion: 0.7,
          agreeableness: 0.7,
          neuroticism: 0.5,
          formalityLevel: 0.2,
          humorLevel: 0.8,
          empathyLevel: 0.8,
          background: 'An imaginative and artistic companion who sees beauty and possibility everywhere.',
          interests: ['art', 'music', 'writing', 'design', 'innovation'],
          expertiseAreas: ['creativity', 'inspiration', 'artistic expression'],
          speakingStyle: 'Expressive, imaginative, and full of creative energy',
        );
      
      case PersonalityPreset.supportive:
        return const CompanionPersonality(
          openness: 0.6,
          conscientiousness: 0.8,
          extraversion: 0.5,
          agreeableness: 0.95,
          neuroticism: 0.2,
          formalityLevel: 0.4,
          humorLevel: 0.6,
          empathyLevel: 0.95,
          background: 'A caring and understanding companion who provides comfort and guidance.',
          interests: ['helping others', 'mental health', 'wellness', 'listening'],
          expertiseAreas: ['emotional support', 'empathy', 'guidance'],
          speakingStyle: 'Gentle, understanding, and deeply caring',
        );
      
      case PersonalityPreset.adventurous:
        return const CompanionPersonality(
          openness: 0.9,
          conscientiousness: 0.5,
          extraversion: 0.8,
          agreeableness: 0.7,
          neuroticism: 0.3,
          formalityLevel: 0.2,
          humorLevel: 0.9,
          empathyLevel: 0.7,
          background: 'An energetic and spontaneous companion who loves exploring and trying new things.',
          interests: ['travel', 'sports', 'adventure', 'exploring', 'challenges'],
          expertiseAreas: ['motivation', 'exploration', 'outdoor activities'],
          speakingStyle: 'Enthusiastic, energetic, and always ready for the next adventure',
        );
      
      case PersonalityPreset.professional:
        return const CompanionPersonality(
          openness: 0.6,
          conscientiousness: 0.9,
          extraversion: 0.6,
          agreeableness: 0.7,
          neuroticism: 0.2,
          formalityLevel: 0.8,
          humorLevel: 0.4,
          empathyLevel: 0.6,
          background: 'A reliable and competent companion focused on productivity and achievement.',
          interests: ['business', 'efficiency', 'planning', 'success', 'leadership'],
          expertiseAreas: ['organization', 'strategy', 'professional development'],
          speakingStyle: 'Clear, professional, and results-oriented',
        );
    }
  }
}

/// Provider for creation workflow
final creationWorkflowProvider = StateNotifierProvider<CreationWorkflowNotifier, CompanionCreationWorkflow>((ref) {
  final companionServiceAsync = ref.watch(companionServiceProvider);
  
  return companionServiceAsync.when(
    data: (companionService) => CreationWorkflowNotifier(companionService),
    loading: () => CreationWorkflowNotifier.loading(),
    error: (error, stack) => CreationWorkflowNotifier.error(error),
  );
});