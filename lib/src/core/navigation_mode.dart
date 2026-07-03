/// How a navigation operation affects the route stacks.
enum FlowNavigationMode {
  /// Replace the declarative location stack.
  go,

  /// Push onto the overlay stack of the target navigator.
  push,

  /// Replace the top overlay or location leaf.
  replace,
}
