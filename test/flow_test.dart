import 'package:flow_routing/flow_routing.dart';
import 'package:flow_routing/src/core/flow_route_information_parser.dart';
import 'package:flow_routing/src/web/platform_location.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationBuilder', () {
    test('builds path from typed route', () {
      expect(Routes.user(id: 42).location, '/users/42');
    });

    test('builds path with query parameters', () {
      expect(
        Routes.user(id: 5, tab: UserTab.activity).location,
        '/users/5?tab=activity',
      );
    });
  });

  group('MatchEngine', () {
    late MatchEngine engine;

    setUp(() {
      engine = MatchEngine([_homeNode, _userNode, _settingsNode]);
    });

    test('matches root path', () {
      final result = engine.match(Uri.parse('/'));
      expect(result.isError, isTrue);
    });

    test('matches home path', () {
      final result = engine.match(Uri.parse('/home'));
      expect(result.isError, isFalse);
      expect(result.chain.leaf?.route.name, 'home');
    });

    test('matches parameterized path', () {
      final result = engine.match(Uri.parse('/users/99'));
      expect(result.isError, isFalse);
      expect(result.chain.leaf!.route.intPathParam('id'), 99);
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
      final registry = RouteRegistry(routes: [_homeNode, _exploreNode]);
      final engine = NavigationEngine(
        registry: registry,
        initialLocation: '/home',
      );
      final parser = FlowRouteInformationParser(engine: engine);
      final state = await parser.parseRouteInformation(
        RouteInformation(uri: Uri.parse('/explore')),
      );
      expect(state.location, '/explore');
    });

    test('restoreRouteInformation reflects navigation location', () async {
      final registry = RouteRegistry(
        routes: [_homeNode, _exploreNode],
        initialLocation: '/home',
      );
      final navEngine = NavigationEngine(
        registry: registry,
        initialLocation: '/home',
      );
      final parser = FlowRouteInformationParser(engine: navEngine);

      expect(parser.restoreRouteInformation(navEngine.state).uri.path, '/home');

      await navEngine.dispatch(const GoIntent(Routes.explore));
      expect(
        parser.restoreRouteInformation(navEngine.state).uri.path,
        '/explore',
      );
    });

    late NavigationEngine engine;

    setUp(() {
      final registry = RouteRegistry(
        routes: [_homeNode, _userNode, _settingsNode],
      );
      engine = NavigationEngine(registry: registry);
    });

    test('go replaces location stack', () async {
      await engine.dispatch(GoIntent(Routes.user(id: 1)));
      expect(engine.state.location, '/users/1');
      await engine.dispatch(const GoIntent(Routes.settings));
      expect(engine.state.location, '/settings');
    });

    test('push adds overlay without changing location', () async {
      await engine.dispatch(const GoIntent(Routes.home));
      await engine.dispatch(const PushIntent(Routes.settings));
      expect(engine.state.location, '/home');
      expect(engine.state.overlayFor('root').entries.length, 1);
    });

    test('pop removes overlay first', () async {
      await engine.dispatch(const GoIntent(Routes.home));
      await engine.dispatch(const PushIntent(Routes.settings));
      await engine.dispatch(const PopIntent());
      expect(engine.state.overlayFor('root').isEmpty, isTrue);
    });

    test('pop uses history when stack has single route', () async {
      await engine.dispatch(const GoIntent(Routes.home));
      await engine.dispatch(GoIntent(Routes.user(id: 1)));
      expect(engine.state.location, '/users/1');
      await engine.dispatch(const PopIntent());
      expect(engine.state.location, '/home');
    });

    test('replace updates query parameters on route', () async {
      await engine.dispatch(GoIntent(Routes.user(id: 1)));
      await engine.dispatch(
        ReplaceIntent(Routes.user(id: 1, tab: UserTab.activity)),
      );
      final route = engine.state.locationChain.leaf!.route;
      expect(route.queryParam('tab'), 'activity');
      expect(engine.state.location, '/users/1?tab=activity');
    });
  });

  group('RouteRegistry', () {
    test('findDefinitionByName resolves registered routes', () {
      final registry = RouteRegistry(routes: [_homeNode, _userNode]);

      expect(registry.findDefinitionByName('home'), isNotNull);
      expect(registry.findDefinitionByName('user'), isNotNull);
      expect(registry.findDefinitionByName('missing'), isNull);
    });
  });

  group('FlowShellNode matching', () {
    late MatchEngine engine;

    setUp(() {
      engine = MatchEngine([
        FlowShellNode(
          pathTemplate: '/app',
          navigatorId: const NavigatorId('shell'),
          builder: (context, child) => child,
          children: [
            flow(
              '/home',
              name: 'shell-home',
              builder: (context, route) => const SizedBox.shrink(),
            ),
            flow(
              '/settings',
              name: 'shell-settings',
              builder: (context, route) => const SizedBox.shrink(),
            ),
          ],
        ),
      ]);
    });

    test('records shell match with builder node', () {
      final result = engine.match(Uri.parse('/app/home'));
      expect(result.isError, isFalse);
      expect(result.chain.leaf?.route.name, 'shell-home');
      expect(result.chain.shellMatches, hasLength(1));
      expect(result.chain.shellMatches.first.shell, isNotNull);
      expect(result.chain.shellMatches.first.pathTemplate, '/app');
    });

    test('matches nested path under shell prefix', () {
      final result = engine.match(Uri.parse('/app/settings'));
      expect(result.isError, isFalse);
      expect(result.chain.leaf?.route.name, 'shell-settings');
      expect(result.chain.shellMatches, hasLength(1));
    });

    test('typed navigation preserves shell matches', () {
      final registry = RouteRegistry(
        routes: [
          FlowShellNode(
            pathTemplate: '/app',
            navigatorId: const NavigatorId('shell'),
            builder: (context, child) => child,
            children: [
              flow(
                '/home',
                name: 'shell-home',
                builder: (context, route) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      );

      expect(registry.fullPathTemplateFor('shell-home'), '/app/home');

      final result = registry.matchTypedRoute(
        const FlowRoute(name: 'shell-home', pathTemplate: '/home'),
      );
      expect(result, isNotNull);
      expect(result!.isError, isFalse);
      expect(result.chain.shellMatches, hasLength(1));
      expect(result.chain.uri.path, '/app/home');
    });
  });

  group('FakeFlowRouter', () {
    test('records navigation intents', () async {
      final fake = FakeFlowRouter();
      await fake.go(Routes.home);
      await fake.push(Routes.user(id: 3));
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

// Test route instances
abstract final class Routes {
  Routes._();

  static const home = FlowRoute(name: 'home', pathTemplate: '/home');
  static const explore = FlowRoute(name: 'explore', pathTemplate: '/explore');
  static const settings = FlowRoute(
    name: 'settings',
    pathTemplate: '/settings',
  );

  static FlowRoute user({required int id, UserTab tab = UserTab.overview}) =>
      FlowRoute(
        name: 'user',
        pathTemplate: '/users/:id',
        pathParameters: {'id': '$id'},
        queryParameters: tab == UserTab.overview ? const {} : {'tab': tab.name},
      );
}

enum UserTab { overview, activity, settings }

final _homeNode = flow(
  '/home',
  name: 'home',
  builder: (context, route) => const SizedBox.shrink(),
);

final _userNode = flow(
  '/users/:id',
  name: 'user',
  builder: (context, route) => const SizedBox.shrink(),
);

final _settingsNode = flow(
  '/settings',
  name: 'settings',
  builder: (context, route) => const SizedBox.shrink(),
);

final _exploreNode = flow(
  '/explore',
  name: 'explore',
  builder: (context, route) => const SizedBox.shrink(),
);
