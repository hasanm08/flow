import 'dart:async';

import 'package:flutter/widgets.dart' hide NavigationMode;

import '../core/navigation_mode.dart';
import '../core/navigator_id.dart';
import '../guards/flow_guard.dart';
import '../matcher/path_pattern.dart';
import '../transitions/flow_transition.dart';
import '../utils/flow_exceptions.dart';
import '../typed_routes/flow_route.dart';

typedef FlowRouteBuilder<T extends FlowRoute> =
    Widget Function(BuildContext context, T route);

typedef FlowRouteFactory = FlowRoute Function(Map<String, String> params);

/// Declarative registration for a typed [FlowRoute].
final class FlowRouteDefinition<T extends FlowRoute> {
  FlowRouteDefinition({
    required this.name,
    required this.pathTemplate,
    required this.builder,
    required this.factory,
    this.guards = const [],
    this.transition = const FlowTransition.material(),
    this.parentNavigatorId,
    this.meta = const {},
    this.restorable = true,
    this.pageKey,
  }) : pattern = PathPattern.parse(pathTemplate);

  final String name;
  final String pathTemplate;
  final FlowRouteBuilder<T> builder;
  final FlowRouteFactory factory;
  final List<FlowGuard> guards;
  final FlowTransition transition;
  final NavigatorId? parentNavigatorId;
  final Map<String, Object?> meta;
  final bool restorable;
  final PathPattern pattern;

  /// Stable navigator page key shared by related routes (e.g. tab siblings).
  final String? pageKey;

  Widget build(BuildContext context, FlowRoute route) {
    return builder(context, route as T);
  }
}

/// Base for shell route definitions.
sealed class FlowRouteNode {
  const FlowRouteNode();
}

final class FlowLeafNode extends FlowRouteNode {
  const FlowLeafNode(this.definition);
  final FlowRouteDefinition definition;
}

final class FlowShellNode extends FlowRouteNode {
  FlowShellNode({
    required this.pathTemplate,
    required this.navigatorId,
    required this.builder,
    required this.children,
    this.restorable = true,
  }) : pattern = PathPattern.parse(pathTemplate);

  final String pathTemplate;
  final NavigatorId navigatorId;
  final Widget Function(BuildContext context, Widget child) builder;
  final List<FlowRouteNode> children;
  final bool restorable;
  final PathPattern pattern;
}

final class FlowBranchNode extends FlowRouteNode {
  const FlowBranchNode({
    required this.navigatorId,
    required this.defaultLocation,
    required this.children,
    this.label,
  });

  final NavigatorId navigatorId;
  final String defaultLocation;
  final List<FlowRouteNode> children;
  final String? label;
}

final class FlowStatefulShellNode extends FlowRouteNode {
  FlowStatefulShellNode({
    required this.pathTemplate,
    required this.branches,
    required this.builder,
    this.restorable = true,
  }) : pattern = PathPattern.parse(pathTemplate);

  final String pathTemplate;
  final List<FlowBranchNode> branches;
  final Widget Function(BuildContext context, FlowStatefulShellController shell)
      builder;
  final bool restorable;
  final PathPattern pattern;
}

/// Controller passed to stateful shell builders.
abstract interface class FlowStatefulShellController {
  int get currentIndex;
  void goBranch(int index, {FlowRoute? route});
  void resetBranch(int index);
  void resetAllBranches();
}

/// Redirect callback signature.
typedef FlowRedirect =
    FutureOr<FlowRedirectResult?> Function(
      BuildContext context,
      FlowRouteState state,
    );

/// Result of a redirect evaluation.
final class FlowRedirectResult {
  const FlowRedirectResult(
    this.route, {
    this.mode = FlowNavigationMode.go,
  });

  final FlowRoute route;
  final FlowNavigationMode mode;
}

/// Read-only navigation state exposed to builders and guards.
final class FlowRouteState {
  const FlowRouteState({
    required this.uri,
    required this.location,
    required this.matchedRoutes,
    required this.pathParameters,
    required this.queryParameters,
    this.extra,
    this.error,
  });

  final Uri uri;
  final String location;
  final List<FlowRoute> matchedRoutes;
  final Map<String, String> pathParameters;
  final Map<String, String> queryParameters;
  final Object? extra;
  final FlowException? error;

  FlowRoute? get route => matchedRoutes.isEmpty ? null : matchedRoutes.last;

  String get fullPath => location;
}
