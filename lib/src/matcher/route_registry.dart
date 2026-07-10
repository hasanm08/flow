import '../matcher/match_engine.dart';
import '../matcher/route_match.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';

/// Central registry of all route definitions.
final class RouteRegistry {
  RouteRegistry({
    required List<FlowRouteNode> routes,
    this.initialLocation = '/',
  }) : _nodes = routes,
       _engine = MatchEngine(routes),
       _definitionsByName = _buildDefinitionIndex(routes);

  final List<FlowRouteNode> _nodes;
  final MatchEngine _engine;
  final Map<String, FlowRouteDefinition> _definitionsByName;
  final String initialLocation;

  List<FlowRouteNode> get nodes => List.unmodifiable(_nodes);
  MatchEngine get engine => _engine;

  FlowRouteDefinition? findDefinitionByName(String name) =>
      _definitionsByName[name];

  /// Fast path for typed navigation — O(1) definition lookup + leaf match.
  MatchResult? matchTypedRoute(FlowRoute route) {
    final definition = findDefinitionByName(route.name);
    if (definition == null) return null;
    return _engine.matchLeaf(definition, route);
  }

  static Map<String, FlowRouteDefinition> _buildDefinitionIndex(
    List<FlowRouteNode> nodes,
  ) {
    final index = <String, FlowRouteDefinition>{};
    void walk(List<FlowRouteNode> current) {
      for (final node in current) {
        switch (node) {
          case FlowLeafNode(:final definition):
            index[definition.name] = definition;
          case FlowShellNode(:final children):
            walk(children);
          case FlowStatefulShellNode(:final branches):
            for (final branch in branches) {
              walk(branch.children);
            }
          case FlowBranchNode(:final children):
            walk(children);
        }
      }
    }

    walk(nodes);
    return index;
  }
}
