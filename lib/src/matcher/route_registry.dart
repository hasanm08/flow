import '../guards/flow_guard.dart';
import '../matcher/match_engine.dart';
import '../matcher/route_match.dart';
import '../typed_routes/flow_route_definition.dart';

/// Central registry of all route definitions.
final class RouteRegistry {
  RouteRegistry({
    required List<FlowRouteNode> routes,
    this.initialLocation = '/',
  }) : _nodes = routes,
       _engine = MatchEngine(routes);

  final List<FlowRouteNode> _nodes;
  final MatchEngine _engine;
  final String initialLocation;

  List<FlowRouteNode> get nodes => List.unmodifiable(_nodes);
  MatchEngine get engine => _engine;

  FlowRouteDefinition? findDefinitionByName(String name) {
    return _findDefinition(_nodes, name);
  }

  FlowRouteDefinition? _findDefinition(List<FlowRouteNode> nodes, String name) {
    for (final node in nodes) {
      switch (node) {
        case FlowLeafNode(:final definition):
          if (definition.name == name) return definition;
        case FlowShellNode(:final children):
          final found = _findDefinition(children, name);
          if (found != null) return found;
        case FlowStatefulShellNode(:final branches):
          for (final branch in branches) {
            final found = _findDefinition(branch.children, name);
            if (found != null) return found;
          }
        case FlowBranchNode(:final children):
          final found = _findDefinition(children, name);
          if (found != null) return found;
      }
    }
    return null;
  }
}
