import 'package:flow/flow.dart';
import 'package:flow/src/matcher/match_engine.dart';
import 'package:flow/src/typed_routes/flow_route.dart';
import 'package:flow/src/typed_routes/flow_route_definition.dart';

/// Benchmark route matching performance.
///
/// Run: `dart run benchmark/match_benchmark.dart`
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
  print('Flow MatchEngine: ${usPerOp.toStringAsFixed(2)} µs/op ($iterations iterations)');
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
