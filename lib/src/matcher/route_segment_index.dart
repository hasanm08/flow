import '../typed_routes/flow_route_definition.dart';
import 'path_pattern.dart';

/// Precomputed index that narrows leaf-route candidates by the first path segment.
///
/// Shell and branch nodes are always included; literal-prefix leaves are keyed
/// by their first segment so matching skips unrelated routes.
final class RouteSegmentIndex {
  RouteSegmentIndex._({
    required this.structural,
    required this.rootLeaves,
    required this.dynamicLeaves,
    required this.byFirstLiteral,
  });

  factory RouteSegmentIndex.build(List<FlowRouteNode> nodes) {
    final structural = <FlowRouteNode>[];
    final rootLeaves = <FlowRouteNode>[];
    final dynamicLeaves = <FlowRouteNode>[];
    final byFirstLiteral = <String, List<FlowRouteNode>>{};

    for (final node in nodes) {
      switch (node) {
        case FlowLeafNode(:final definition):
          final segments = definition.pattern.segments;
          if (segments.isEmpty) {
            rootLeaves.add(node);
            continue;
          }
          switch (segments.first) {
            case LiteralSegment(:final value):
              (byFirstLiteral[value] ??= []).add(node);
            case PathParamSegment():
            case WildcardSegment():
              dynamicLeaves.add(node);
          }
        default:
          structural.add(node);
      }
    }

    return RouteSegmentIndex._(
      structural: structural,
      rootLeaves: rootLeaves,
      dynamicLeaves: dynamicLeaves,
      byFirstLiteral: byFirstLiteral,
    );
  }

  final List<FlowRouteNode> structural;
  final List<FlowRouteNode> rootLeaves;
  final List<FlowRouteNode> dynamicLeaves;
  final Map<String, List<FlowRouteNode>> byFirstLiteral;

  /// Returns nodes to evaluate at [segmentIndex], ordered for correctness.
  List<FlowRouteNode> candidates(int segmentIndex, List<String> segments) {
    final result = <FlowRouteNode>[...structural];

    if (segmentIndex >= segments.length) {
      result.addAll(rootLeaves);
    } else {
      final decoded = Uri.decodeComponent(segments[segmentIndex]);
      final literalMatches = byFirstLiteral[decoded];
      if (literalMatches != null) {
        result.addAll(literalMatches);
      }
    }

    result.addAll(dynamicLeaves);
    return result;
  }
}

/// Builds a [RouteSegmentIndex] for every node list in the route tree.
Map<List<FlowRouteNode>, RouteSegmentIndex> buildRouteSegmentIndexCache(
  List<FlowRouteNode> root,
) {
  final cache = <List<FlowRouteNode>, RouteSegmentIndex>{};

  void walk(List<FlowRouteNode> nodes) {
    if (cache.containsKey(nodes)) return;
    cache[nodes] = RouteSegmentIndex.build(nodes);
    for (final node in nodes) {
      switch (node) {
        case FlowShellNode(:final children):
          walk(children);
        case FlowStatefulShellNode(:final branches):
          for (final branch in branches) {
            walk(branch.children);
          }
        case FlowBranchNode(:final children):
          walk(children);
        default:
          break;
      }
    }
  }

  walk(root);
  return cache;
}
