import 'package:flutter/widgets.dart';

import 'flow_router.dart';
import '../navigation/navigation_engine.dart';

/// Provides [FlowRouter] to the widget tree.
final class FlowRouterScope extends InheritedNotifier<NavigationEngine> {
  FlowRouterScope({
    required this.router,
    required super.child,
    super.key,
  }) : super(notifier: router.engine);

  final FlowRouter router;

  static FlowRouter of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlowRouterScope>();
    assert(scope != null, 'No FlowRouterScope found in context');
    return scope!.router;
  }

  static FlowRouter? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlowRouterScope>()
        ?.router;
  }

  @override
  bool updateShouldNotify(FlowRouterScope oldWidget) =>
      router != oldWidget.router;
}
