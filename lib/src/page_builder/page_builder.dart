import 'package:flutter/material.dart';

import '../core/flow_router.dart';
import '../matcher/route_registry.dart';
import '../navigation/navigation_state.dart';

/// Builds [Page] objects from navigation state with page-level caching.
final class PageBuilder {
  PageBuilder(this.registry, this.router);

  final RouteRegistry registry;
  final FlowRouter router;

  List<Page<void>> _cachedPages = const [];
  final List<Object> _cachedKeys = [];
  NavigationState? _cachedState;

  List<Page<void>> buildPages(BuildContext context, NavigationState state) {
    if (identical(_cachedState, state)) return _cachedPages;

    final pages = <Page<void>>[];
    final keys = <Object>[];

    for (final match in state.locationChain.matches) {
      final key = match.definition.pageKey ?? match.matchedLocation;
      final cachedIndex = _indexOfKey(key);
      if (cachedIndex != null && _cachedPages.length > cachedIndex) {
        pages.add(_cachedPages[cachedIndex]);
        keys.add(key);
        continue;
      }

      final page = match.definition.transition.buildPage<void>(
        key: ValueKey('flow-$key'),
        child: Builder(
          builder: (scopedContext) =>
              match.definition.build(scopedContext, match.route),
        ),
      );
      pages.add(page);
      keys.add(key);
    }

    final rootOverlay = state.overlayFor('root');
    for (final entry in rootOverlay.entries) {
      final key = 'overlay-${entry.id}';
      pages.add(
        entry.match.definition.transition.buildPage<void>(
          key: ValueKey('flow-$key'),
          child: Builder(
            builder: (scopedContext) =>
                entry.match.definition.build(scopedContext, entry.route),
          ),
        ),
      );
      keys.add(key);
    }

    if (pages.isEmpty) {
      pages.add(
        const MaterialPage<void>(
          key: ValueKey('flow-empty'),
          child: SizedBox.shrink(),
        ),
      );
      keys.add('empty');
    }

    _cachedState = state;
    _cachedPages = pages;
    _cachedKeys
      ..clear()
      ..addAll(keys);
    return pages;
  }

  int? _indexOfKey(Object key) {
    if (_cachedState == null) return null;
    for (var i = 0; i < _cachedKeys.length; i++) {
      if (_cachedKeys[i] == key) return i;
    }
    return null;
  }
}
