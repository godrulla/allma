import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../utils/constants.dart';

class SecondaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final BorderRadius? borderRadius;

  const SecondaryButton({
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.padding,
    this.minimumSize,
    this.borderRadius,
    super.key,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: widget.onPressed != null 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              ),
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              minimumSize: widget.minimumSize ?? const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: widget.borderRadius ?? 
                    BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : widget.child,
          ),
        );
      },
    );

    // Add tap animation
    button = GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) => _animationController.forward()
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) => _animationController.reverse()
          : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? () => _animationController.reverse()
          : null,
      child: button,
    );

    if (widget.isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Variant with icon
class SecondaryIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final bool isLoading;
  final bool isExpanded;

  const SecondaryIconButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          label,
        ],
      ),
    );
  }
}

/// Small variant
class SmallSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const SmallSecondaryButton({
    required this.child,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minimumSize: const Size(0, 40),
      child: child,
    );
  }
}

/// Ghost variant (no border)
class GhostButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isExpanded;

  const GhostButton({
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    super.key,
  });

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: TextButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : widget.child,
          ),
        );
      },
    );

    // Add tap animation
    button = GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) => _animationController.forward()
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) => _animationController.reverse()
          : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? () => _animationController.reverse()
          : null,
      child: button,
    );

    if (widget.isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}