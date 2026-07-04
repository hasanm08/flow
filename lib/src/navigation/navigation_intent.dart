import '../core/navigation_mode.dart';
import '../core/navigator_id.dart';
import '../typed_routes/flow_route.dart';

/// Sealed hierarchy of navigation intents.
sealed class NavigationIntent {
  const NavigationIntent();
}

/// Replace declarative location stack.
final class GoIntent extends NavigationIntent {
  const GoIntent(this.route, {this.extra});
  final FlowRoute route;
  final Object? extra;

  @override
  String toString() => 'GoIntent(${route.location})';
}

/// Push onto overlay stack.
final class PushIntent extends NavigationIntent {
  const PushIntent(
    this.route, {
    this.extra,
    this.navigatorId = NavigatorId.root,
  });

  final FlowRoute route;
  final Object? extra;
  final NavigatorId navigatorId;

  @override
  String toString() => 'PushIntent(${route.location})';
}

/// Pop from overlay or location stack.
final class PopIntent extends NavigationIntent {
  const PopIntent({this.result, this.navigatorId = NavigatorId.root});
  final Object? result;
  final NavigatorId navigatorId;

  @override
  String toString() => 'PopIntent()';
}

/// Replace top route.
final class ReplaceIntent extends NavigationIntent {
  const ReplaceIntent(
    this.route, {
    this.extra,
    this.navigatorId = NavigatorId.root,
  });

  final FlowRoute route;
  final Object? extra;
  final NavigatorId navigatorId;
}

/// Pop until a route is found.
final class PopUntilIntent extends NavigationIntent {
  const PopUntilIntent(this.route, {this.inclusive = false});
  final FlowRoute route;
  final bool inclusive;
}

/// Switch stateful shell branch.
final class GoBranchIntent extends NavigationIntent {
  const GoBranchIntent(this.index, {this.route});
  final int index;
  final FlowRoute? route;
}

/// Navigate using a route (alias for go).
final class NavigateIntent extends NavigationIntent {
  const NavigateIntent(
    this.route, {
    this.extra,
    this.mode = FlowNavigationMode.go,
  });
  final FlowRoute route;
  final Object? extra;
  final FlowNavigationMode mode;
}

/// Set state from external URL.
final class SetLocationIntent extends NavigationIntent {
  const SetLocationIntent(this.location, {this.extra});
  final String location;
  final Object? extra;
}
