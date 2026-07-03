import 'package:flutter/widgets.dart';

/// Observes navigator-level route changes.
class FlowNavigatorObserver extends NavigatorObserver {
  void onFlowPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onFlowChanged(route, previousRoute);
  }

  void onFlowPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onFlowChanged(previousRoute, route);
  }

  void onFlowChanged(Route<dynamic>? route, Route<dynamic>? previousRoute) {}

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onFlowPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onFlowPop(route, previousRoute);
  }
}
