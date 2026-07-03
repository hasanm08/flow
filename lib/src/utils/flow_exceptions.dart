/// Base exception for Flow routing errors.
sealed class FlowException implements Exception {
  const FlowException(this.message);

  final String message;

  @override
  String toString() => 'FlowException: $message';
}

/// Thrown when no route matches a location.
final class FlowNotFoundException extends FlowException {
  const FlowNotFoundException(super.message, {this.location});

  final String? location;
}

/// Thrown when redirect evaluation exceeds [maxRedirects].
final class FlowRedirectLoopException extends FlowException {
  const FlowRedirectLoopException(super.message);
}

/// Thrown when a guard blocks navigation.
final class FlowGuardBlockedException extends FlowException {
  const FlowGuardBlockedException(super.message, {this.reason});

  final String? reason;
}

/// Thrown when popping an empty stack.
final class FlowNothingToPopException extends FlowException {
  const FlowNothingToPopException() : super('There is nothing to pop.');
}
