import 'dart:async';

import '../navigation/navigation_result.dart';
import '../navigation/navigation_state.dart';

/// Context for middleware hooks.
final class MiddlewareContext {
  const MiddlewareContext({
    required this.previousState,
    required this.targetState,
    this.extra,
  });

  final NavigationState previousState;
  final NavigationState targetState;
  final Object? extra;
}

/// Middleware observes navigation before and after transitions.
abstract interface class FlowMiddleware {
  FutureOr<void> onBefore(MiddlewareContext context);
  FutureOr<void> onAfter(MiddlewareContext context, NavigationResult result);
}

/// Logs navigation transitions.
final class LoggingMiddleware implements FlowMiddleware {
  const LoggingMiddleware({this.onLog = _defaultLog});

  final void Function(String message) onLog;

  static void _defaultLog(String message) {
    // ignore: avoid_print
    print('[Flow] $message');
  }

  @override
  void onBefore(MiddlewareContext context) {
    if (context.previousState.location == context.targetState.location &&
        context.previousState.overlayStacks.length ==
            context.targetState.overlayStacks.length) {
      return;
    }
    onLog(
      '→ ${context.targetState.location} (from ${context.previousState.location})',
    );
  }

  @override
  void onAfter(MiddlewareContext context, NavigationResult result) {
    if (!result.completed) return;
    if (context.previousState.location == result.state.location &&
        context.previousState.overlayStacks.length ==
            result.state.overlayStacks.length) {
      return;
    }
    onLog('✓ ${result.state.location}');
  }
}
