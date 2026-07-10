# Migration Guide

## Navigation API (v2)

| Old (v1) | New (v2) |
|----------|----------|
| `context.go(route)` | `context.flow(route)` |
| `context.push(route)` | `context.flow(route, push: true)` |
| `context.pop()` | `context.pop()` (unchanged) |
| `context.replace(route)` | `context.replace(route)` |
| `context.flow` (router getter) | `context.flowRouter` |
| `context.routeState` | `context.routeState` (unchanged) |
| — | `context.flowNamed('user', pathParameters: {'id': '42'})` |
| — | `context.flowNamed('about', push: true)` |

## From GoRouter

| GoRouter | Flow |
|----------|------|
| `GoRoute(path: '/users/:id', ...)` | `flow('/users/:id', name: 'user', builder: ...)` |
| `context.go('/users/42')` | `context.flow(Routes.user(id: 42))` |
| `context.goNamed('user', pathParameters: {'id': '42'})` | `context.flowNamed('user', pathParameters: {'id': '42'})` |
| `context.push('/settings')` | `context.flow(Routes.settings, push: true)` |
| `context.pushNamed('about')` | `context.flowNamed('about', push: true)` |
| `context.pop()` | `context.pop()` |
| `GoRouter.redirect` | `FlowGuard` / `RedirectGuard` |
| `ShellRoute` | `FlowShellNode` |
| `StatefulShellRoute` | `FlowStatefulShellNode` |
| `extra` | `extra` parameter on `context.flow` |
| `GoRouterState.of(context)` | `context.routeState` |

### Route classes → instances (v2)

| v1 | v2 |
|----|-----|
| `final class UserRoute extends FlowRoute { ... }` | `Routes.user(id: 42)` instance |
| `FlowRouteDefinition<UserRoute>(...)` | `flow('/users/:id', name: 'user', ...)` |
| Manual `factory:` | Optional — auto-generated from path params |

### Path migration helper

```dart
import 'package:flow_routing/flow_routing.dart';

final definition = goRouterPathToDefinition(
  name: 'user',
  path: '/users/:id',
  builder: (context, route) => UserPage(id: route.intPathParam('id')),
);
```

## From Navigator 1.0

| Navigator 1.0 | Flow |
|---------------|------|
| `Navigator.pushNamed(context, '/user', arguments: 42)` | `context.flowNamed('user', pathParameters: {'id': '42'})` |
| `Navigator.push(context, MaterialPageRoute(...))` | `context.flow(route, push: true)` |
| `Navigator.pop(context)` | `context.pop()` |
| `routes: {'/': ...}` | `FlowRouter(routes: [...])` |

## From AutoRoute

AutoRoute generated route classes map to Flow route instances:

```dart
// AutoRoute: context.router.push(UserRoute(id: 42))
// Flow:       context.flow(Routes.user(id: 42), push: true)
```

Remove `@RoutePage` and code generation; define route instances in a `Routes` class.

## From Beamer

| Beamer | Flow |
|--------|------|
| `BeamLocation` | `FlowShellNode` or feature module routes |
| `beamToNamed('/users/42')` | `context.flow(Routes.user(id: 42))` |
| `locationBuilder` | `FlowRouter` route tree |

## From Navigator 2.0

Flow replaces your custom `RouterDelegate`, `RouteInformationParser`, and matching logic:

```dart
// Before: MaterialApp.router(routerDelegate: ..., routeInformationParser: ...)
// After:  FlowApp.router(router: flowRouter)
```

Your `Page` building logic moves into `flow()` / `FlowRouteDefinition.builder`.
