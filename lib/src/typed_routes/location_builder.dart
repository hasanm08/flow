import 'flow_route.dart';

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

  /// Builds a canonical location string.
  String build() {
    final path = _buildPath();
    final buffer = StringBuffer(path);

    if (queryParameters.isNotEmpty) {
      buffer.write('?');
      buffer.write(
        queryParameters.entries
            .map(
              (e) =>
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
            )
            .join('&'),
      );
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
