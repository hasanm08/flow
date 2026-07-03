import 'package:flutter/widgets.dart';

import '../matcher/route_match.dart';
import '../navigation/navigation_engine.dart';
import '../navigation/navigation_state.dart';

/// Parses platform route information into [NavigationState].
final class FlowRouteInformationParser
    extends RouteInformationParser<NavigationState> {
  FlowRouteInformationParser({required this.engine});

  final NavigationEngine engine;

  @override
  Future<NavigationState> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final parsed = uri.hasQuery
        ? uri
        : Uri(path: path, queryParameters: uri.queryParameters);

    final result = engine.registry.engine.match(parsed);

    if (result.isError) {
      return NavigationState(locationChain: result.chain);
    }

    return NavigationState(locationChain: result.chain);
  }

  @override
  RouteInformation restoreRouteInformation(NavigationState configuration) {
    final location = configuration.location;
    return RouteInformation(
      uri: Uri.parse(location.startsWith('/') ? location : '/$location'),
    );
  }
}
