import 'flow_route.dart';
import '../matcher/path_pattern.dart';

/// Builds canonical URL locations from [FlowRoute] instances.
final class LocationBuilder {
  const LocationBuilder({
    required this.pathTemplate,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.fragment,
  });

  factory LocationBuilder.fromRoute(FlowRoute route) {
    return LocationBuilder(
      pathTemplate: route.pathTemplate,
      pathParameters: route.pathParameters,
      queryParameters: route.queryParameters,
      fragment: route.fragment,
    );
  }

  final String pathTemplate;
  final Map<String, String> pathParameters;
  final Map<String, String> queryParameters;
  final String? fragment;

  /// Builds path only from a compiled [pattern] — no query string.
  static String pathOnly(
    PathPattern pattern,
    Map<String, String> pathParameters,
  ) {
    if (pattern.segments.isEmpty) return '/';

    final parts = <String>[];
    for (final seg in pattern.segments) {
      switch (seg) {
        case LiteralSegment(:final value):
          parts.add(value);
        case PathParamSegment(:final name):
          final value = pathParameters[name];
          if (value != null) parts.add(value);
        case WildcardSegment():
          break;
      }
    }
    return '/${parts.join('/')}';
  }

  /// Builds a canonical location string.
  String build() {
    final path = _buildPath();
    if (queryParameters.isEmpty && (fragment == null || fragment!.isEmpty)) {
      return path;
    }

    final buffer = StringBuffer(path);

    if (queryParameters.isNotEmpty) {
      buffer.write('?');
      var first = true;
      for (final entry in queryParameters.entries) {
        if (!first) buffer.write('&');
        first = false;
        buffer
          ..write(Uri.encodeQueryComponent(entry.key))
          ..write('=')
          ..write(Uri.encodeQueryComponent(entry.value));
      }
    }

    if (fragment != null && fragment!.isNotEmpty) {
      buffer.write('#${Uri.encodeComponent(fragment!)}');
    }

    return buffer.toString();
  }

  String _buildPath() {
    final segments = pathTemplate.split('/').where((s) => s.isNotEmpty);
    final built = <String>[];

    for (final segment in segments) {
      if (segment.startsWith(':')) {
        final key = segment.replaceAll('?', '');
        final value = pathParameters[key.substring(1)];
        if (value != null) {
          built.add(Uri.encodeComponent(value));
        }
      } else {
        built.add(segment);
      }
    }

    return '/${built.join('/')}';
  }
}
