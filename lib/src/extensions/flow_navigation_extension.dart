import 'package:flutter/widgets.dart';

import '../core/flow_router.dart';
import '../core/flow_router_scope.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';

/// Extension methods for navigation from [BuildContext].
extension FlowNavigation on BuildContext {
  /// The nearest [FlowRouter].
  FlowRouter get flow => FlowRouterScope.of(this);

  Future<void> go(FlowRoute route, {Object? extra}) =>
      flow.go(route, extra: extra, context: this);

  Future<void> push(FlowRoute route, {Object? extra}) =>
      flow.push(route, extra: extra, context: this);

  Future<void> replace(FlowRoute route, {Object? extra}) =>
      flow.replace(route, extra: extra, context: this);

  Future<Object?> pop([Object? result]) =>
      flow.pop(context: this, result: result);

  Future<void> popUntil(FlowRoute route, {bool inclusive = false}) =>
      flow.popUntil(route, inclusive: inclusive, context: this);

  bool canPop() => flow.canPop();

  FlowRouteState get routeState => flow.state;
}
