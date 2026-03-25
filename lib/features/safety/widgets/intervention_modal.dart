import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/safety/conversation_monitor.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/utils/animation_utils.dart';

class InterventionModal extends StatefulWidget {
  final InterventionType interventionType;
  final List<String> recommendations;
  final String? customMessage;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onGetHelp;
  final VoidCallback? onDismiss;
  final bool allowDismiss;

  const InterventionModal({
    required this.interventionType,
    required this.recommendations,
    this.customMessage,
    this.onAcknowledge,
    this.onGetHelp,
    this.onDismiss,
    this.allowDismiss = true,
    super.key,
  });

  @override
  State<InterventionModal> createState() => _InterventionModalState();
}

class _InterventionModalState extends State<InterventionModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    
    if (widget.interventionType == InterventionType.mentalHealthSupport) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: () async => widget.allowDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme),
                _buildContent(theme),
                _buildActions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final color = _getInterventionColor(widget.interventionType);
    final icon = _getInterventionIcon(widget.interventionType);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          if (widget.allowDismiss)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms),
          
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
              );
            },
          )
          .animate()
          .scale(
            duration: 600.ms,
            delay: 200.ms,
            curve: Curves.elasticOut,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _getInterventionTitle(widget.interventionType),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 400.ms)
          .slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.customMessage ?? _getInterventionMessage(widget.interventionType),
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 500.ms)
          .slideY(begin: 0.3),
          
          if (widget.recommendations.isNotEmpty) ...[
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendations',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.recommendations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final recommendation = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: (600 + index * 100).ms)
                      .slideX(begin: 0.3),
                    );
                  }),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 600.ms)
            .slideY(begin: 0.3),
          ],
          
          if (widget.interventionType == InterventionType.mentalHealthSupport) ...[
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Crisis Support',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you\'re in crisis, please reach out to professional help immediately:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CrisisResource(
                    name: 'National Suicide Prevention Lifeline',
                    number: '988',
                    description: '24/7 crisis support',
                  ),
                  const SizedBox(height: 8),
                  _CrisisResource(
                    name: 'Crisis Text Line',
                    number: 'Text HOME to 741741',
                    description: '24/7 text-based support',
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 700.ms)
            .slideY(begin: 0.3),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (widget.interventionType == InterventionType.mentalHealthSupport && widget.onGetHelp != null) ...[
            SizedBox(
              width: double.infinity,
              child: AnimatedButton(
                onPressed: widget.onGetHelp,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Get Professional Help'),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms)
            .slideY(begin: 0.3),
            
            const SizedBox(height: 12),
          ],
          
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onPressed: widget.onAcknowledge ?? () => Navigator.of(context).pop(),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Text('I Understand'),
            ),
          )
          .animate()
          .fadeIn(delay: 900.ms)
          .slideY(begin: 0.3),
        ],
      ),
    );
  }

  Color _getInterventionColor(InterventionType type) {
    switch (type) {
      case InterventionType.gentleRedirect:
        return Colors.blue;
      case InterventionType.boundaryReminder:
        return Colors.orange;
      case InterventionType.behaviorCorrection:
        return Colors.amber;
      case InterventionType.mentalHealthSupport:
        return Colors.red;
      case InterventionType.conversationPause:
        return Colors.purple;
    }
  }

  IconData _getInterventionIcon(InterventionType type) {
    switch (type) {
      case InterventionType.gentleRedirect:
        return Icons.navigation;
      case InterventionType.boundaryReminder:
        return Icons.security;
      case InterventionType.behaviorCorrection:
        return Icons.tune;
      case InterventionType.mentalHealthSupport:
        return Icons.favorite;
      case InterventionType.conversationPause:
        return Icons.pause_circle;
    }
  }

  String _getInterventionTitle(InterventionType type) {
    switch (type) {
      case InterventionType.gentleRedirect:
        return 'Let\'s Try Something Else';
      case InterventionType.boundaryReminder:
        return 'Boundary Reminder';
      case InterventionType.behaviorCorrection:
        return 'Conversation Guidelines';
      case InterventionType.mentalHealthSupport:
        return 'We\'re Here for You';
      case InterventionType.conversationPause:
        return 'Take a Moment';
    }
  }

  String _getInterventionMessage(InterventionType type) {
    switch (type) {
      case InterventionType.gentleRedirect:
        return 'I noticed our conversation might benefit from exploring a different direction. Let\'s find a topic that\'s more helpful and appropriate for both of us.';
      case InterventionType.boundaryReminder:
        return 'I want to gently remind you about maintaining healthy boundaries in our AI companion relationship. This helps ensure our interactions remain positive and beneficial.';
      case InterventionType.behaviorCorrection:
        return 'Let\'s keep our conversation positive, respectful, and appropriate. This creates a better experience for both of us.';
      case InterventionType.mentalHealthSupport:
        return 'I notice you might be going through a difficult time. Please know that while I care about your wellbeing, there are trained professionals who can provide the support you deserve.';
      case InterventionType.conversationPause:
        return 'It might be helpful to take a short break from our conversation. Sometimes stepping away and returning when you\'re ready can lead to more meaningful interactions.';
    }
  }
}

class _CrisisResource extends StatelessWidget {
  final String name;
  final String number;
  final String description;

  const _CrisisResource({
    required this.name,
    required this.number,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedButton(
            onPressed: () {
              // TODO: Implement call/text functionality
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show intervention modal
void showInterventionModal({
  required BuildContext context,
  required InterventionType interventionType,
  required List<String> recommendations,
  String? customMessage,
  VoidCallback? onAcknowledge,
  VoidCallback? onGetHelp,
  VoidCallback? onDismiss,
  bool allowDismiss = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: allowDismiss,
    builder: (context) => InterventionModal(
      interventionType: interventionType,
      recommendations: recommendations,
      customMessage: customMessage,
      onAcknowledge: onAcknowledge,
      onGetHelp: onGetHelp,
      onDismiss: onDismiss,
      allowDismiss: allowDismiss,
    ),
  );
}