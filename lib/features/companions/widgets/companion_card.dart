import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/companions/models/companion.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/utils/animation_utils.dart';

class CompanionCard extends StatefulWidget {
  final Companion companion;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showFavoriteButton;
  final bool compact;

  const CompanionCard({
    required this.companion,
    this.isSelected = false,
    this.onTap,
    this.onFavorite,
    this.showFavoriteButton = true,
    this.compact = false,
    super.key,
  });

  @override
  State<CompanionCard> createState() => _CompanionCardState();
}

class _CompanionCardState extends State<CompanionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = widget.compact;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: isCompact ? 120 : 200,
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.8),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: widget.isSelected ? 12 : 8,
                offset: const Offset(0, 4),
                spreadRadius: widget.isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: isCompact ? _buildCompactLayout(theme) : _buildFullLayout(theme),
              ),
              
              // Selection indicator
              if (widget.isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                .animate()
                .scale(duration: 300.ms, curve: Curves.elasticOut),
              
              // Favorite button
              if (widget.showFavoriteButton && !isCompact)
                Positioned(
                  top: 8,
                  right: widget.isSelected ? 40 : 8,
                  child: IconButton(
                    onPressed: widget.onFavorite,
                    icon: Icon(
                      widget.companion.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: widget.companion.isFavorite
                          ? Colors.red
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              
              // Hover overlay
              if (_isHovered)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.primary.withOpacity(0.05),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 200.ms),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOutQuart)
    .scale(
      begin: const Offset(0.9, 0.9),
      duration: 400.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildFullLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and basic info
        Row(
          children: [
            // Avatar
            Hero(
              tag: 'companion-avatar-${widget.companion.id}',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(widget.companion.appearance.primaryColor),
                      Color(widget.companion.appearance.secondaryColor),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(widget.companion.appearance.primaryColor).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.companion.appearance.avatar,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Name and type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.companion.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPersonalityLabel(widget.companion.personality),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Description
        Text(
          widget.companion.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.3,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        const Spacer(),
        
        // Personality traits
        Row(
          children: [
            _buildTraitChip('Empathy', widget.companion.personality.agreeableness, theme),
            const SizedBox(width: 6),
            _buildTraitChip('Energy', widget.companion.personality.extraversion, theme),
            const SizedBox(width: 6),
            _buildTraitChip('Creativity', widget.companion.personality.openness, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(widget.companion.appearance.primaryColor),
                Color(widget.companion.appearance.secondaryColor),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.companion.appearance.avatar,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.companion.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.companion.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraitChip(String label, double value, ThemeData theme) {
    final intensity = (value * 3).round();
    final color = intensity >= 2 ? Colors.green : intensity >= 1 ? Colors.orange : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getPersonalityLabel(CompanionPersonality personality) {
    if (personality.extraversion > 0.7) return 'Energetic';
    if (personality.agreeableness > 0.7) return 'Caring';
    if (personality.conscientiousness > 0.7) return 'Organized';
    if (personality.neuroticism < 0.3) return 'Calm';
    if (personality.openness > 0.7) return 'Creative';
    return 'Balanced';
  }
}

class CompanionGrid extends StatelessWidget {
  final List<Companion> companions;
  final String? selectedCompanionId;
  final Function(Companion)? onCompanionSelected;
  final Function(Companion)? onCompanionFavorited;
  final bool compact;
  final int crossAxisCount;

  const CompanionGrid({
    required this.companions,
    this.selectedCompanionId,
    this.onCompanionSelected,
    this.onCompanionFavorited,
    this.compact = false,
    this.crossAxisCount = 2,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: compact ? 2.5 : 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: companions.length,
      itemBuilder: (context, index) {
        final companion = companions[index];
        return CompanionCard(
          companion: companion,
          isSelected: companion.id == selectedCompanionId,
          compact: compact,
          onTap: () => onCompanionSelected?.call(companion),
          onFavorite: () => onCompanionFavorited?.call(companion),
        );
      },
    );
  }
}