import 'package:flow_routing/flow_routing.dart';

/// Benchmark route matching performance.
///
/// Run: `flutter test test/match_benchmark_test.dart`
/// Or this script: `flutter run benchmark/match_benchmark.dart` (requires Flutter)
void main() {
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

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    engine.match(Uri.parse('/section/42/item/99'));
  }
  stopwatch.stop();

  final usPerOp = stopwatch.elapsedMicroseconds / iterations;
  // ignore: avoid_print
  print(
    'Flow MatchEngine: ${usPerOp.toStringAsFixed(2)} µs/op ($iterations iterations)',
  );
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
