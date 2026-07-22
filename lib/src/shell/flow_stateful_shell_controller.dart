import 'package:flutter/widgets.dart';

import '../core/flow_router.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';

/// Default [FlowStatefulShellController] used by the page builder.
final class FlowStatefulShellControllerImpl
    implements FlowStatefulShellController {
  FlowStatefulShellControllerImpl({
    required this.router,
    required this.node,
    required this.currentIndex,
    required this.child,
  });

  final FlowRouter router;
  final FlowStatefulShellNode node;

  @override
  final int currentIndex;

  @override
  final Widget child;

  @override
  void goBranch(int index, {FlowRoute? route}) {
    if (route != null) {
      router.goBranch(index, route: route);
      return;
    }
    if (index < 0 || index >= node.branches.length) return;
    final result = router.registry.engine.match(
      Uri.parse(node.branches[index].defaultLocation),
    );
    final leafRoute = result.chain.leaf?.route;
    if (leafRoute != null) {
      router.goBranch(index, route: leafRoute);
      return;
    }
    router.goBranch(index);
  }

  @override
  void resetBranch(int index) {
    if (index < 0 || index >= node.branches.length) return;
    goBranch(index);
  }

  @override
  void resetAllBranches() {
    goBranch(currentIndex);
  }
}
