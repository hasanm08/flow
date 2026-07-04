/// Stable identifier for a [Navigator] within Flow.
///
/// Prefer this over ad-hoc [GlobalKey] assignment to avoid collisions
/// in shell and branch navigators.
final class NavigatorId {
  const NavigatorId(this.value);

  /// Root navigator identifier.
  static const root = NavigatorId('root');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NavigatorId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NavigatorId($value)';
}
