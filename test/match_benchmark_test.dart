import 'package:flow_routing/flow_routing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Benchmark-style stress test for route matching performance.
///
/// Run: `flutter test test/match_benchmark_test.dart`
void main() {
  test('MatchEngine resolves among 100 routes at scale', () {
    final routes = List.generate(100, (i) {
      return FlowLeafNode(
        FlowRouteDefinition<_BenchRoute>(
          name: 'route_$i',
          pathTemplate: '/section/$i/item/:id',
          builder: (_, _) => throw UnimplementedError(),
          factory: (params) => _BenchRoute(id: int.parse(params['id']!)),
        ),
      );
    });

    final engine = MatchEngine(routes);
    const iterations = 10000;

    for (var i = 0; i < iterations; i++) {
      final result = engine.match(Uri.parse('/section/42/item/99'));
      expect(result.isError, isFalse);
      expect((result.chain.leaf!.route as _BenchRoute).id, 99);
    }
  });

  test('RouteSegmentIndex preserves match correctness', () {
    final engine = MatchEngine([
      FlowLeafNode(_homeDefinition),
      FlowLeafNode(_userDefinition),
      FlowLeafNode(_settingsDefinition),
    ]);

    expect(engine.match(Uri.parse('/home')).isError, isFalse);
    expect(engine.match(Uri.parse('/users/7')).isError, isFalse);
    expect(engine.match(Uri.parse('/settings')).isError, isFalse);
    expect(engine.match(Uri.parse('/unknown')).isError, isTrue);
  });
}

final class _BenchRoute extends FlowRoute {
  const _BenchRoute({required this.id});
  final int id;
  @override
  String get name => 'bench';
  @override
  String get pathTemplate => '/section/:section/item/:id';
  @override
  Map<String, String> get pathParameters => {'id': '$id'};
}

final class _HomeRoute extends FlowRoute {
  const _HomeRoute();
  @override
  String get name => 'home';
  @override
  String get pathTemplate => '/home';
}

final class _UserRoute extends FlowRoute {
  const _UserRoute({required this.id});
  final int id;
  @override
  String get name => 'user';
  @override
  String get pathTemplate => '/users/:id';
  @override
  Map<String, String> get pathParameters => {'id': '$id'};
}

final class _SettingsRoute extends FlowRoute {
  const _SettingsRoute();
  @override
  String get name => 'settings';
  @override
  String get pathTemplate => '/settings';
}

final _homeDefinition = FlowRouteDefinition<_HomeRoute>(
  name: 'home',
  pathTemplate: '/home',
  builder: (_, _) => throw UnimplementedError(),
  factory: (_) => const _HomeRoute(),
);

final _userDefinition = FlowRouteDefinition<_UserRoute>(
  name: 'user',
  pathTemplate: '/users/:id',
  builder: (_, _) => throw UnimplementedError(),
  factory: (params) => _UserRoute(id: int.parse(params['id']!)),
);

final _settingsDefinition = FlowRouteDefinition<_SettingsRoute>(
  name: 'settings',
  pathTemplate: '/settings',
  builder: (_, _) => throw UnimplementedError(),
  factory: (_) => const _SettingsRoute(),
);
