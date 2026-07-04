import '../parser/uri_normalizer.dart';
import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';
import 'path_pattern.dart';
import 'route_match.dart';
import 'route_segment_index.dart';

/// Efficient segment-based route matching engine.
final class MatchEngine {
  MatchEngine(this._nodes)
    : _segmentIndexes = buildRouteSegmentIndexCache(_nodes);

  final List<FlowRouteNode> _nodes;
  final Map<List<FlowRouteNode>, RouteSegmentIndex> _segmentIndexes;

  MatchResult match(Uri rawUri) {
    final uri = UriNormalizer.normalize(rawUri);
    final segments = UriNormalizer.pathSegments(uri);
    final queryParams = UriNormalizer.queryParameters(uri);

    final matches = <RouteMatch>[];
    final shellMatches = <ShellMatch>[];
    const branchIndex = 0;

    final result = _matchNodes(
      _nodes,
      segments,
      0,
      matches,
      shellMatches,
      '',
      branchIndex,
      queryParams,
    );

    if (result == null) {
      return MatchResult(
        chain: RouteMatchChain(matches: const [], uri: uri),
        error: 'No route matches location: ${uri.path}',
      );
    }

    return MatchResult(
      chain: RouteMatchChain(
        matches: matches,
        shellMatches: shellMatches,
        uri: uri.replace(queryParameters: queryParams),
        activeBranchIndex: result,
      ),
    );
  }

  MatchResult matchRoute(FlowRouteDefinition definition, FlowRoute route) {
    final uri = Uri.parse(route.location);
    return match(uri);
  }

  int? _matchNodes(
    List<FlowRouteNode> nodes,
    List<String> segments,
    int segmentIndex,
    List<RouteMatch> matches,
    List<ShellMatch> shellMatches,
    String locationPrefix,
    int branchIndex,
    Map<String, String> queryParams,
  ) {
    final index = _segmentIndexes[nodes];
    final candidates = index?.candidates(segmentIndex, segments) ?? nodes;
    for (final node in candidates) {
      switch (node) {
        case FlowLeafNode(:final definition):
          final match = _matchPattern(
            definition.pattern,
            segments,
            segmentIndex,
          );
          if (match != null) {
            final params = match.$1;
            final consumed = match.$2;
            if (consumed == segments.length - segmentIndex) {
              final allParams = {...params, ...queryParams};
              final route = definition.factory(allParams);
              matches.add(
                RouteMatch(
                  route: route,
                  definition: definition,
                  pathParameters: params,
                  matchedLocation: _buildLocation(definition.pattern, params),
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
            final shellLocation = _buildLocation(pattern, params);
            shellMatches.add(
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
              matches,
              shellMatches,
              shellLocation,
              branchIndex,
              queryParams,
            );
            if (childResult != null) return childResult;
            if (matches.isNotEmpty) {
              matches.removeLast();
            }
            if (shellMatches.isNotEmpty) {
              shellMatches.removeLast();
            }
          }
        case FlowStatefulShellNode(:final pattern, :final branches):
          final match = _matchPattern(pattern, segments, segmentIndex);
          if (match != null) {
            final params = match.$1;
            final consumed = match.$2;
            final shellLocation = _buildLocation(pattern, params);
            for (var i = 0; i < branches.length; i++) {
              final branch = branches[i];
              final childResult = _matchNodes(
                branch.children,
                segments,
                segmentIndex + consumed,
                matches,
                shellMatches,
                shellLocation,
                i,
                queryParams,
              );
              if (childResult != null) {
                shellMatches.add(
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
              matches.clear();
            }
          }
        case FlowBranchNode():
          break;
      }
    }
    return null;
  }

  (Map<String, String>, int)? _matchPattern(
    PathPattern pattern,
    List<String> segments,
    int start,
  ) {
    final params = <String, String>{};
    var segIndex = start;
    var patIndex = 0;

    while (patIndex < pattern.segments.length) {
      final patSeg = pattern.segments[patIndex];

      switch (patSeg) {
        case LiteralSegment(:final value):
          if (segIndex >= segments.length ||
              Uri.decodeComponent(segments[segIndex]) != value) {
            return null;
          }
          segIndex++;
          patIndex++;
        case PathParamSegment(:final name, :final optional):
          if (segIndex < segments.length) {
            params[name] = Uri.decodeComponent(segments[segIndex]);
            segIndex++;
            patIndex++;
          } else if (optional) {
            patIndex++;
          } else {
            return null;
          }
        case WildcardSegment():
          return (params, segments.length - start);
      }
    }

    if (segIndex != segments.length) return null;
    return (params, segIndex - start);
  }

  String _buildLocation(PathPattern pattern, Map<String, String> params) {
    final parts = <String>[];
    for (final seg in pattern.segments) {
      switch (seg) {
        case LiteralSegment(:final value):
          parts.add(value);
        case PathParamSegment(:final name):
          final value = params[name];
          if (value != null) parts.add(value);
        case WildcardSegment():
          break;
      }
    }
    return '/${parts.join('/')}';
  }
}
