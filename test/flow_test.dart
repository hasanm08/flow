import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flow_routing/src/core/flow_route_information_parser.dart';
import 'package:flow_routing/src/matcher/match_engine.dart';
import 'package:flow_routing/src/matcher/route_registry.dart';
import 'package:flow_routing/src/navigation/navigation_engine.dart';
import 'package:flow_routing/src/typed_routes/flow_route.dart';
import 'package:flow_routing/src/typed_routes/flow_route_definition.dart';
import 'package:flow_routing/src/web/platform_location.dart';

void main() {
  group('LocationBuilder', () {
    test('builds path from typed route', () {
      expect(const UserRoute(id: 42).location, '/users/42');
    });

    test('builds path with query parameters', () {
      expect(
        const UserRoute(id: 5, tab: 'profile').location,
        '/users/5?tab=profile',
      );
    });
  });

  group('MatchEngine', () {
    late MatchEngine engine;

    setUp(() {
      engine = MatchEngine([
        FlowLeafNode(_homeDefinition),
        FlowLeafNode(_userDefinition),
        FlowLeafNode(_settingsDefinition),
      ]);
    });

    test('matches root path', () {
      final result = engine.match(Uri.parse('/'));
      expect(result.isError, isTrue);
    });

    test('matches home path', () {
      final result = engine.match(Uri.parse('/home'));
      expect(result.isError, isFalse);
      expect(result.chain.leaf?.route, isA<HomeRoute>());
    });

    test('matches parameterized path', () {
      final result = engine.match(Uri.parse('/users/99'));
      expect(result.isError, isFalse);
      final route = result.chain.leaf!.route as UserRoute;
      expect(route.id, 99);
    });

    test('returns error for unknown path', () {
      final result = engine.match(Uri.parse('/unknown'));
      expect(result.isError, isTrue);
    });
  });

  group('NavigationEngine', () {
    test('resolveInitialLocation falls back to default for bare root', () {
      expect(resolveInitialLocation(defaultLocation: '/home'), '/home');
    });

    test('parseRouteInformation handles explore deep link', () async {
      final registry = RouteRegistry(
        routes: [
          FlowLeafNode(_homeDefinition),
          FlowLeafNode(_exploreDefinition),
        ],
      );
      final engine = NavigationEngine(registry: registry, initialLocation: '/home');
      final parser = FlowRouteInformationParser(engine: engine);
      final state = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/explore')),
      );
      expect(state.location, '/explore');
    });

    test('restoreRouteInformation reflects navigation location', () async {
      final registry = RouteRegistry(
        routes: [
          FlowLeafNode(_homeDefinition),
          FlowLeafNode(_exploreDefinition),
        ],
        initialLocation: '/home',
      );
      final navEngine = NavigationEngine(
        registry: registry,
        initialLocation: '/home',
      );
      final parser = FlowRouteInformationParser(engine: navEngine);

      expect(
        parser.restoreRouteInformation(navEngine.state).uri.path,
        '/home',
      );

      await navEngine.dispatch(const GoIntent(ExploreRoute()));
      expect(
        parser.restoreRouteInformation(navEngine.state).uri.path,
        '/explore',
      );
    });

    late NavigationEngine engine;

    setUp(() {
      final registry = RouteRegistry(
        routes: [
          FlowLeafNode(_homeDefinition),
          FlowLeafNode(_userDefinition),
          FlowLeafNode(_settingsDefinition),
        ],
      );
      engine = NavigationEngine(registry: registry);
    });

    test('go replaces location stack', () async {
      await engine.dispatch(const GoIntent(UserRoute(id: 1)));
      expect(engine.state.location, '/users/1');
      await engine.dispatch(const GoIntent(SettingsRoute()));
      expect(engine.state.location, '/settings');
    });

    test('push adds overlay without changing location', () async {
      await engine.dispatch(const GoIntent(HomeRoute()));
      await engine.dispatch(const PushIntent(SettingsRoute()));
      expect(engine.state.location, '/home');
      expect(engine.state.overlayFor('root').entries.length, 1);
    });

    test('pop removes overlay first', () async {
      await engine.dispatch(const GoIntent(HomeRoute()));
      await engine.dispatch(const PushIntent(SettingsRoute()));
      await engine.dispatch(const PopIntent());
      expect(engine.state.overlayFor('root').isEmpty, isTrue);
    });

    test('pop uses history when stack has single route', () async {
      await engine.dispatch(const GoIntent(HomeRoute()));
      await engine.dispatch(const GoIntent(UserRoute(id: 1)));
      expect(engine.state.location, '/users/1');
      await engine.dispatch(const PopIntent());
      expect(engine.state.location, '/home');
    });

    test('replace updates query parameters on route', () async {
      await engine.dispatch(const GoIntent(UserRoute(id: 1)));
      await engine.dispatch(
        const ReplaceIntent(UserRoute(id: 1, tab: 'activity')),
      );
      final route = engine.state.locationChain.leaf!.route as UserRoute;
      expect(route.tab, 'activity');
      expect(engine.state.location, '/users/1?tab=activity');
    });
  });

  group('FakeFlowRouter', () {
    test('records navigation intents', () async {
      final fake = FakeFlowRouter();
      await fake.go(const HomeRoute());
      await fake.push(const UserRoute(id: 3));
      expect(fake.hasGoIntents, isTrue);
      expect(fake.hasPushIntents, isTrue);
      expect(fake.intents.length, 2);
    });
  });

  group('goRouterPathToDefinition', () {
    test('normalizes paths', () {
      expect(migrateGoRouterPath('users'), '/users');
      expect(migrateGoRouterPath('/users/'), '/users');
    });
  });
}

// Test routes
final class HomeRoute extends FlowRoute {
  const HomeRoute();
  @override
  String get name => 'home';
  @override
  String get pathTemplate => '/home';
}

final class UserRoute extends FlowRoute {
  const UserRoute({required this.id, this.tab = 'overview'});
  final int id;
  final String tab;

  @override
  String get name => 'user';
  @override
  String get pathTemplate => '/users/:id';
  @override
  Map<String, String> get pathParameters => {'id': '$id'};
  @override
  Map<String, String> get queryParameters =>
      tab == 'overview' ? const {} : {'tab': tab};
}

final class SettingsRoute extends FlowRoute {
  const SettingsRoute();
  @override
  String get name => 'settings';
  @override
  String get pathTemplate => '/settings';
}

final class ExploreRoute extends FlowRoute {
  const ExploreRoute();
  @override
  String get name => 'explore';
  @override
  String get pathTemplate => '/explore';
}

final _homeDefinition = FlowRouteDefinition<HomeRoute>(
  name: 'home',
  pathTemplate: '/home',
  builder: (context, route) => const SizedBox.shrink(),
  factory: (_) => const HomeRoute(),
);

final _userDefinition = FlowRouteDefinition<UserRoute>(
  name: 'user',
  pathTemplate: '/users/:id',
  builder: (context, route) => const SizedBox.shrink(),
  factory: (params) => UserRoute(id: int.parse(params['id']!)),
);

final _settingsDefinition = FlowRouteDefinition<SettingsRoute>(
  name: 'settings',
  pathTemplate: '/settings',
  builder: (context, route) => const SizedBox.shrink(),
  factory: (_) => const SettingsRoute(),
);

final _exploreDefinition = FlowRouteDefinition<ExploreRoute>(
  name: 'explore',
  pathTemplate: '/explore',
  builder: (context, route) => const SizedBox.shrink(),
  factory: (_) => const ExploreRoute(),
);
