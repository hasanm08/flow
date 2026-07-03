import 'package:flutter/material.dart';

import '../core/flow_router.dart';
import '../core/flow_router_scope.dart';
import '../matcher/route_registry.dart';
import '../navigation/navigation_state.dart';

/// Builds [Page] objects from navigation state.
final class PageBuilder {
  PageBuilder(this.registry, this.router);

  final RouteRegistry registry;
  final FlowRouter router;

  List<Page<void>> buildPages(BuildContext context, NavigationState state) {
    final pages = <Page<void>>[];

    for (final match in state.locationChain.matches) {
      // Path-only key: query-param changes (e.g. tabs) don't recreate the page.
      final key = ValueKey(
        'flow-${match.definition.pageKey ?? match.matchedLocation}',
      );
      final child = FlowRouterScope(
        router: router,
        child: Builder(
          builder: (scopedContext) =>
              match.definition.build(scopedContext, match.route),
        ),
      );
      pages.add(
        match.definition.transition.buildPage(
          key: key,
          child: child,
        ),
      );
    }

    final rootOverlay = state.overlayFor('root');
    for (final entry in rootOverlay.entries) {
      final key = ValueKey('flow-overlay-${entry.id}');
      pages.add(
        entry.match.definition.transition.buildPage(
          key: key,
          child: FlowRouterScope(
            router: router,
            child: Builder(
              builder: (scopedContext) => entry.match.definition.build(
                scopedContext,
                entry.route,
              ),
            ),
          ),
        ),
      );
    }

    if (pages.isEmpty) {
      pages.add(
        const MaterialPage<void>(
          key: ValueKey('flow-empty'),
          child: SizedBox.shrink(),
        ),
      );
    }

    return pages;
  }
}
