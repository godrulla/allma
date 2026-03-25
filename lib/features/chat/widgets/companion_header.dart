import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/companions/models/companion.dart';
import '../../../shared/utils/constants.dart';

class CompanionHeader extends StatelessWidget {
  final Companion companion;
  final bool showOnlineStatus;

  const CompanionHeader({
    required this.companion,
    this.showOnlineStatus = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Avatar
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: companion.appearance.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        companion.appearance.avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(theme),
                      ),
                    )
                  : _buildDefaultAvatar(theme),
            ),
            
            // Online indicator
            if (showOnlineStatus)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  duration: 2000.ms,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                ),
              ),
          ],
        ),
        
        const SizedBox(width: 12),
        
        // Companion info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companion.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              
              if (showOnlineStatus)
                Text(
                  'Online',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Text(
                  _getPersonalityDescription(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: AppConstants.animationDuration)
    .slideX(begin: -0.2, duration: AppConstants.animationDuration);
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy,
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
    );
  }

  String _getPersonalityDescription() {
    // Generate a brief personality description
    final personality = companion.personality;
    
    if (personality.extraversion > 0.7) {
      return 'Outgoing and energetic';
    } else if (personality.agreeableness > 0.8) {
      return 'Kind and supportive';
    } else if (personality.openness > 0.8) {
      return 'Creative and curious';
    } else if (personality.conscientiousness > 0.8) {
      return 'Organized and reliable';
    } else {
      return 'Thoughtful companion';
    }
  }
}

/// Extended companion header with more details
class DetailedCompanionHeader extends StatelessWidget {
  final Companion companion;

  const DetailedCompanionHeader({
    required this.companion,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Main header
          CompanionHeader(
            companion: companion,
            showOnlineStatus: true,
          ),
          
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                context,
                'Conversations',
                companion.totalInteractions.toString(),
                Icons.chat_bubble_outline,
              ),
              _buildStat(
                context,
                'Created',
                _formatDate(companion.createdAt),
                Icons.calendar_today,
              ),
              _buildStat(
                context,
                'Interests',
                companion.personality.interests.length.toString(),
                Icons.favorite_outline,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Personality traits
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildPersonalityChips(context),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .slideY(begin: -0.3, duration: 500.ms, curve: Curves.easeOutQuart);
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPersonalityChips(BuildContext context) {
    final theme = Theme.of(context);
    final personality = companion.personality;
    final chips = <Widget>[];
    
    // Add dominant traits
    if (personality.extraversion > 0.7) {
      chips.add(_buildChip(context, 'Outgoing', Colors.orange));
    }
    if (personality.agreeableness > 0.8) {
      chips.add(_buildChip(context, 'Kind', Colors.pink));
    }
    if (personality.openness > 0.8) {
      chips.add(_buildChip(context, 'Creative', Colors.purple));
    }
    if (personality.conscientiousness > 0.8) {
      chips.add(_buildChip(context, 'Organized', Colors.blue));
    }
    if (personality.humorLevel > 0.7) {
      chips.add(_buildChip(context, 'Funny', Colors.green));
    }
    
    // Add interests
    for (final interest in companion.personality.interests.take(3)) {
      chips.add(_buildChip(context, interest, theme.colorScheme.primary));
    }
    
    return chips;
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }
}