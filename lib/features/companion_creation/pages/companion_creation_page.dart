import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../providers/creation_workflow_provider.dart';
import '../widgets/creation_step_indicator.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/appearance_step.dart';
import '../widgets/personality_step.dart';
import '../widgets/background_step.dart';
import '../widgets/review_step.dart';
import '../models/creation_step.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/buttons/secondary_button.dart';

class CompanionCreationPage extends ConsumerStatefulWidget {
  const CompanionCreationPage({super.key});

  @override
  ConsumerState<CompanionCreationPage> createState() => _CompanionCreationPageState();
}

class _CompanionCreationPageState extends ConsumerState<CompanionCreationPage> {
  final PageController _pageController = PageController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Initialize workflow when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creationWorkflowProvider.notifier).initializeWorkflow();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(creationWorkflowProvider);
    final workflowNotifier = ref.read(creationWorkflowProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Companion'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Progress indicator
          CreationStepIndicator(
            currentStep: workflow.currentStepIndex,
            totalSteps: workflow.steps.length,
            stepLabels: workflow.steps.map((step) => step.title).toList(),
          ),
          
          // Step content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: workflow.steps.length,
              onPageChanged: (index) {
                workflowNotifier.goToStep(index);
              },
              itemBuilder: (context, index) {
                final step = workflow.steps[index];
                return _buildStepContent(step);
              },
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(workflow, workflowNotifier),
        ],
      ),
    );
  }

  Widget _buildStepContent(CreationStep step) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title and description
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
          .animate()
          .fadeIn(duration: AppConstants.animationDuration)
          .slideX(begin: -0.2, duration: AppConstants.animationDuration),
          
          const SizedBox(height: 8),
          
          if (step.subtitle != null)
            Text(
              step.subtitle!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            )
            .animate()
            .fadeIn(duration: AppConstants.animationDuration, delay: 100.ms)
            .slideX(begin: -0.2, duration: AppConstants.animationDuration),
          
          const SizedBox(height: 24),
          
          // Step-specific content
          Expanded(
            child: _buildStepWidget(step.type),
          ),
          
          // Validation errors
          if (step.validationErrors.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  ...step.validationErrors.map(
                    (error) => Text(
                      '• $error',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppConstants.animationDuration)
            .shake(duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildStepWidget(CreationStepType stepType) {
    switch (stepType) {
      case CreationStepType.basicInfo:
        return BasicInfoStep(
          onChanged: (name, description) {
            // Handle basic info changes
          },
        );
      case CreationStepType.appearance:
        return AppearanceStep(
          onChanged: (avatar) {
            // Handle appearance changes
          },
        );
      case CreationStepType.personality:
        return PersonalityStep(
          onChanged: (traits) {
            // Handle personality changes
          },
        );
      case CreationStepType.background:
        return BackgroundStep(
          onChanged: (background) {
            // Handle background changes
          },
        );
      case CreationStepType.review:
        return ReviewStep(
          name: 'Sample Companion',
          description: 'Sample Description',
          avatar: '👩',
          personalityTraits: {
            'openness': 0.5,
            'conscientiousness': 0.5,
            'extraversion': 0.5,
            'agreeableness': 0.5,
            'neuroticism': 0.3,
          },
          background: 'Sample background',
          onCreateCompanion: () {
            // Handle companion creation
          },
        );
    }
  }

  Widget _buildNavigationButtons(
    CompanionCreationWorkflow workflow,
    CreationWorkflowNotifier workflowNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (workflow.canGoPrevious)
            Expanded(
              child: SecondaryButton(
                onPressed: () {
                  workflowNotifier.previousStep();
                  _pageController.previousPage(
                    duration: AppConstants.animationDuration,
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Previous'),
              ),
            ),
          
          if (workflow.canGoPrevious) const SizedBox(width: 16),
          
          // Next/Create button
          Expanded(
            child: PrimaryButton(
              onPressed: _isCreating ? null : () => _handleNextOrCreate(workflow, workflowNotifier),
              isLoading: _isCreating,
              child: Text(_getNextButtonText(workflow)),
            ),
          ),
        ],
      ),
    )
    .animate()
    .slideY(begin: 1, duration: AppConstants.animationDuration)
    .fadeIn(duration: AppConstants.animationDuration);
  }

  String _getNextButtonText(CompanionCreationWorkflow workflow) {
    if (workflow.currentStepIndex == workflow.steps.length - 1) {
      return 'Create Companion';
    }
    return 'Next';
  }

  Future<void> _handleNextOrCreate(
    CompanionCreationWorkflow workflow,
    CreationWorkflowNotifier workflowNotifier,
  ) async {
    final currentStep = workflow.currentStep;
    
    // If on review step, create companion
    if (currentStep.type == CreationStepType.review) {
      await _createCompanion(workflowNotifier);
      return;
    }
    
    // If current step is completed or not required, go to next
    if (!currentStep.isRequired || currentStep.isCompleted) {
      workflowNotifier.nextStep();
      _pageController.nextPage(
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      // Show validation errors by triggering state update
      // The step widgets should handle showing errors when validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete the required fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _createCompanion(CreationWorkflowNotifier workflowNotifier) async {
    setState(() {
      _isCreating = true;
    });

    try {
      final companion = await workflowNotifier.createCompanion();
      
      if (companion != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${companion.name} has been created!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Navigate to companion chat
        context.go('/chat/${companion.id}');
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create companion. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Creation?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.pop();
    }
  }
}