/// Compiled path pattern for route matching.
final class PathPattern {
  const PathPattern(this.template, this.segments, this.pathParamNames);

  factory PathPattern.parse(String template) {
    final normalized = template == '/' ? '' : template;
    final parts = normalized.split('/').where((s) => s.isNotEmpty).toList();
    final segments = <PathSegment>[];
    final pathParamNames = <String>{};

    for (final part in parts) {
      if (part.startsWith(':')) {
        final optional = part.endsWith('?');
        final name = part.substring(1).replaceAll('?', '');
        segments.add(PathParamSegment(name, optional: optional));
        pathParamNames.add(name);
      } else if (part == '*') {
        segments.add(const WildcardSegment());
      } else {
        segments.add(LiteralSegment(part));
      }
    }

    return PathPattern(template, segments, pathParamNames);
  }

  final String template;
  final List<PathSegment> segments;

  /// Precomputed at parse time — avoids per-factory Set allocation.
  final Set<String> pathParamNames;

  int get length => segments.length;
}

sealed class PathSegment {
  const PathSegment();
}

final class LiteralSegment extends PathSegment {
  const LiteralSegment(this.value);
  final String value;
}

final class PathParamSegment extends PathSegment {
  const PathParamSegment(this.name, {this.optional = false});
  final String name;
  final bool optional;
}

final class WildcardSegment extends PathSegment {
  const WildcardSegment();
}
