import '../typed_routes/flow_route.dart';

/// Typed accessors for [FlowRoute] path and query parameters.
extension FlowRouteAccess on FlowRoute {
  /// Required path parameter.
  String pathParam(String key) {
    final value = pathParameters[key];
    if (value == null) {
      throw StateError('Missing path parameter "$key" on route "$name"');
    }
    return value;
  }

  /// Optional path parameter.
  String? optionalPathParam(String key) => pathParameters[key];

  /// Path parameter parsed as [int].
  int intPathParam(String key) => int.parse(pathParam(key));

  /// Query parameter, if present.
  String? queryParam(String key) => queryParameters[key];

  /// Typed [extra] payload.
  T? extraAs<T>() => extra is T ? extra as T : null;
}
