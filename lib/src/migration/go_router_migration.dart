import 'package:flutter/widgets.dart';

import '../typed_routes/flow_route.dart';
import '../typed_routes/flow_route_definition.dart';

/// Converts a GoRouter-style path template to a Flow path template.
String migrateGoRouterPath(String path) {
  if (path.isEmpty) return '/';
  if (!path.startsWith('/')) return '/$path';
  return path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
}

/// Scaffold for creating a [FlowRouteDefinition] from a GoRouter path.
FlowRouteDefinition<T> goRouterPathToDefinition<T extends FlowRoute>({
  required String name,
  required String path,
  required FlowRouteBuilder<T> builder,
  required FlowRouteFactory factory,
}) {
  return FlowRouteDefinition<T>(
    name: name,
    pathTemplate: migrateGoRouterPath(path),
    builder: builder,
    factory: factory,
  );
}
