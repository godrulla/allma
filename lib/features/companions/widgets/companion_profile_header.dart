import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/companions/models/companion.dart';
import '../../../shared/utils/constants.dart';

class CompanionProfileHeader extends StatefulWidget {
  final Companion companion;
  final VoidCallback? onEdit;
  final VoidCallback? onFavorite;
  final VoidCallback? onChat;
  final bool showActions;

  const CompanionProfileHeader({
    required this.companion,
    this.onEdit,
    this.onFavorite,
    this.onChat,
    this.showActions = true,
    super.key,
  });

  @override
  State<CompanionProfileHeader> createState() => _CompanionProfileHeaderState();
}

class _CompanionProfileHeaderState extends State<CompanionProfileHeader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: 300,
      width: double.infinity,
      child: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(widget.companion.appearance.primaryColor),
                        Color(widget.companion.appearance.secondaryColor),
                        Color(widget.companion.appearance.primaryColor).withOpacity(0.8),
                      ],
                      stops: [
                        0.0,
                        0.5 + 0.3 * _backgroundController.value,
                        1.0,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Floating particles effect
          ...List.generate(8, (index) {
            return Positioned(
              left: (size.width * (index * 0.15 + 0.1)) % size.width,
              top: 50 + (index * 25.0) % 200,
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  final offset = _backgroundController.value * 2 * 3.14159;
                  return Transform.translate(
                    offset: Offset(
                      20 * (index.isEven ? 1 : -1) * (0.5 + 0.5 * (offset + index).cos()),
                      15 * (offset * 0.7 + index).sin(),
                    ),
                    child: Container(
                      width: 4 + (index % 3) * 2,
                      height: 4 + (index % 3) * 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Content overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header actions
                  if (widget.showActions)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: widget.onFavorite,
                              icon: Icon(
                                widget.companion.isFavorite 
                                    ? Icons.favorite 
                                    : Icons.favorite_border,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: widget.companion.isFavorite 
                                    ? Colors.red 
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.onEdit != null)
                              IconButton(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: -0.5),
                  
                  const Spacer(),
                  
                  // Avatar with pulse effect
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 120 + 10 * _pulseController.value.sin(),
                        height: 120 + 10 * _pulseController.value.sin(),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Center(
                          child: Hero(
                            tag: 'companion-avatar-${widget.companion.id}',
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  widget.companion.appearance.avatar,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(),
                  
                  const SizedBox(height: 20),
                  
                  // Name and description
                  Text(
                    widget.companion.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.3),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getPersonalityLabel(widget.companion.personality),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    widget.companion.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                  .animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.3),
                  
                  const SizedBox(height: 20),
                  
                  // Chat button
                  if (widget.onChat != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onChat,
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Start Chatting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(widget.companion.appearance.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.5)
                    .scale(begin: const Offset(0.9, 0.9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPersonalityLabel(CompanionPersonality personality) {
    final traits = [
      if (personality.extraversion > 0.7) 'Energetic',
      if (personality.agreeableness > 0.7) 'Caring',
      if (personality.conscientiousness > 0.7) 'Organized',
      if (personality.neuroticism < 0.3) 'Calm',
      if (personality.openness > 0.7) 'Creative',
    ];
    
    if (traits.isNotEmpty) {
      return traits.first;
    }
    
    return 'Balanced Personality';
  }
}

class PersonalityTraitBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const PersonalityTraitBar({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideX(begin: 0.3, duration: 400.ms, curve: Curves.easeOutQuart);
  }
}