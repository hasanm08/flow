# Getting Started with Flow

Flow is a typed, declarative Flutter router built on Navigator 2.0.

## Installation

```yaml
dependencies:
  flow_routing: ^2.0.0
```

## Quick Start

### 1. Define route instances

```dart
abstract final class Routes {
  static const home = FlowRoute(name: 'home', pathTemplate: '/');

  static FlowRoute user({required int id}) => FlowRoute(
    name: 'user',
    pathTemplate: '/users/:id',
    pathParameters: {'id': '$id'},
  );
}
```

### 2. Register routes

```dart
final router = FlowRouter(
  routes: [
    flow('/', name: 'home', builder: (context, route) => const HomePage()),
    flow(
      '/users/:id',
      name: 'user',
      builder: (context, route) => UserPage(id: route.intPathParam('id')),
    ),
  ],
);
```

### 3. Wire up the app

```dart
void main() {
  runApp(FlowApp.router(router: router));
}
```

### 4. Navigate

```dart
context.flow(Routes.home);
context.flow(Routes.user(id: 42));
context.flow(Routes.about, push: true);  // overlay — URL unchanged
context.pop();

// By name (goNamed / pushNamed equivalent)
context.flowNamed('user', pathParameters: {'id': '42'});

// Reverse routing — never build URLs manually
Routes.user(id: 5).location; // → "/users/5"
```

## Run the Example

```bash
cd example
flutter run
```

The example demonstrates typed navigation, route guards, middleware, push overlays, and web-ready URLs.

## Next Steps

- [API Reference](API.md)
- [Architecture](ARCHITECTURE.md)
- [Migration Guide](MIGRATION.md)
- [Cookbook](COOKBOOK.md)
