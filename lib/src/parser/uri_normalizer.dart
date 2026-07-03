/// Normalizes URIs for consistent matching and serialization.
abstract final class UriNormalizer {
  static Uri normalize(Uri uri) {
    var path = uri.path;
    if (path.isEmpty) path = '/';
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return uri.replace(path: path);
  }

  static List<String> pathSegments(Uri uri) {
    return uri.path.split('/').where((s) => s.isNotEmpty).toList();
  }

  static Map<String, String> queryParameters(Uri uri) {
    return Map<String, String>.from(uri.queryParameters);
  }
}
