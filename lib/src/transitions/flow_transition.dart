import 'package:flutter/material.dart';

/// Transition configuration for route pages.
final class FlowTransition {
  const FlowTransition({
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration,
    this.type = FlowTransitionType.material,
    this.preserveGesture = true,
  });

  const FlowTransition.material({
    Duration duration = const Duration(milliseconds: 300),
  }) : this(duration: duration, type: FlowTransitionType.material);

  const FlowTransition.fade({
    Duration duration = const Duration(milliseconds: 250),
  }) : this(duration: duration, type: FlowTransitionType.fade);

  const FlowTransition.slide({
    Duration duration = const Duration(milliseconds: 300),
  }) : this(duration: duration, type: FlowTransitionType.slide);

  const FlowTransition.none()
      : duration = Duration.zero,
        reverseDuration = Duration.zero,
        type = FlowTransitionType.none,
        preserveGesture = true;

  final Duration duration;
  final Duration? reverseDuration;
  final FlowTransitionType type;
  final bool preserveGesture;

  Page<T> buildPage<T>({
    required LocalKey key,
    required Widget child,
    bool fullscreenDialog = false,
  }) {
    switch (type) {
      case FlowTransitionType.none:
        return _NoTransitionPage<T>(key: key, child: child);
      case FlowTransitionType.fade:
        return _CustomTransitionPage<T>(
          key: key,
          child: child,
          duration: duration,
          reverseDuration: reverseDuration ?? duration,
          transitionsBuilder: (context, animation, secondaryAnimation, c) {
            return FadeTransition(opacity: animation, child: c);
          },
        );
      case FlowTransitionType.slide:
        return _CustomTransitionPage<T>(
          key: key,
          child: child,
          duration: duration,
          reverseDuration: reverseDuration ?? duration,
          transitionsBuilder: (context, animation, secondaryAnimation, c) {
            final offset = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(position: offset, child: c);
          },
        );
      case FlowTransitionType.material:
        return MaterialPage<T>(
          key: key,
          child: child,
          fullscreenDialog: fullscreenDialog,
        );
    }
  }
}

enum FlowTransitionType { material, fade, slide, none }

class _NoTransitionPage<T> extends Page<T> {
  const _NoTransitionPage({required this.child, super.key});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

class _CustomTransitionPage<T> extends Page<T> {
  const _CustomTransitionPage({
    required this.child,
    required this.duration,
    required this.reverseDuration,
    required this.transitionsBuilder,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Duration reverseDuration;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }
}
