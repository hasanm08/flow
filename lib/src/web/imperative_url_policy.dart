/// Controls how imperative navigation affects the browser URL.
enum ImperativeUrlPolicy {
  /// URL reflects declarative location only (default, deep-link safe).
  declarativeOnly,

  /// URL reflects the top of merged stacks (legacy behavior).
  includeOverlays,

  /// URL never changes on push/pop.
  frozen,
}
