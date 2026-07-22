import 'dart:async';

import 'package:flutter/widgets.dart' hide NavigationMode;

import '../core/navigation_mode.dart';
import '../core/navigator_id.dart';
import '../guards/flow_guard.dart';
import '../matcher/path_pattern.dart';
import '../transitions/flow_transition.dart';
import '../utils/flow_exceptions.dart';
import '../typed_routes/flow_route.dart';

typedef FlowRouteBuilder =
    Widget Function(BuildContext context, FlowRoute route);

typedef FlowRouteFactory = FlowRoute Function(Map<String, String> params);

/// Declarative registration for a [FlowRoute] destination.
final class FlowRouteDefinition {
  FlowRouteDefinition({
    required this.name,
    required this.pathTemplate,
    required this.builder,
    FlowRouteFactory? factory,
    this.guards = const [],
    this.transition = const FlowTransition.material(),
    this.parentNavigatorId,
    this.meta = const {},
    this.restorable = true,
    this.pageKey,
  }) : pattern = PathPattern.parse(pathTemplate),
       factory =
           factory ??
           _defaultFactory(name, pathTemplate, PathPattern.parse(pathTemplate));

  final String name;
  final String pathTemplate;
  final FlowRouteBuilder builder;
  final FlowRouteFactory factory;
  final List<FlowGuard> guards;
  final FlowTransition transition;
  final NavigatorId? parentNavigatorId;
  final Map<String, Object?> meta;
  final bool restorable;
  final PathPattern pattern;

  /// Stable navigator page key shared by related routes (e.g. tab siblings).
  final String? pageKey;

  Widget build(BuildContext context, FlowRoute route) =>
      builder(context, route);

  static FlowRouteFactory _defaultFactory(
    String name,
    String pathTemplate,
    PathPattern pattern,
  ) {
    final pathKeys = pattern.pathParamNames;
    return (allParams) {
      final pathParams = <String, String>{};
      final queryParams = <String, String>{};
      for (final entry in allParams.entries) {
        if (pathKeys.contains(entry.key)) {
          pathParams[entry.key] = entry.value;
        } else {
          queryParams[entry.key] = entry.value;
        }
      }
      return FlowRoute(
        name: name,
        pathTemplate: pathTemplate,
        pathParameters: pathParams,
        queryParameters: queryParams,
      );
    };
  }
}

/// Declares a leaf route — the simplest way to register a destination.
///
/// ```dart
/// flow('/users/:id', name: 'user', builder: (context, route) {
///   return UserPage(id: route.intPathParam('id'));
/// }),
/// ```
FlowLeafNode flow(
  String pathTemplate, {
  required String name,
  required FlowRouteBuilder builder,
  FlowRouteFactory? factory,
  List<FlowGuard> guards = const [],
  FlowTransition transition = const FlowTransition.material(),
  NavigatorId? parentNavigatorId,
  Map<String, Object?> meta = const {},
  bool restorable = true,
  String? pageKey,
}) {
  return FlowLeafNode(
    FlowRouteDefinition(
      name: name,
      pathTemplate: pathTemplate,
      builder: builder,
      factory: factory,
      guards: guards,
      transition: transition,
      parentNavigatorId: parentNavigatorId,
      meta: meta,
      restorable: restorable,
      pageKey: pageKey,
    ),
  );
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
  /// Active branch index.
  int get currentIndex;

  /// Widget for the currently active branch (typically used as `Scaffold.body`).
  Widget get child;

  /// Switch to [index], optionally navigating to [route] within that branch.
  void goBranch(int index, {FlowRoute? route});

  /// Reset a single branch to its default location.
  void resetBranch(int index);

  /// Reset every branch to its default location.
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
  const FlowRedirectResult(this.route, {this.mode = FlowNavigationMode.go});

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
