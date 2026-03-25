import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/safety/conversation_monitor.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/utils/animation_utils.dart';

class SafetyFeedbackWidget extends StatefulWidget {
  final SafetyAssessment safetyAssessment;
  final VoidCallback? onReportIssue;
  final VoidCallback? onAdjustSettings;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const SafetyFeedbackWidget({
    required this.safetyAssessment,
    this.onReportIssue,
    this.onAdjustSettings,
    this.onDismiss,
    this.showDetails = false,
    super.key,
  });

  @override
  State<SafetyFeedbackWidget> createState() => _SafetyFeedbackWidgetState();
}

class _SafetyFeedbackWidgetState extends State<SafetyFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.safetyAssessment.riskCategory == RiskCategory.high ||
        widget.safetyAssessment.riskCategory == RiskCategory.medium) {
      _pulseController.repeat(reverse: true);
    }

    _isExpanded = widget.showDetails;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor(widget.safetyAssessment.riskCategory);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: riskColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: riskColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(theme, riskColor),
                if (_isExpanded) _buildDetails(theme, riskColor),
                _buildActions(theme),
              ],
            ),
          ),
        );
      },
    )
    .animate()
    .slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutQuart)
    .fadeIn(duration: 300.ms);
  }

  Widget _buildHeader(ThemeData theme, Color riskColor) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              riskColor.withOpacity(0.1),
              riskColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getRiskIcon(widget.safetyAssessment.riskCategory),
                color: riskColor,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRiskTitle(widget.safetyAssessment.riskCategory),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getRiskDescription(widget.safetyAssessment.riskCategory),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: riskColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(ThemeData theme, Color riskColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          
          // Safety scores
          _SafetyScoreRow(
            label: 'Overall Safety',
            score: widget.safetyAssessment.overallRiskScore,
            icon: Icons.shield,
            theme: theme,
          ),
          
          const SizedBox(height: 8),
          
          _SafetyScoreRow(
            label: 'Conversation Health',
            score: widget.safetyAssessment.conversationHealthScore,
            icon: Icons.favorite,
            theme: theme,
          ),
          
          if (widget.safetyAssessment.safetyRecommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            
            Text(
              'Safety Recommendations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: riskColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ...widget.safetyAssessment.safetyRecommendations.take(3).map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 16,
                      color: riskColor,
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
              );
            }),
          ],
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 200.ms)
    .slideY(begin: -0.3);
  }

  Widget _buildActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          if (widget.onReportIssue != null)
            Expanded(
              child: AnimatedButton(
                onPressed: widget.onReportIssue,
                backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                foregroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.report_problem, size: 16),
                    SizedBox(width: 4),
                    Text('Report'),
                  ],
                ),
              ),
            ),
          
          if (widget.onReportIssue != null && widget.onAdjustSettings != null)
            const SizedBox(width: 8),
          
          if (widget.onAdjustSettings != null)
            Expanded(
              child: AnimatedButton(
                onPressed: widget.onAdjustSettings,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 16),
                    SizedBox(width: 4),
                    Text('Settings'),
                  ],
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          
          AnimatedButton(
            onPressed: widget.onDismiss ?? () {},
            backgroundColor: theme.colorScheme.surfaceVariant,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return Colors.green;
      case RiskCategory.low:
        return Colors.blue;
      case RiskCategory.medium:
        return Colors.orange;
      case RiskCategory.high:
        return Colors.red;
    }
  }

  IconData _getRiskIcon(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return Icons.shield;
      case RiskCategory.low:
        return Icons.info;
      case RiskCategory.medium:
        return Icons.warning;
      case RiskCategory.high:
        return Icons.error;
    }
  }

  String _getRiskTitle(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return 'Conversation is Safe';
      case RiskCategory.low:
        return 'Minor Safety Notice';
      case RiskCategory.medium:
        return 'Safety Attention Needed';
      case RiskCategory.high:
        return 'High Risk Detected';
    }
  }

  String _getRiskDescription(RiskCategory category) {
    switch (category) {
      case RiskCategory.minimal:
        return 'Everything looks good with this conversation';
      case RiskCategory.low:
        return 'Some minor points to be aware of';
      case RiskCategory.medium:
        return 'Please review safety recommendations';
      case RiskCategory.high:
        return 'Immediate attention required for safety';
    }
  }
}

class _SafetyScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final ThemeData theme;

  const _SafetyScoreRow({
    required this.label,
    required this.score,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).round();
    final color = score >= 0.7 ? Colors.green : score >= 0.4 ? Colors.orange : Colors.red;
    
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        )
        .animate()
        .scaleX(duration: 600.ms, curve: Curves.easeOutQuart),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SafetyQuickActions extends StatelessWidget {
  final VoidCallback? onReportContent;
  final VoidCallback? onBlockUser;
  final VoidCallback? onAdjustSettings;
  final VoidCallback? onGetHelp;

  const SafetyQuickActions({
    this.onReportContent,
    this.onBlockUser,
    this.onAdjustSettings,
    this.onGetHelp,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Safety Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onReportContent != null)
                _ActionChip(
                  label: 'Report Content',
                  icon: Icons.report,
                  color: Colors.red,
                  onPressed: onReportContent!,
                ),
              
              if (onBlockUser != null)
                _ActionChip(
                  label: 'Block',
                  icon: Icons.block,
                  color: Colors.orange,
                  onPressed: onBlockUser!,
                ),
              
              if (onAdjustSettings != null)
                _ActionChip(
                  label: 'Safety Settings',
                  icon: Icons.tune,
                  color: Colors.blue,
                  onPressed: onAdjustSettings!,
                ),
              
              if (onGetHelp != null)
                _ActionChip(
                  label: 'Get Help',
                  icon: Icons.help,
                  color: Colors.green,
                  onPressed: onGetHelp!,
                ),
            ],
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.3);
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: color.withOpacity(0.1),
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyTip extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;
  final VoidCallback? onLearnMore;

  const SafetyTip({
    required this.title,
    required this.description,
    required this.icon,
    this.color,
    this.onLearnMore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tipColor = color ?? theme.colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tipColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tipColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tipColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onLearnMore != null) ...[
            const SizedBox(width: 8),
            AnimatedButton(
              onPressed: onLearnMore,
              backgroundColor: tipColor.withOpacity(0.2),
              foregroundColor: tipColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text('Learn More'),
            ),
          ],
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideX(begin: 0.3);
  }
}