import 'package:flutter/widgets.dart';

import 'flow_router.dart';
import '../navigation/navigation_engine.dart';
import '../navigation/navigation_intent.dart';
import '../navigation/navigation_state.dart';
import '../page_builder/page_builder.dart';
import '../typed_routes/flow_route_definition.dart';
import '../web/imperative_url_policy.dart';
import 'flow_router_scope.dart';

/// Builds [Navigator] pages from [NavigationEngine] state.
final class FlowRouterDelegate extends RouterDelegate<NavigationState>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<NavigationState> {
  FlowRouterDelegate({
    required this.router,
    this.observers = const [],
    this.errorBuilder,
  }) : _pageBuilder = PageBuilder(router.registry, router) {
    router.engine.addListener(_onEngineChanged);
  }

  final FlowRouter router;
  final List<NavigatorObserver> observers;
  final Widget Function(BuildContext, FlowRouteState)? errorBuilder;
  final PageBuilder _pageBuilder;
  bool _updatingFromPlatform = false;
  Uri? _lastSyncedUri;
  NavigationState? _lastBuiltState;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigationEngine get engine => router.engine;

  @override
  NavigationState get currentConfiguration => engine.state;

  void _onEngineChanged() {
    final state = engine.state;
    if (_lastBuiltState == state) return;
    _lastBuiltState = state;
    notifyListeners();
    if (!_updatingFromPlatform) {
      _syncPlatformUrl(state);
    }
  }

  /// Notifies the [Router] to rebuild the navigation stack.
  void rebuild() => notifyListeners();

  void _syncPlatformUrl(NavigationState state) {
    final policy = router.imperativeUrlPolicy;
    if (policy == ImperativeUrlPolicy.frozen) return;

    final uri = state.uri;
    if (_lastSyncedUri == uri) return;
    _lastSyncedUri = uri;

    router.routeInformationProvider.routerReportsNewRouteInformation(
      RouteInformation(uri: uri),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = engine.state;

    if (state.isEmpty && errorBuilder != null) {
      return FlowRouterScope(
        router: router,
        child: errorBuilder!(context, engine.toRouteState(state)),
      );
    }

    final pages = _pageBuilder.buildPages(context, state);

    return FlowRouterScope(
      router: router,
      child: Navigator(
        key: navigatorKey,
        pages: pages,
        observers: observers,
        onDidRemovePage: (page) {
          if (!engine.isApplyingState) {
            engine.dispatch(const PopIntent());
          }
        },
      ),
    );
  }

  @override
  Future<void> setNewRoutePath(NavigationState configuration) async {
    _updatingFromPlatform = true;
    engine.setState(configuration);
    _lastSyncedUri = configuration.uri;
    _updatingFromPlatform = false;
  }

  @override
  Future<bool> popRoute() async {
    if (engine.canPop()) {
      await engine.dispatch(const PopIntent());
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    router.engine.removeListener(_onEngineChanged);
    super.dispose();
  }
}
