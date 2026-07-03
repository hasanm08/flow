# Getting Started with Flow

Flow is a typed, declarative Flutter router built on Navigator 2.0.

## Installation

```yaml
dependencies:
  flow_routing: ^1.0.0
```

## Quick Start

### 1. Define typed routes

```dart
final class HomeRoute extends FlowRoute {
  const HomeRoute();
  @override
  String get name => 'home';
  @override
  String get pathTemplate => '/';
}

final class UserRoute extends FlowRoute {
  const UserRoute({required this.id});
  final int id;

  @override
  String get name => 'user';
  @override
  String get pathTemplate => '/users/:id';
  @override
  Map<String, String> get pathParameters => {'id': '$id'};
}
```

### 2. Register routes

```dart
final router = FlowRouter(
  routes: [
    FlowLeafNode(
      FlowRouteDefinition<HomeRoute>(
        name: 'home',
        pathTemplate: '/',
        builder: (context, route) => const HomePage(),
        factory: (_) => const HomeRoute(),
      ),
    ),
    FlowLeafNode(
      FlowRouteDefinition<UserRoute>(
        name: 'user',
        pathTemplate: '/users/:id',
        builder: (context, route) => UserPage(id: route.id),
        factory: (params) => UserRoute(id: int.parse(params['id']!)),
      ),
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
context.go(const HomeRoute());
context.push(const UserRoute(id: 42));
context.pop();

// Reverse routing — never build URLs manually
UserRoute(id: 5).location; // → "/users/5"
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
