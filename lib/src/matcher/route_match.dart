import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';

/// A single matched route in the navigation tree.
final class RouteMatch {
  const RouteMatch({
    required this.route,
    required this.definition,
    required this.pathParameters,
    required this.matchedLocation,
    this.shellNavigatorId,
  });

  final FlowRoute route;
  final FlowRouteDefinition definition;
  final Map<String, String> pathParameters;
  final String matchedLocation;
  final String? shellNavigatorId;

  RouteMatch copyWithRoute(FlowRoute route) {
    return RouteMatch(
      route: route,
      definition: definition,
      pathParameters: route.pathParameters,
      matchedLocation: route.location.split('?').first,
      shellNavigatorId: shellNavigatorId,
    );
  }
}

/// Ordered chain of matches from root to leaf.
final class RouteMatchChain {
  const RouteMatchChain({
    required this.matches,
    required this.uri,
    this.shellMatches = const [],
    this.activeBranchIndex = 0,
  });

  final List<RouteMatch> matches;
  final List<ShellMatch> shellMatches;
  final Uri uri;
  final int activeBranchIndex;

  bool get isEmpty => matches.isEmpty;
  RouteMatch? get leaf => matches.isEmpty ? null : matches.last;

  RouteMatchChain copyWith({
    List<RouteMatch>? matches,
    Uri? uri,
    List<ShellMatch>? shellMatches,
    int? activeBranchIndex,
  }) {
    return RouteMatchChain(
      matches: matches ?? this.matches,
      uri: uri ?? this.uri,
      shellMatches: shellMatches ?? this.shellMatches,
      activeBranchIndex: activeBranchIndex ?? this.activeBranchIndex,
    );
  }
}

/// Applies a typed [route] to the leaf of [chain] and updates the URI.
RouteMatchChain applyRouteToChain(RouteMatchChain chain, FlowRoute route) {
  if (chain.matches.isEmpty) return chain;
  final matches = List<RouteMatch>.from(chain.matches);
  matches[matches.length - 1] = matches.last.copyWithRoute(route);
  return chain.copyWith(matches: matches, uri: Uri.parse(route.location));
}

/// Match for a shell route in the tree.
final class ShellMatch {
  const ShellMatch({
    required this.pathTemplate,
    required this.navigatorId,
    required this.matchedLocation,
    this.isStateful = false,
    this.branchIndex = 0,
  });

  final String pathTemplate;
  final String navigatorId;
  final String matchedLocation;
  final bool isStateful;
  final int branchIndex;
}

/// Result of matching a URI against the route registry.
final class MatchResult {
  const MatchResult({required this.chain, this.error});

  final RouteMatchChain chain;
  final String? error;

  bool get isError => error != null;
}
