import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../utils/constants.dart';

class PrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final BorderRadius? borderRadius;

  const PrimaryButton({
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> 
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
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
              disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.5),
              elevation: widget.onPressed != null ? 2 : 0,
              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
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
                        theme.colorScheme.onPrimary,
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
class PrimaryIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final bool isLoading;
  final bool isExpanded;

  const PrimaryIconButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
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
class SmallPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const SmallPrimaryButton({
    required this.child,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minimumSize: const Size(0, 40),
      child: child,
    );
  }
}