import 'dart:async';

import 'package:flutter/material.dart';

import '../guards/flow_guard.dart';
import '../matcher/route_registry.dart';
import '../middleware/flow_middleware.dart';
import '../navigation/navigation_engine.dart';
import '../navigation/navigation_intent.dart';
import '../navigation/navigation_result.dart';
import '../navigation/navigation_state.dart';
import '../observer/flow_navigator_observer.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';
import '../utils/flow_exceptions.dart';
import '../web/imperative_url_policy.dart';
import '../web/platform_location.dart';
import 'flow_router_delegate.dart';
import 'flow_route_information_parser.dart';
import 'flow_route_information_provider.dart';

/// The primary entry point for Flow routing.
final class FlowRouter {
  FlowRouter({
    required List<FlowRouteNode> routes,
    String? initialLocation,
    this.guards = const [],
    this.middleware = const [],
    this.redirect,
    this.maxRedirects = 5,
    this.observers = const <NavigatorObserver>[],
    this.debugLogDiagnostics = false,
    this.imperativeUrlPolicy = ImperativeUrlPolicy.declarativeOnly,
    this.errorBuilder,
    Listenable? refreshListenable,
  }) : registry = RouteRegistry(
         routes: routes,
         initialLocation: initialLocation ?? '/',
       ) {
    engine = NavigationEngine(
      registry: registry,
      guards: guards,
      middleware: middleware,
      maxRedirects: maxRedirects,
      initialLocation: initialLocation,
    );

    _refreshListenable = refreshListenable;
    _refreshListenable?.addListener(_onRefresh);

    routerDelegate = FlowRouterDelegate(
      router: this,
      observers: observers,
      errorBuilder: errorBuilder,
    );
    routeInformationParser = FlowRouteInformationParser(engine: engine);
    routeInformationProvider = FlowRouteInformationProvider(
      engine: engine,
      defaultLocation: initialLocation ?? registry.initialLocation,
      imperativeUrlPolicy: imperativeUrlPolicy,
    );
  }

  final RouteRegistry registry;
  late final NavigationEngine engine;
  final List<FlowGuard> guards;
  final List<FlowMiddleware> middleware;
  final FlowRedirect? redirect;
  final int maxRedirects;
  final List<NavigatorObserver> observers;
  final bool debugLogDiagnostics;
  final ImperativeUrlPolicy imperativeUrlPolicy;
  final Widget Function(BuildContext, FlowRouteState)? errorBuilder;

  late final FlowRouterDelegate routerDelegate;
  late final FlowRouteInformationParser routeInformationParser;
  late final FlowRouteInformationProvider routeInformationProvider;

  Listenable? _refreshListenable;

  RouterConfig<NavigationState> get config => RouterConfig<NavigationState>(
    routerDelegate: routerDelegate,
    routeInformationParser: routeInformationParser,
    routeInformationProvider: routeInformationProvider,
    backButtonDispatcher: RootBackButtonDispatcher(),
  );

  FlowRouteState get state => engine.toRouteState(engine.state);

  String get location => engine.state.location;

  bool canPop() => engine.canPop();

  void _onRefresh() => routerDelegate.notifyListeners();

  Future<NavigationResult> go(
    FlowRoute route, {
    Object? extra,
    BuildContext? context,
  }) {
    return _dispatch(GoIntent(route, extra: extra), context);
  }

  Future<NavigationResult> push(
    FlowRoute route, {
    Object? extra,
    BuildContext? context,
  }) {
    return _dispatch(PushIntent(route, extra: extra), context);
  }

  Future<NavigationResult> replace(
    FlowRoute route, {
    Object? extra,
    BuildContext? context,
  }) {
    return _dispatch(ReplaceIntent(route, extra: extra), context);
  }

  Future<Object?> pop({BuildContext? context, Object? result}) {
    return _dispatch(PopIntent(result: result), context).then(
      (r) => r.popResult,
    );
  }

  Future<NavigationResult> popUntil(
    FlowRoute route, {
    bool inclusive = false,
    BuildContext? context,
  }) {
    return _dispatch(PopUntilIntent(route, inclusive: inclusive), context);
  }

  Future<NavigationResult> goBranch(
    int index, {
    FlowRoute? route,
    BuildContext? context,
  }) {
    return _dispatch(GoBranchIntent(index, route: route), context);
  }

  void refresh() => routerDelegate.notifyListeners();

  Future<NavigationResult> _dispatch(
    NavigationIntent intent,
    BuildContext? context,
  ) async {
    if (debugLogDiagnostics) {
      debugPrint('[Flow] dispatch: $intent');
    }
    try {
      return await engine.dispatch(intent, context: context);
    } on FlowException catch (e) {
      if (debugLogDiagnostics) debugPrint('[Flow] error: $e');
      rethrow;
    }
  }

  void dispose() {
    _refreshListenable?.removeListener(_onRefresh);
    engine.dispose();
  }
}
