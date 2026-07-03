import 'dart:async';

import 'package:flutter/widgets.dart' hide NavigationMode;

import '../core/navigation_mode.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';

/// Context passed to guards during navigation.
final class GuardContext {
  const GuardContext({
    required this.context,
    required this.currentState,
    required this.targetRoute,
    required this.targetState,
  });

  final BuildContext? context;
  final FlowRouteState currentState;
  final FlowRoute targetRoute;
  final FlowRouteState targetState;
}

/// Result of guard evaluation.
sealed class GuardResult {
  const GuardResult();
}

/// Allow navigation to proceed.
final class GuardAllow extends GuardResult {
  const GuardAllow();
}

/// Block navigation.
final class GuardBlock extends GuardResult {
  const GuardBlock({this.reason});
  final String? reason;
}

/// Redirect to another route.
final class GuardRedirect extends GuardResult {
  const GuardRedirect(this.route, {this.mode = FlowNavigationMode.go});
  final FlowRoute route;
  final FlowNavigationMode mode;
}

/// Guard that can allow, block, or redirect navigation.
abstract class FlowGuard {
  const FlowGuard();

  FutureOr<GuardResult> canActivate(GuardContext context);

  FutureOr<GuardResult> canDeactivate(GuardContext context) =>
      const GuardAllow();
}

/// Guard that redirects when [condition] is true.
final class RedirectGuard extends FlowGuard {
  const RedirectGuard({
    required this.condition,
    required this.redirectTo,
    this.mode = FlowNavigationMode.go,
  });

  final bool Function(GuardContext context) condition;
  final FlowRoute Function(GuardContext context) redirectTo;
  final FlowNavigationMode mode;

  @override
  FutureOr<GuardResult> canActivate(GuardContext context) {
    if (condition(context)) {
      return GuardRedirect(redirectTo(context), mode: mode);
    }
    return const GuardAllow();
  }
}
