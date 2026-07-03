import '../typed_routes/location_builder.dart';

/// Base class for strongly typed routes.
///
/// Subclass for each destination. URLs are always derived via [location].
///
/// ```dart
/// final class UserRoute extends FlowRoute {
///   const UserRoute({required this.id});
///   final int id;
///
///   @override
///   String get name => 'user';
///
///   @override
///   String get pathTemplate => '/users/:id';
///
///   @override
///   Map<String, String> get pathParameters => {'id': '$id'};
/// }
/// ```
abstract class FlowRoute {
  const FlowRoute();

  /// Stable route name used for named navigation and restoration.
  String get name;

  /// Path template, e.g. `/users/:id`.
  String get pathTemplate;

  /// Path parameters for this route instance.
  Map<String, String> get pathParameters => const {};

  /// Query parameters for this route instance.
  Map<String, String> get queryParameters => const {};

  /// Optional URI fragment.
  String? get fragment => null;

  /// Canonical URL location — never construct URLs manually.
  String get location => LocationBuilder.fromRoute(this).build();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowRoute &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _mapEquals(pathParameters, other.pathParameters) &&
          _mapEquals(queryParameters, other.queryParameters) &&
          fragment == other.fragment;

  @override
  int get hashCode => Object.hash(
        name,
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
