import '../navigation/navigation_state.dart';

/// Result of a navigation operation.
final class NavigationResult {
  const NavigationResult({
    required this.state,
    this.popResult,
    this.completed = true,
  });

  final NavigationState state;
  final Object? popResult;
  final bool completed;
}
