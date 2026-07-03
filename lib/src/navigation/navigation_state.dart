import '../matcher/route_match.dart';
import '../typed_routes/flow_route.dart';

/// Immutable overlay entry for imperative navigation.
final class FlowOverlayEntry {
  const FlowOverlayEntry({
    required this.route,
    required this.match,
    this.extra,
    this.id,
  });

  final FlowRoute route;
  final RouteMatch match;
  final Object? extra;
  final int? id;
}

/// Stack of imperative overlay routes for a navigator.
final class OverlayStack {
  const OverlayStack({this.entries = const []});

  final List<FlowOverlayEntry> entries;

  bool get isEmpty => entries.isEmpty;
  FlowOverlayEntry? get top => entries.isEmpty ? null : entries.last;

  OverlayStack push(FlowOverlayEntry entry) =>
      OverlayStack(entries: [...entries, entry]);

  OverlayStack pop() => entries.isEmpty
      ? this
      : OverlayStack(entries: entries.sublist(0, entries.length - 1));

  OverlayStack replaceTop(FlowOverlayEntry entry) {
    if (entries.isEmpty) return OverlayStack(entries: [entry]);
    final next = [...entries];
    next[next.length - 1] = entry;
    return OverlayStack(entries: next);
  }

  OverlayStack clear() => const OverlayStack();
}

/// Complete immutable navigation state.
final class NavigationState {
  const NavigationState({
    required this.locationChain,
    this.overlayStacks = const {},
    this.extra,
    this.branchLocations = const {},
  });

  final RouteMatchChain locationChain;
  final Map<String, OverlayStack> overlayStacks;
  final Object? extra;
  final Map<int, String> branchLocations;

  bool get isEmpty => locationChain.isEmpty;

  String get location {
    final path = locationChain.uri.path;
    final normalizedPath = path.isEmpty ? '/' : path;
    final query = locationChain.uri.query;
    if (query.isEmpty) return normalizedPath;
    return '$normalizedPath?$query';
  }

  Uri get uri => locationChain.uri;

  OverlayStack overlayFor(String navigatorId) =>
      overlayStacks[navigatorId] ?? const OverlayStack();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState &&
          location == other.location &&
          extra == other.extra &&
          _mapEquals(overlayStacks, other.overlayStacks);

  @override
  int get hashCode => Object.hash(location, extra, overlayStacks.length);

  static bool _mapEquals(
    Map<String, OverlayStack> a,
    Map<String, OverlayStack> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key]?.entries.length != entry.value.entries.length) {
        return false;
      }
    }
    return true;
  }

  NavigationState copyWith({
    RouteMatchChain? locationChain,
    Map<String, OverlayStack>? overlayStacks,
    Object? extra,
    bool clearExtra = false,
    Map<int, String>? branchLocations,
  }) {
    return NavigationState(
      locationChain: locationChain ?? this.locationChain,
      overlayStacks: overlayStacks ?? this.overlayStacks,
      extra: clearExtra ? null : (extra ?? this.extra),
      branchLocations: branchLocations ?? this.branchLocations,
    );
  }
}
