import 'package:flow_routing/flow_routing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance benchmarks for high-FPS routing targets.
void main() {
  group('MatchEngine benchmarks', () {
    test('resolves among 100 routes at scale', () {
      final routes = List.generate(100, (i) {
        return flow(
          '/section/$i/item/:id',
          name: 'route_$i',
          builder: (_, _) => throw UnimplementedError(),
        );
      });

      final engine = MatchEngine(routes);
      const iterations = 10000;

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        final result = engine.match(Uri.parse('/section/42/item/99'));
        expect(result.isError, isFalse);
      }
      stopwatch.stop();

      final usPerOp = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print(
        'MatchEngine: ${usPerOp.toStringAsFixed(2)} µs/op ($iterations iterations)',
      );
      expect(usPerOp, lessThan(50));
    });

    test('typed leaf match is faster than full scan', () {
      final routes = List.generate(100, (i) {
        return flow(
          '/section/$i/item/:id',
          name: 'route_$i',
          builder: (_, _) => throw UnimplementedError(),
        );
      });

      final registry = RouteRegistry(routes: routes);
      const route = FlowRoute(
        name: 'route_42',
        pathTemplate: '/section/42/item/:id',
        pathParameters: {'id': '99'},
      );
      const iterations = 10000;

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        registry.matchTypedRoute(route);
      }
      stopwatch.stop();

      final usPerOp = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print(
        'matchTypedRoute: ${usPerOp.toStringAsFixed(2)} µs/op ($iterations iterations)',
      );
      expect(usPerOp, lessThan(10));
    });
  });

  group('NavigationEngine benchmarks', () {
    test('go dispatch with typed fast path', () async {
      final registry = RouteRegistry(routes: [_homeNode, _userNode]);
      final engine = NavigationEngine(registry: registry);
      const iterations = 1000;

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        await engine.dispatch(GoIntent(Routes.user(id: i % 50)));
      }
      stopwatch.stop();

      final usPerOp = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print(
        'GoIntent dispatch: ${usPerOp.toStringAsFixed(2)} µs/op ($iterations iterations)',
      );
      expect(usPerOp, lessThan(500));
    });
  });

  test('RouteTrieIndex preserves match correctness', () {
    final engine = MatchEngine([_homeNode, _userNode, _settingsNode]);

    expect(engine.match(Uri.parse('/home')).isError, isFalse);
    expect(engine.match(Uri.parse('/users/7')).isError, isFalse);
    expect(engine.match(Uri.parse('/settings')).isError, isFalse);
    expect(engine.match(Uri.parse('/unknown')).isError, isTrue);
  });
}

abstract final class Routes {
  static FlowRoute user({required int id}) => FlowRoute(
    name: 'user',
    pathTemplate: '/users/:id',
    pathParameters: {'id': '$id'},
  );
}

final _homeNode = flow(
  '/home',
  name: 'home',
  builder: (_, _) => throw UnimplementedError(),
);

final _userNode = flow(
  '/users/:id',
  name: 'user',
  builder: (_, _) => throw UnimplementedError(),
);

final _settingsNode = flow(
  '/settings',
  name: 'settings',
  builder: (_, _) => throw UnimplementedError(),
);
