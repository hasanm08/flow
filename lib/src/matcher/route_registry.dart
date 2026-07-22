import '../matcher/match_engine.dart';
import '../matcher/route_match.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';
import '../typed_routes/location_builder.dart';

/// Central registry of all route definitions.
final class RouteRegistry {
  RouteRegistry({
    required List<FlowRouteNode> routes,
    this.initialLocation = '/',
  }) : _nodes = routes,
       _engine = MatchEngine(routes),
       _definitionsByName = _buildDefinitionIndex(routes),
       _fullPathByName = _buildFullPathIndex(routes),
       _containsShells = _treeContainsShells(routes);

  final List<FlowRouteNode> _nodes;
  final MatchEngine _engine;
  final Map<String, FlowRouteDefinition> _definitionsByName;
  final Map<String, String> _fullPathByName;
  final bool _containsShells;
  final String initialLocation;

  List<FlowRouteNode> get nodes => List.unmodifiable(_nodes);
  MatchEngine get engine => _engine;

  FlowRouteDefinition? findDefinitionByName(String name) =>
      _definitionsByName[name];

  /// Full path template including shell prefixes, e.g. `/app/home`.
  String? fullPathTemplateFor(String name) => _fullPathByName[name];

  /// Typed navigation match — uses full tree match when shells are present
  /// so [RouteMatchChain.shellMatches] (and builders) are preserved.
  MatchResult? matchTypedRoute(FlowRoute route) {
    final definition = findDefinitionByName(route.name);
    if (definition == null) return null;
    if (_containsShells) {
      final fullTemplate = _fullPathByName[route.name] ?? route.pathTemplate;
      final location = LocationBuilder(
        pathTemplate: fullTemplate,
        pathParameters: route.pathParameters,
        queryParameters: route.queryParameters,
        fragment: route.fragment,
      ).build();
      return _engine.match(Uri.parse(location));
    }
    return _engine.matchLeaf(definition, route);
  }

  static bool _treeContainsShells(List<FlowRouteNode> nodes) {
    for (final node in nodes) {
      switch (node) {
        case FlowShellNode():
        case FlowStatefulShellNode():
          return true;
        case FlowBranchNode(:final children):
          if (_treeContainsShells(children)) return true;
        case FlowLeafNode():
          break;
      }
    }
    return false;
  }

  static String _joinPaths(String prefix, String path) {
    if (prefix.isEmpty || prefix == '/') {
      return path.isEmpty ? '/' : (path.startsWith('/') ? path : '/$path');
    }
    if (path.isEmpty || path == '/') return prefix;
    final head = prefix.endsWith('/')
        ? prefix.substring(0, prefix.length - 1)
        : prefix;
    final tail = path.startsWith('/') ? path : '/$path';
    return '$head$tail';
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

  static Map<String, String> _buildFullPathIndex(List<FlowRouteNode> nodes) {
    final index = <String, String>{};
    void walk(List<FlowRouteNode> current, String prefix) {
      for (final node in current) {
        switch (node) {
          case FlowLeafNode(:final definition):
            index[definition.name] = _joinPaths(
              prefix,
              definition.pathTemplate,
            );
          case FlowShellNode(:final pathTemplate, :final children):
            walk(children, _joinPaths(prefix, pathTemplate));
          case FlowStatefulShellNode(:final pathTemplate, :final branches):
            final next = _joinPaths(prefix, pathTemplate);
            for (final branch in branches) {
              walk(branch.children, next);
            }
          case FlowBranchNode(:final children):
            walk(children, prefix);
        }
      }
    }

    walk(nodes, '');
    return index;
  }
}
