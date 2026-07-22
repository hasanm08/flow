import 'package:flutter/material.dart';

import '../core/flow_router.dart';
import '../matcher/route_match.dart';
import '../matcher/route_registry.dart';
import '../navigation/navigation_state.dart';
import '../shell/flow_stateful_shell_controller.dart';

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
    final shellMatches = state.locationChain.shellMatches;

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
          builder: (scopedContext) {
            final content = match.definition.build(scopedContext, match.route);
            return _wrapWithShells(scopedContext, content, shellMatches);
          },
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

  /// Wraps [child] with shell builders from innermost to outermost.
  Widget _wrapWithShells(
    BuildContext context,
    Widget child,
    List<ShellMatch> shellMatches,
  ) {
    if (shellMatches.isEmpty) return child;

    var wrapped = child;
    for (var i = shellMatches.length - 1; i >= 0; i--) {
      final shellMatch = shellMatches[i];
      final current = wrapped;

      final shell = shellMatch.shell;
      if (shell != null) {
        wrapped = Builder(
          builder: (scopedContext) => shell.builder(scopedContext, current),
        );
        continue;
      }

      final stateful = shellMatch.statefulShell;
      if (stateful != null) {
        final controller = FlowStatefulShellControllerImpl(
          router: router,
          node: stateful,
          currentIndex: shellMatch.branchIndex,
          child: current,
        );
        wrapped = Builder(
          builder: (scopedContext) =>
              stateful.builder(scopedContext, controller),
        );
      }
    }
    return wrapped;
  }

  int? _indexOfKey(Object key) {
    if (_cachedState == null) return null;
    for (var i = 0; i < _cachedKeys.length; i++) {
      if (_cachedKeys[i] == key) return i;
    }
    return null;
  }
}
