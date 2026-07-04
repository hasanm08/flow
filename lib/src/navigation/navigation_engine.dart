import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/navigation_mode.dart';
import '../core/navigator_id.dart';
import '../guards/flow_guard.dart';
import '../history/navigation_history.dart';
import '../matcher/route_match.dart';
import '../matcher/route_registry.dart';
import '../middleware/flow_middleware.dart';
import '../navigation/navigation_intent.dart';
import '../navigation/navigation_result.dart';
import '../navigation/navigation_state.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';
import '../utils/flow_exceptions.dart';
import '../web/platform_location.dart';

/// Core navigation engine — single source of truth for routing state.
final class NavigationEngine extends ChangeNotifier {
  NavigationEngine({
    required RouteRegistry registry,
    this.guards = const [],
    this.middleware = const [],
    this.maxRedirects = 5,
    String? initialLocation,
  }) : _registry = registry,
       _state = _initialState(registry, initialLocation),
       _history = NavigationHistory() {
    if (!_state.isEmpty) {
      _history.push(_state.location);
    }
  }

  final RouteRegistry _registry;
  final List<FlowGuard> guards;
  final List<FlowMiddleware> middleware;
  final int maxRedirects;
  final NavigationHistory _history;

  NavigationState _state;
  int _overlayIdCounter = 0;
  bool _isDispatching = false;
  bool _isApplyingState = false;

  /// True while the engine is pushing a new state to the [Navigator].
  ///
  /// The delegate uses this to avoid handling [PopIntent] twice when
  /// [Navigator.onDidRemovePage] fires for a state-driven page removal.
  bool get isApplyingState => _isApplyingState;

  NavigationState get state => _state;
  NavigationHistory get history => _history;
  RouteRegistry get registry => _registry;

  static NavigationState _initialState(
    RouteRegistry registry,
    String? initialLocation,
  ) {
    final location = resolveInitialLocation(
      defaultLocation: initialLocation ?? registry.initialLocation,
    );
    final result = registry.engine.match(Uri.parse(location));
    if (result.isError) {
      return NavigationState(
        locationChain: RouteMatchChain(
          matches: const [],
          uri: Uri.parse(location),
        ),
      );
    }
    return NavigationState(locationChain: result.chain);
  }

  FlowRouteState toRouteState(NavigationState navState, {Object? extra}) {
    final chain = navState.locationChain;
    return FlowRouteState(
      uri: chain.uri,
      location: navState.location,
      matchedRoutes: chain.matches.map((m) => m.route).toList(),
      pathParameters: chain.leaf?.pathParameters ?? const {},
      queryParameters: Uri.splitQueryString(chain.uri.query),
      extra: extra ?? navState.extra,
      error: chain.isEmpty ? const FlowNotFoundException('Not found') : null,
    );
  }

  Future<NavigationResult> dispatch(
    NavigationIntent intent, {
    BuildContext? context,
  }) async {
    final incomingContext = context;
    while (_isDispatching) {
      await Future<void>.delayed(Duration.zero);
    }

    _isDispatching = true;
    try {
      final previous = _state;
      late NavigationState next;
      Object? popResult;

      switch (intent) {
        case GoIntent(:final route, :final extra):
          next = await _go(
            route,
            extra: extra,
            context: incomingContext != null && incomingContext.mounted
                ? incomingContext
                : null,
          );
        case PushIntent(:final route, :final extra, :final navigatorId):
          next = _push(route, navigatorId: navigatorId, extra: extra);
        case PopIntent(:final navigatorId):
          final result = _pop(navigatorId);
          next = result.$1;
          popResult = result.$2;
          if (next == previous) {
            return NavigationResult(state: _state, completed: false);
          }
        case ReplaceIntent(:final route, :final extra, :final navigatorId):
          next = _replace(route, navigatorId: navigatorId, extra: extra);
        case PopUntilIntent(:final route, :final inclusive):
          next = _popUntil(route, inclusive: inclusive);
        case GoBranchIntent(:final index, :final route):
          next = await _goBranch(
            index,
            route: route,
            context: incomingContext != null && incomingContext.mounted
                ? incomingContext
                : null,
          );
        case NavigateIntent(:final route, :final extra, :final mode):
          next = mode == FlowNavigationMode.push
              ? _push(route, extra: extra)
              : await _go(
                  route,
                  extra: extra,
                  context: incomingContext != null && incomingContext.mounted
                      ? incomingContext
                      : null,
                );
        case SetLocationIntent(:final location, :final extra):
          next = await _setLocation(location, extra: extra);
      }

      final middlewareContext = MiddlewareContext(
        previousState: previous,
        targetState: next,
        extra: intent is GoIntent
            ? intent.extra
            : intent is PushIntent
            ? intent.extra
            : null,
      );

      for (final m in middleware) {
        await m.onBefore(middlewareContext);
      }

      _applyState(next);

      switch (intent) {
        case ReplaceIntent():
          _history.replace(_state.location, extra: _state.extra);
        case PopIntent():
          break;
        default:
          if (previous.location != _state.location) {
            _history.push(_state.location, extra: _state.extra);
          }
      }

      final result = NavigationResult(state: _state, popResult: popResult);

      for (final m in middleware) {
        await m.onAfter(middlewareContext, result);
      }

      return result;
    } finally {
      _isDispatching = false;
    }
  }

  Future<NavigationState> _go(
    FlowRoute route, {
    Object? extra,
    BuildContext? context,
  }) async {
    final resolved = await _resolveWithGuards(route, context: context);
    if (resolved == null) return _state;

    final result = _registry.engine.match(Uri.parse(resolved.location));
    if (result.isError) return _state;

    return NavigationState(
      locationChain: applyRouteToChain(result.chain, resolved),
      overlayStacks: const {},
      extra: extra,
    );
  }

  NavigationState _push(
    FlowRoute route, {
    NavigatorId navigatorId = NavigatorId.root,
    Object? extra,
  }) {
    final result = _registry.engine.match(Uri.parse(route.location));
    if (result.isError || result.chain.leaf == null) return _state;

    final match = result.chain.leaf!.copyWithRoute(route);
    final entry = FlowOverlayEntry(
      route: route,
      match: match,
      extra: extra,
      id: _overlayIdCounter++,
    );

    final stacks = Map<String, OverlayStack>.from(_state.overlayStacks);
    final key = navigatorId.value;
    final current = stacks[key] ?? const OverlayStack();
    stacks[key] = current.push(entry);

    return _state.copyWith(overlayStacks: stacks);
  }

  (NavigationState, Object?) _pop(NavigatorId navigatorId) {
    final key = navigatorId.value;
    final overlay = _state.overlayFor(key);

    if (!overlay.isEmpty) {
      final stacks = Map<String, OverlayStack>.from(_state.overlayStacks);
      stacks[key] = overlay.pop();
      return (_state.copyWith(overlayStacks: stacks), null);
    }

    if (_state.locationChain.matches.length > 1) {
      final matches = List<RouteMatch>.from(_state.locationChain.matches)
        ..removeLast();
      final chain = _state.locationChain.copyWith(matches: matches);
      _history.goBack();
      return (_state.copyWith(locationChain: chain), null);
    }

    if (_history.canGoBack) {
      final entry = _history.goBack();
      if (entry != null) {
        final uri = Uri.parse(
          entry.location.startsWith('/')
              ? entry.location
              : '/${entry.location}',
        );
        final result = _registry.engine.match(uri);
        if (!result.isError) {
          return (
            NavigationState(locationChain: result.chain, extra: entry.extra),
            null,
          );
        }
      }
    }

    return (_state, null);
  }

  NavigationState _replace(
    FlowRoute route, {
    NavigatorId navigatorId = NavigatorId.root,
    Object? extra,
  }) {
    final result = _registry.engine.match(Uri.parse(route.location));
    if (result.isError || result.chain.leaf == null) return _state;

    final chain = applyRouteToChain(result.chain, route);
    final match = chain.leaf!;

    final entry = FlowOverlayEntry(
      route: route,
      match: match,
      extra: extra,
      id: _overlayIdCounter++,
    );

    final key = navigatorId.value;
    final overlay = _state.overlayFor(key);

    if (!overlay.isEmpty) {
      final stacks = Map<String, OverlayStack>.from(_state.overlayStacks);
      stacks[key] = overlay.replaceTop(entry);
      return _state.copyWith(overlayStacks: stacks);
    }

    return _state.copyWith(
      locationChain: chain,
      extra: extra,
      clearExtra: extra == null,
    );
  }

  NavigationState _popUntil(FlowRoute route, {bool inclusive = false}) {
    final targetLocation = route.location;

    for (final key in _state.overlayStacks.keys) {
      var stack = _state.overlayStacks[key]!;
      while (!stack.isEmpty) {
        final top = stack.top!;
        if (top.route.location == targetLocation) {
          if (inclusive) stack = stack.pop();
          break;
        }
        stack = stack.pop();
      }
    }

    var matches = List<RouteMatch>.from(_state.locationChain.matches);
    while (matches.isNotEmpty) {
      final top = matches.last;
      if (top.route.location == targetLocation) {
        if (inclusive) matches.removeLast();
        break;
      }
      matches.removeLast();
    }

    return _state.copyWith(
      locationChain: _state.locationChain.copyWith(matches: matches),
    );
  }

  Future<NavigationState> _goBranch(
    int index, {
    FlowRoute? route,
    BuildContext? context,
  }) async {
    if (route != null) {
      return _go(route, context: context);
    }
    return _state.copyWith(
      locationChain: _state.locationChain.copyWith(activeBranchIndex: index),
    );
  }

  Future<NavigationState> _setLocation(
    String location, {
    Object? extra,
  }) async {
    final result = _registry.engine.match(Uri.parse(location));
    if (result.isError) return _state;

    return NavigationState(locationChain: result.chain, extra: extra);
  }

  Future<FlowRoute?> _resolveWithGuards(
    FlowRoute route, {
    BuildContext? context,
  }) async {
    var activeContext = context;
    var current = route;
    var redirectCount = 0;

    while (redirectCount < maxRedirects) {
      final result = _registry.engine.match(Uri.parse(current.location));
      if (result.isError) return null;

      final targetState = toRouteState(
        NavigationState(locationChain: result.chain),
      );
      final currentState = toRouteState(_state);

      var redirected = false;
      for (final guard in [...guards, ..._collectRouteGuards(result.chain)]) {
        final guardContext = GuardContext(
          context: activeContext != null && activeContext.mounted
              ? activeContext
              : null,
          currentState: currentState,
          targetRoute: current,
          targetState: targetState,
        );
        if (guardContext.context == null) {
          activeContext = null;
        }
        final guardResult = await guard.canActivate(guardContext);
        switch (guardResult) {
          case GuardAllow():
            break;
          case GuardBlock(:final reason):
            throw FlowGuardBlockedException(
              'Navigation blocked',
              reason: reason,
            );
          case GuardRedirect(:final route):
            current = route;
            redirectCount++;
            redirected = true;
        }
        if (redirected) break;
      }
      if (redirected) continue;
      return current;
    }

    throw const FlowRedirectLoopException('Maximum redirect depth exceeded');
  }

  List<FlowGuard> _collectRouteGuards(RouteMatchChain chain) {
    return chain.matches.expand((m) => m.definition.guards).toList();
  }

  bool canPop({NavigatorId navigatorId = NavigatorId.root}) {
    final overlay = _state.overlayFor(navigatorId.value);
    if (!overlay.isEmpty) return true;
    if (_state.locationChain.matches.length > 1) return true;
    return _history.canGoBack;
  }

  void _applyState(NavigationState next) {
    _isApplyingState = true;
    _state = next;
    notifyListeners();
    scheduleMicrotask(() => _isApplyingState = false);
  }

  void setState(NavigationState state) {
    _applyState(state);
  }
}
