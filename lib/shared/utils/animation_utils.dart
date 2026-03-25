import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimationUtils {
  AnimationUtils._();

  // Common animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Common curves
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeOutQuart = Curves.easeOutQuart;
  static const Curve bounceOut = Curves.bounceOut;

  // Stagger delays for list animations
  static Duration staggerDelay(int index, {Duration baseDelay = const Duration(milliseconds: 50)}) {
    return baseDelay * index;
  }

  // Create a slide-in animation from different directions
  static Widget slideIn({
    required Widget child,
    SlideDirection direction = SlideDirection.bottom,
    Duration duration = normal,
    Duration delay = Duration.zero,
    Curve curve = easeOutQuart,
  }) {
    Offset offset;
    switch (direction) {
      case SlideDirection.top:
        offset = const Offset(0, -1);
        break;
      case SlideDirection.bottom:
        offset = const Offset(0, 1);
        break;
      case SlideDirection.left:
        offset = const Offset(-1, 0);
        break;
      case SlideDirection.right:
        offset = const Offset(1, 0);
        break;
    }

    return child
        .animate()
        .slideX(
          duration: duration,
          delay: delay,
          begin: offset.dx,
          curve: curve,
        )
        .slideY(
          duration: duration,
          delay: delay,
          begin: offset.dy,
          curve: curve,
        )
        .fadeIn(
          duration: duration,
          delay: delay,
          curve: curve,
        );
  }

  // Create a scale animation with fade
  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    Duration delay = Duration.zero,
    double scaleBegin = 0.0,
    Curve curve = elasticOut,
  }) {
    return child
        .animate()
        .scale(
          duration: duration,
          delay: delay,
          begin: Offset(scaleBegin, scaleBegin),
          curve: curve,
        )
        .fadeIn(
          duration: duration,
          delay: delay,
          curve: curve,
        );
  }

  // Create a rotation animation
  static Widget rotateIn({
    required Widget child,
    Duration duration = normal,
    Duration delay = Duration.zero,
    double rotationBegin = 0.5,
    Curve curve = easeOut,
  }) {
    return child
        .animate()
        .rotate(
          duration: duration,
          delay: delay,
          begin: rotationBegin,
          curve: curve,
        )
        .fadeIn(
          duration: duration,
          delay: delay,
          curve: curve,
        );
  }

  // Create a flip animation
  static Widget flipIn({
    required Widget child,
    FlipDirection direction = FlipDirection.horizontal,
    Duration duration = normal,
    Duration delay = Duration.zero,
    Curve curve = easeOut,
  }) {
    return child
        .animate()
        .flip(
          duration: duration,
          delay: delay,
          direction: direction == FlipDirection.horizontal ? Axis.horizontal : Axis.vertical,
          curve: curve,
        )
        .fadeIn(
          duration: duration,
          delay: delay,
          curve: curve,
        );
  }

  // Create a shimmer effect
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          color: highlightColor ?? Colors.white.withOpacity(0.5),
        );
  }

  // Create a typing animation for text
  static Widget typeWriter({
    required String text,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 50),
    Duration delay = Duration.zero,
  }) {
    return Text(text, style: style)
        .animate()
        .fadeIn(delay: delay)
        .then()
        .typewriter(
          duration: duration * text.length,
          text: text,
        );
  }

  // Create a bouncing animation
  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double bounceHeight = 20.0,
    bool repeat = false,
  }) {
    final animation = child
        .animate()
        .moveY(
          duration: duration,
          begin: 0,
          end: -bounceHeight,
          curve: Curves.easeOut,
        )
        .then()
        .moveY(
          duration: duration,
          begin: -bounceHeight,
          end: 0,
          curve: Curves.bounceOut,
        );

    if (repeat) {
      return animation.animate(onPlay: (controller) => controller.repeat());
    }
    
    return animation;
  }

  // Create a wave animation
  static Widget wave({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
    double amplitude = 10.0,
    int frequency = 2,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .custom(
          duration: duration,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, amplitude * (value * frequency * 2 * 3.14159).sin()),
              child: child,
            );
          },
        );
  }

  // Create a pulse animation
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double scaleMin = 1.0,
    double scaleMax = 1.1,
    bool repeat = true,
  }) {
    final animation = child
        .animate()
        .scale(
          duration: duration,
          begin: Offset(scaleMin, scaleMin),
          end: Offset(scaleMax, scaleMax),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          duration: duration,
          begin: Offset(scaleMax, scaleMax),
          end: Offset(scaleMin, scaleMin),
          curve: Curves.easeInOut,
        );

    if (repeat) {
      return animation.animate(onPlay: (controller) => controller.repeat());
    }
    
    return animation;
  }

  // Create a shake animation
  static Widget shake({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    double shakeDistance = 10.0,
  }) {
    return child
        .animate()
        .shake(
          duration: duration,
          offset: Offset(shakeDistance, 0),
        );
  }

  // Create a list animation with staggered items
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration itemDuration = normal,
    SlideDirection direction = SlideDirection.bottom,
    Curve curve = easeOutQuart,
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return slideIn(
        child: child,
        direction: direction,
        duration: itemDuration,
        delay: staggerDelay * index,
        curve: curve,
      );
    }).toList();
  }

  // Create a hero-style animation
  static Widget hero({
    required Widget child,
    required String tag,
    Duration duration = normal,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }

  // Create a page transition
  static PageRouteBuilder<T> createRoute<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.slideFromRight,
    Duration duration = normal,
    Curve curve = easeOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case PageTransitionType.slideFromRight:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          case PageTransitionType.slideFromLeft:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          case PageTransitionType.slideFromBottom:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          case PageTransitionType.slideFromTop:
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          case PageTransitionType.fade:
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: curve)),
              child: child,
            );
          case PageTransitionType.scale:
            return ScaleTransition(
              scale: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
          case PageTransitionType.rotation:
            return RotationTransition(
              turns: animation.drive(
                Tween(begin: 0.25, end: 0.0).chain(CurveTween(curve: curve)),
              ),
              child: child,
            );
        }
      },
    );
  }
}

enum SlideDirection { top, bottom, left, right }
enum FlipDirection { horizontal, vertical }
enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotation,
}

// Extension methods for easier animation access
extension WidgetAnimationExtensions on Widget {
  Widget slideInFromBottom({
    Duration duration = AnimationUtils.normal,
    Duration delay = Duration.zero,
  }) =>
      AnimationUtils.slideIn(
        child: this,
        direction: SlideDirection.bottom,
        duration: duration,
        delay: delay,
      );

  Widget slideInFromTop({
    Duration duration = AnimationUtils.normal,
    Duration delay = Duration.zero,
  }) =>
      AnimationUtils.slideIn(
        child: this,
        direction: SlideDirection.top,
        duration: duration,
        delay: delay,
      );

  Widget slideInFromLeft({
    Duration duration = AnimationUtils.normal,
    Duration delay = Duration.zero,
  }) =>
      AnimationUtils.slideIn(
        child: this,
        direction: SlideDirection.left,
        duration: duration,
        delay: delay,
      );

  Widget slideInFromRight({
    Duration duration = AnimationUtils.normal,
    Duration delay = Duration.zero,
  }) =>
      AnimationUtils.slideIn(
        child: this,
        direction: SlideDirection.right,
        duration: duration,
        delay: delay,
      );

  Widget scaleInWithFade({
    Duration duration = AnimationUtils.normal,
    Duration delay = Duration.zero,
    double scaleBegin = 0.0,
  }) =>
      AnimationUtils.scaleIn(
        child: this,
        duration: duration,
        delay: delay,
        scaleBegin: scaleBegin,
      );

  Widget pulseAnimation({
    Duration duration = const Duration(milliseconds: 1000),
    double scaleMin = 1.0,
    double scaleMax = 1.1,
    bool repeat = true,
  }) =>
      AnimationUtils.pulse(
        child: this,
        duration: duration,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
        repeat: repeat,
      );

  Widget shakeAnimation({
    Duration duration = const Duration(milliseconds: 500),
    double shakeDistance = 10.0,
  }) =>
      AnimationUtils.shake(
        child: this,
        duration: duration,
        shakeDistance: shakeDistance,
      );
}