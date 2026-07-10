import '../typed_routes/flow_route_definition.dart';
import 'path_pattern.dart';

/// Multi-level radix trie that narrows route candidates per URL segment.
///
/// Replaces flat first-segment indexing — O(depth) lookup instead of O(routes)
/// for apps with shared path prefixes (e.g. `/section/42/item/:id`).
final class RouteTrieIndex {
  RouteTrieIndex._({
    required this.structural,
    required this._root,
    required this.rootLeaves,
  });

  factory RouteTrieIndex.build(List<FlowRouteNode> nodes) {
    final structural = <FlowRouteNode>[];
    final rootLeaves = <FlowLeafNode>[];
    final trieRoot = _TrieNode();

    for (final node in nodes) {
      switch (node) {
        case final FlowLeafNode leaf:
          if (leaf.definition.pattern.segments.isEmpty) {
            rootLeaves.add(leaf);
          } else {
            _insertLeaf(trieRoot, leaf, 0);
          }
        default:
          structural.add(node);
      }
    }

    return RouteTrieIndex._(
      structural: structural,
      root: trieRoot,
      rootLeaves: rootLeaves,
    );
  }

  final List<FlowRouteNode> structural;
  final _TrieNode _root;
  final List<FlowLeafNode> rootLeaves;

  /// Fills [out] with candidate nodes at [segmentIndex]. Reuses [out] buffer.
  void collectCandidates(
    int segmentIndex,
    List<String> segments,
    List<FlowRouteNode> out,
  ) {
    out
      ..clear()
      ..addAll(structural);

    if (segmentIndex >= segments.length) {
      out.addAll(rootLeaves);
      _collectTerminals(_root, out);
      return;
    }

    final decoded = _decodeSegment(segments[segmentIndex]);
    final literalChild = _root.literals[decoded];
    if (literalChild != null) {
      _walkLiteral(literalChild, segmentIndex + 1, segments, out);
    }

    out.addAll(_root.paramLeaves);
    out.addAll(_root.wildcardLeaves);
  }

  static void _insertLeaf(_TrieNode node, FlowLeafNode leaf, int patIndex) {
    final segments = leaf.definition.pattern.segments;
    if (patIndex >= segments.length) {
      node.terminal = leaf;
      return;
    }

    switch (segments[patIndex]) {
      case LiteralSegment(:final value):
        final child = node.literals.putIfAbsent(value, _TrieNode.new);
        _insertLeaf(child, leaf, patIndex + 1);
      case PathParamSegment():
        node.paramLeaves.add(leaf);
      case WildcardSegment():
        node.wildcardLeaves.add(leaf);
    }
  }

  static void _walkLiteral(
    _TrieNode node,
    int segmentIndex,
    List<String> segments,
    List<FlowRouteNode> out,
  ) {
    if (segmentIndex >= segments.length) {
      _collectTerminals(node, out);
      return;
    }

    final decoded = _decodeSegment(segments[segmentIndex]);
    final literalChild = node.literals[decoded];
    if (literalChild != null) {
      _walkLiteral(literalChild, segmentIndex + 1, segments, out);
    }

    out.addAll(node.paramLeaves);
    out.addAll(node.wildcardLeaves);
  }

  static void _collectTerminals(_TrieNode node, List<FlowRouteNode> out) {
    if (node.terminal != null) out.add(node.terminal!);
  }

  static String _decodeSegment(String segment) {
    return segment.contains('%')
        ? Uri.decodeComponent(segment)
        : segment;
  }
}

final class _TrieNode {
  FlowLeafNode? terminal;
  final Map<String, _TrieNode> literals = {};
  final List<FlowLeafNode> paramLeaves = [];
  final List<FlowLeafNode> wildcardLeaves = [];
}

/// Builds a [RouteTrieIndex] for every node list in the route tree.
Map<List<FlowRouteNode>, RouteTrieIndex> buildRouteTrieIndexCache(
  List<FlowRouteNode> root,
) {
  final cache = <List<FlowRouteNode>, RouteTrieIndex>{};

  void walk(List<FlowRouteNode> nodes) {
    if (cache.containsKey(nodes)) return;
    cache[nodes] = RouteTrieIndex.build(nodes);
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

// Keep legacy name for internal references during transition.
typedef RouteSegmentIndex = RouteTrieIndex;
Map<List<FlowRouteNode>, RouteTrieIndex> buildRouteSegmentIndexCache(
  List<FlowRouteNode> root,
) => buildRouteTrieIndexCache(root);
