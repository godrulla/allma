import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? animationDuration;
  final Duration? staggerDelay;
  final Curve? curve;
  final Offset? slideOffset;
  final double? scaleBegin;
  final double? fadeBegin;
  final bool enableHover;
  final VoidCallback? onTap;

  const AnimatedListItem({
    required this.child,
    required this.index,
    this.animationDuration,
    this.staggerDelay,
    this.curve,
    this.slideOffset,
    this.scaleBegin,
    this.fadeBegin,
    this.enableHover = true,
    this.onTap,
    super.key,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverScale;
  late Animation<double> _hoverElevation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverScale = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    _hoverElevation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (!widget.enableHover) return;
    
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationDuration = widget.animationDuration ?? const Duration(milliseconds: 600);
    final staggerDelay = widget.staggerDelay ?? const Duration(milliseconds: 100);
    final curve = widget.curve ?? Curves.easeOutQuart;
    final slideOffset = widget.slideOffset ?? const Offset(0, 0.3);
    final scaleBegin = widget.scaleBegin ?? 0.8;
    final fadeBegin = widget.fadeBegin ?? 0.0;

    Widget animatedChild = widget.child
        .animate()
        .fadeIn(
          duration: animationDuration,
          delay: staggerDelay * widget.index,
          begin: fadeBegin,
          curve: curve,
        )
        .slideY(
          duration: animationDuration,
          delay: staggerDelay * widget.index,
          begin: slideOffset.dy,
          curve: curve,
        )
        .slideX(
          duration: animationDuration,
          delay: staggerDelay * widget.index,
          begin: slideOffset.dx,
          curve: curve,
        )
        .scale(
          duration: animationDuration,
          delay: staggerDelay * widget.index,
          begin: Offset(scaleBegin, scaleBegin),
          curve: curve,
        );

    if (widget.enableHover) {
      animatedChild = MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverScale.value,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: _hoverElevation.value,
                      offset: Offset(0, _hoverElevation.value / 2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: animatedChild,
        ),
      );
    }

    if (widget.onTap != null) {
      animatedChild = GestureDetector(
        onTap: widget.onTap,
        child: animatedChild,
      );
    }

    return animatedChild;
  }
}

class StaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Duration? animationDuration;
  final Duration? staggerDelay;
  final Curve? curve;

  const StaggeredGrid({
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.animationDuration,
    this.staggerDelay,
    this.curve,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          animationDuration: animationDuration,
          staggerDelay: staggerDelay,
          curve: curve,
          child: children[index],
        );
      },
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableHover;
  final Duration animationDuration;

  const AnimatedCard({
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.enableHover = true,
    this.animationDuration = const Duration(milliseconds: 200),
    super.key,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (!widget.enableHover) return;
    
    setState(() => _isHovered = isHovered);
    if (isHovered && !_isPressed) {
      _controller.forward();
    } else if (!_isPressed) {
      _controller.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (!_isHovered) {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    if (!_isHovered) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget card = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color ?? theme.cardColor,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );

    if (widget.enableHover) {
      card = MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: card,
      );
    }

    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: card,
      );
    }

    return card;
  }
}

class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;
  final Curve curve;

  const SlideInAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.begin = const Offset(0, 1),
    this.curve = Curves.easeOutQuart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .slideX(
          duration: duration,
          delay: delay,
          begin: begin.dx,
          curve: curve,
        )
        .slideY(
          duration: duration,
          delay: delay,
          begin: begin.dy,
          curve: curve,
        )
        .fadeIn(
          duration: duration,
          delay: delay,
          curve: curve,
        );
  }
}

class FadeInScale extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double scaleBegin;
  final Curve curve;

  const FadeInScale({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.scaleBegin = 0.8,
    this.curve = Curves.easeOutQuart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          duration: duration,
          delay: delay,
          curve: curve,
        )
        .scale(
          duration: duration,
          delay: delay,
          begin: Offset(scaleBegin, scaleBegin),
          curve: curve,
        );
  }
}

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? highlightColor;
  final Color? baseColor;

  const ShimmerLoading({
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.highlightColor,
    this.baseColor,
    super.key,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surfaceVariant;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}