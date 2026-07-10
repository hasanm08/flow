import 'package:flutter/widgets.dart';

import '../core/flow_router.dart';
import '../core/flow_router_scope.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';
import '../utils/flow_exceptions.dart';

/// Navigation and router access from [BuildContext].
extension FlowNavigation on BuildContext {
  /// The nearest [FlowRouter].
  FlowRouter get flowRouter => FlowRouterScope.of(this);

  /// Current URL location.
  String get location => flowRouter.location;

  /// Read-only navigation state.
  FlowRouteState get routeState => flowRouter.state;

  bool canPop() => flowRouter.canPop();

  /// Navigate with a route instance.
  ///
  /// ```dart
  /// context.flow(Routes.home);                    // go
  /// context.flow(Routes.about, push: true);       // push overlay
  /// ```
  Future<void> flow(FlowRoute route, {bool push = false, Object? extra}) {
    if (push) {
      return flowRouter.push(route, extra: extra, context: this);
    }
    return flowRouter.go(route, extra: extra, context: this);
  }

  /// Navigate by route name (`goNamed` / `pushNamed` equivalent).
  ///
  /// ```dart
  /// context.flowNamed('user', pathParameters: {'id': '42'});
  /// context.flowNamed('about', push: true);
  /// ```
  Future<void> flowNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    String? fragment,
    bool push = false,
    Object? extra,
  }) {
    final definition = flowRouter.registry.findDefinitionByName(name);
    if (definition == null) {
      throw FlowNotFoundException('No route named "$name"');
    }
    return flow(
      FlowRoute(
        name: name,
        pathTemplate: definition.pathTemplate,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        fragment: fragment,
      ),
      push: push,
      extra: extra,
    );
  }

  Future<void> replace(FlowRoute route, {Object? extra}) =>
      flowRouter.replace(route, extra: extra, context: this);

  Future<void> popUntil(FlowRoute route, {bool inclusive = false}) =>
      flowRouter.popUntil(route, inclusive: inclusive, context: this);

  /// Pop from overlay or location stack.
  Future<Object?> pop([Object? result]) =>
      flowRouter.pop(context: this, result: result);
}
