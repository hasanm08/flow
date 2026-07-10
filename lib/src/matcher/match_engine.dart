import '../parser/uri_normalizer.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';
import '../typed_routes/location_builder.dart';
import 'path_pattern.dart';
import 'route_match.dart';
import 'route_segment_index.dart';

/// Efficient segment-based route matching engine.
final class MatchEngine {
  MatchEngine(this._nodes)
    : _trieIndexes = buildRouteTrieIndexCache(_nodes);

  final List<FlowRouteNode> _nodes;
  final Map<List<FlowRouteNode>, RouteTrieIndex> _trieIndexes;

  // Reusable scratch buffers — zero per-match list/map allocation.
  final List<RouteMatch> _matches = [];
  final List<ShellMatch> _shellMatches = [];
  final List<FlowRouteNode> _candidates = [];
  final Map<String, String> _params = {};
  final Map<String, String> _pathParams = {};

  MatchResult match(Uri rawUri) {
    final uri = UriNormalizer.normalize(rawUri);
    final segments = UriNormalizer.pathSegments(uri);

    _matches.clear();
    _shellMatches.clear();

    final result = _matchNodes(
      _nodes,
      segments,
      0,
      '',
      0,
      uri.hasQuery ? uri.queryParameters : const {},
    );

    if (result == null) {
      return MatchResult(
        chain: RouteMatchChain(matches: const [], uri: uri),
        error: 'No route matches location: ${uri.path}',
      );
    }

    return MatchResult(
      chain: RouteMatchChain(
        matches: List.unmodifiable(_matches),
        shellMatches: List.unmodifiable(_shellMatches),
        uri: uri,
        activeBranchIndex: result,
      ),
    );
  }

  /// Fast path for typed navigation — skips full tree scan.
  MatchResult matchLeaf(
    FlowRouteDefinition definition,
    FlowRoute route, {
    Map<String, String>? queryParameters,
  }) {
    final location = route.location;
    final uri = Uri.parse(location);
    final pathParams = route.pathParameters;
    final matchedLocation = LocationBuilder.pathOnly(
      definition.pattern,
      pathParams,
    );

    final match = RouteMatch(
      route: route,
      definition: definition,
      pathParameters: pathParams,
      matchedLocation: matchedLocation,
    );

    return MatchResult(
      chain: RouteMatchChain(
        matches: [match],
        uri: queryParameters != null && queryParameters.isNotEmpty
            ? uri.replace(queryParameters: queryParameters)
            : uri,
      ),
    );
  }

  MatchResult matchRoute(FlowRouteDefinition definition, FlowRoute route) =>
      matchLeaf(definition, route);

  int? _matchNodes(
    List<FlowRouteNode> nodes,
    List<String> segments,
    int segmentIndex,
    String locationPrefix,
    int branchIndex,
    Map<String, String> queryParams,
  ) {
    final index = _trieIndexes[nodes];
    if (index != null) {
      index.collectCandidates(segmentIndex, segments, _candidates);
    } else {
      _candidates
        ..clear()
        ..addAll(nodes);
    }

    for (final node in _candidates) {
      switch (node) {
        case FlowLeafNode(:final definition):
          final match = _matchPattern(
            definition.pattern,
            segments,
            segmentIndex,
          );
          if (match != null) {
            final consumed = match.$2;
            if (consumed == segments.length - segmentIndex) {
              final params = match.$1;
              _mergeParams(params, queryParams);
              final route = definition.factory(_params);
              _matches.add(
                RouteMatch(
                  route: route,
                  definition: definition,
                  pathParameters: Map.unmodifiable(params),
                  matchedLocation: LocationBuilder.pathOnly(
                    definition.pattern,
                    params,
                  ),
                ),
              );
              return branchIndex;
            }
          }
        case FlowShellNode(:final pattern, :final navigatorId, :final children):
          final match = _matchPattern(pattern, segments, segmentIndex);
          if (match != null) {
            final params = match.$1;
            final consumed = match.$2;
            final shellLocation = LocationBuilder.pathOnly(pattern, params);
            _shellMatches.add(
              ShellMatch(
                pathTemplate: node.pathTemplate,
                navigatorId: navigatorId.value,
                matchedLocation: shellLocation,
              ),
            );
            final childResult = _matchNodes(
              children,
              segments,
              segmentIndex + consumed,
              shellLocation,
              branchIndex,
              queryParams,
            );
            if (childResult != null) return childResult;
            if (_matches.isNotEmpty) {
              _matches.removeLast();
            }
            if (_shellMatches.isNotEmpty) {
              _shellMatches.removeLast();
            }
          }
        case FlowStatefulShellNode(:final pattern, :final branches):
          final match = _matchPattern(pattern, segments, segmentIndex);
          if (match != null) {
            final params = match.$1;
            final consumed = match.$2;
            final shellLocation = LocationBuilder.pathOnly(pattern, params);
            for (var i = 0; i < branches.length; i++) {
              final branch = branches[i];
              final childResult = _matchNodes(
                branch.children,
                segments,
                segmentIndex + consumed,
                shellLocation,
                i,
                queryParams,
              );
              if (childResult != null) {
                _shellMatches.add(
                  ShellMatch(
                    pathTemplate: node.pathTemplate,
                    navigatorId: branch.navigatorId.value,
                    matchedLocation: shellLocation,
                    isStateful: true,
                    branchIndex: i,
                  ),
                );
                return i;
              }
              _matches.clear();
            }
          }
        case FlowBranchNode():
          break;
      }
    }
    return null;
  }

  void _mergeParams(
    Map<String, String> pathParams,
    Map<String, String> queryParams,
  ) {
    _params
      ..clear()
      ..addAll(pathParams);
    if (queryParams.isNotEmpty) {
      _params.addAll(queryParams);
    }
  }

  (Map<String, String>, int)? _matchPattern(
    PathPattern pattern,
    List<String> segments,
    int start,
  ) {
    _pathParams.clear();
    var segIndex = start;
    var patIndex = 0;

    while (patIndex < pattern.segments.length) {
      final patSeg = pattern.segments[patIndex];

      switch (patSeg) {
        case LiteralSegment(:final value):
          if (segIndex >= segments.length) return null;
          final segment = segments[segIndex];
          final decoded = segment.contains('%')
              ? Uri.decodeComponent(segment)
              : segment;
          if (decoded != value) return null;
          segIndex++;
          patIndex++;
        case PathParamSegment(:final name, :final optional):
          if (segIndex < segments.length) {
            final segment = segments[segIndex];
            _pathParams[name] = segment.contains('%')
                ? Uri.decodeComponent(segment)
                : segment;
            segIndex++;
            patIndex++;
          } else if (optional) {
            patIndex++;
          } else {
            return null;
          }
        case WildcardSegment():
          return (
            Map.unmodifiable(Map<String, String>.from(_pathParams)),
            segments.length - start,
          );
      }
    }

    if (segIndex != segments.length) return null;
    return (
      Map.unmodifiable(Map<String, String>.from(_pathParams)),
      segIndex - start,
    );
  }
}
