import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/safety/conversation_monitor.dart';
import '../../../shared/utils/constants.dart';

/// Visual safety indicator for conversations
class SafetyIndicator extends StatelessWidget {
  final double safetyScore;
  final RiskCategory riskCategory;
  final bool showDetails;
  final VoidCallback? onTap;

  const SafetyIndicator({
    required this.safetyScore,
    required this.riskCategory,
    this.showDetails = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getSafetyColor(riskCategory).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSafetyColor(riskCategory).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSafetyIcon(riskCategory),
              size: 14,
              color: _getSafetyColor(riskCategory),
            ),
            if (showDetails) ...[
              const SizedBox(width: 4),
              Text(
                _getSafetyLabel(riskCategory),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getSafetyColor(riskCategory),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .scale(
      begin: const Offset(0.8, 0.8),
      duration: 300.ms,
      curve: Curves.elasticOut,
    );
  }

  Color _getSafetyColor(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return Colors.green;
      case RiskCategory.low:
        return Colors.lightGreen;
      case RiskCategory.medium:
        return Colors.orange;
      case RiskCategory.high:
        return Colors.red;
    }
  }

  IconData _getSafetyIcon(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return Icons.shield;
      case RiskCategory.low:
        return Icons.info_outline;
      case RiskCategory.medium:
        return Icons.warning_amber;
      case RiskCategory.high:
        return Icons.error_outline;
    }
  }

  String _getSafetyLabel(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return 'Safe';
      case RiskCategory.low:
        return 'Monitored';
      case RiskCategory.medium:
        return 'Caution';
      case RiskCategory.high:
        return 'High Risk';
    }
  }
}

/// Detailed safety information panel
class SafetyInfoPanel extends StatelessWidget {
  final SafetyAssessment safetyAssessment;
  final VoidCallback? onClose;

  const SafetyInfoPanel({
    required this.safetyAssessment,
    this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Conversation Safety',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Safety scores
          _buildScoreCard(
            'Overall Safety',
            safetyAssessment.overallRiskScore,
            Icons.shield,
            theme,
          ),
          
          const SizedBox(height: 8),
          
          _buildScoreCard(
            'Conversation Health',
            safetyAssessment.conversationHealthScore,
            Icons.favorite,
            theme,
          ),
          
          // Recommendations
          if (safetyAssessment.safetyRecommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Safety Recommendations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...safetyAssessment.safetyRecommendations.map((recommendation) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Risk category
          const SizedBox(height: 16),
          SafetyIndicator(
            safetyScore: safetyAssessment.overallRiskScore,
            riskCategory: safetyAssessment.riskCategory,
            showDetails: true,
          ),
        ],
      ),
    )
    .animate()
    .slideY(
      begin: 0.3,
      duration: 400.ms,
      curve: Curves.easeOutQuart,
    )
    .fadeIn(duration: 300.ms);
  }

  Widget _buildScoreCard(String label, double score, IconData icon, ThemeData theme) {
    final percentage = (score * 100).round();
    final color = score >= 0.7 ? Colors.green : score >= 0.4 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: score,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated safety intervention dialog
class SafetyInterventionDialog extends StatelessWidget {
  final InterventionType interventionType;
  final List<String> recommendations;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onGetHelp;

  const SafetyInterventionDialog({
    required this.interventionType,
    required this.recommendations,
    this.onAcknowledge,
    this.onGetHelp,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getInterventionColor(interventionType).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getInterventionIcon(interventionType),
                size: 32,
                color: _getInterventionColor(interventionType),
              ),
            )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              _getInterventionTitle(interventionType),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(delay: 200.ms)
            .slideY(begin: 0.3),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              _getInterventionMessage(interventionType),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(delay: 300.ms)
            .slideY(begin: 0.3),
            
            // Recommendations
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendations:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.map((recommendation) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.arrow_right,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                recommendation,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                if (interventionType == InterventionType.mentalHealthSupport && onGetHelp != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onGetHelp,
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Get Help'),
                    ),
                  ),
                if (interventionType == InterventionType.mentalHealthSupport && onGetHelp != null)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAcknowledge ?? () => Navigator.of(context).pop(),
                    child: const Text('I Understand'),
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(delay: 500.ms)
            .slideY(begin: 0.3),
          ],
        ),
      ),
    )
    .animate()
    .scale(
      begin: const Offset(0.7, 0.7),
      duration: 400.ms,
      curve: Curves.easeOutQuart,
    )
    .fadeIn(duration: 300.ms);
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
        return 'Let\'s explore a different topic that might be more helpful or appropriate for our conversation.';
      case InterventionType.boundaryReminder:
        return 'I want to remind you about healthy boundaries in our AI companion relationship.';
      case InterventionType.behaviorCorrection:
        return 'Let\'s keep our conversation positive, respectful, and appropriate.';
      case InterventionType.mentalHealthSupport:
        return 'I notice you might be going through a difficult time. Please know that there are people who can help.';
      case InterventionType.conversationPause:
        return 'It might be helpful to take a short break from our conversation and return when you\'re ready.';
    }
  }
}

/// Floating safety status widget
class FloatingSafetyStatus extends StatelessWidget {
  final double safetyScore;
  final bool isVisible;
  final VoidCallback? onTap;

  const FloatingSafetyStatus({
    required this.safetyScore,
    required this.isVisible,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final color = safetyScore >= 0.7 ? Colors.green : safetyScore >= 0.4 ? Colors.orange : Colors.red;
    
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.3, 1.3),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.3, 1.3),
                end: const Offset(1.0, 1.0),
                duration: 1000.ms,
              ),
              const SizedBox(width: 6),
              Text(
                'Safe',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .slideX(begin: 1.0, duration: 300.ms, curve: Curves.easeOut)
    .fadeIn(duration: 200.ms);
  }
}