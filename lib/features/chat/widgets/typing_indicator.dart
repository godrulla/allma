import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/utils/constants.dart';

class TypingIndicator extends StatelessWidget {
  final String companionName;
  final bool showAvatar;

  const TypingIndicator({
    required this.companionName,
    this.showAvatar = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.1),
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppConstants.borderRadius),
                topRight: const Radius.circular(AppConstants.borderRadius),
                bottomRight: const Radius.circular(AppConstants.borderRadius),
                bottomLeft: Radius.circular(showAvatar ? 4 : AppConstants.borderRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$companionName is typing',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _buildAnimatedDots(theme),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .slideY(
      begin: 0.3,
      duration: AppConstants.animationDuration,
      curve: Curves.easeOutQuart,
    )
    .fadeIn(
      duration: AppConstants.animationDuration,
      curve: Curves.easeOut,
    );
  }

  Widget _buildAnimatedDots(ThemeData theme) {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.secondary,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: index * 200),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(0.5, 0.5),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }),
    );
  }
}

/// Simple typing indicator without companion context
class SimpleTypingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const SimpleTypingIndicator({
    this.color,
    this.size = 6,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = color ?? theme.colorScheme.primary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: size * 0.2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.3, 1.3),
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: index * 200),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(0.5, 0.5),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }),
    );
  }
}

/// Pulsing typing indicator for input fields
class InputTypingIndicator extends StatelessWidget {
  final bool isVisible;
  final String text;

  const InputTypingIndicator({
    required this.isVisible,
    this.text = 'AI is thinking...',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SimpleTypingIndicator(
            color: theme.colorScheme.primary,
            size: 4,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 200.ms)
    .slideY(begin: -0.5, duration: 200.ms);
  }
}

/// Circular typing indicator for buttons
class CircularTypingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const CircularTypingIndicator({
    this.size = 20,
    this.color,
    this.strokeWidth = 2,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .rotate(duration: 1000.ms);
  }
}

/// Wave typing indicator
class WaveTypingIndicator extends StatelessWidget {
  final Color? color;
  final double height;
  final int barsCount;

  const WaveTypingIndicator({
    this.color,
    this.height = 20,
    this.barsCount = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = color ?? theme.colorScheme.primary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(barsCount, (index) {
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scaleY(
          begin: 0.3,
          end: 1.0,
          duration: const Duration(milliseconds: 800),
          delay: Duration(milliseconds: index * 100),
          curve: Curves.easeInOut,
        )
        .then()
        .scaleY(
          begin: 1.0,
          end: 0.3,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }),
    );
  }
}

/// Pulse typing indicator
class PulseTypingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const PulseTypingIndicator({
    this.color,
    this.size = 8,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulseColor = color ?? theme.colorScheme.primary;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pulseColor,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.5, 1.5),
      duration: 1000.ms,
      curve: Curves.easeInOut,
    )
    .fadeOut(
      begin: 1.0,
      duration: 1000.ms,
      curve: Curves.easeInOut,
    );
  }
}