import '../typed_routes/location_builder.dart';

/// Lazily caches computed [FlowRoute.location] strings per instance.
final Expando<String> _routeLocationCache = Expando();

/// A typed route instance — no subclass needed.
///
/// Define route constants or factory functions in your app, then navigate:
///
/// ```dart
/// context.flow(Routes.home);
/// context.flow(Routes.about, push: true);
/// context.pop();
/// ```
final class FlowRoute {
  const FlowRoute({
    required this.name,
    required this.pathTemplate,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.fragment,
    this.extra,
  });

  /// Stable route name used for named navigation and restoration.
  final String name;

  /// Path template, e.g. `/users/:id`.
  final String pathTemplate;

  /// Path parameters for this route instance.
  final Map<String, String> pathParameters;

  /// Query parameters for this route instance.
  final Map<String, String> queryParameters;

  /// Optional URI fragment.
  final String? fragment;

  /// Optional typed payload attached at navigation time.
  final Object? extra;

  /// Canonical URL location — never construct URLs manually.
  ///
  /// Cached per instance after first access.
  String get location =>
      _routeLocationCache[this] ??= LocationBuilder.fromRoute(this).build();

  /// Whether this route matches [name].
  bool isName(String name) => this.name == name;

  FlowRoute copyWith({
    String? name,
    String? pathTemplate,
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
    String? fragment,
    Object? extra,
  }) {
    return FlowRoute(
      name: name ?? this.name,
      pathTemplate: pathTemplate ?? this.pathTemplate,
      pathParameters: pathParameters ?? this.pathParameters,
      queryParameters: queryParameters ?? this.queryParameters,
      fragment: fragment ?? this.fragment,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowRoute &&
          name == other.name &&
          pathTemplate == other.pathTemplate &&
          _mapEquals(pathParameters, other.pathParameters) &&
          _mapEquals(queryParameters, other.queryParameters) &&
          fragment == other.fragment;

  @override
  int get hashCode => Object.hash(
    name,
    pathTemplate,
    Object.hashAll(pathParameters.entries),
    Object.hashAll(queryParameters.entries),
    fragment,
  );

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
