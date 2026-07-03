# Migration Guide

## From GoRouter

| GoRouter | Flow |
|----------|------|
| `GoRoute(path: '/users/:id', ...)` | `FlowRouteDefinition<UserRoute>(pathTemplate: '/users/:id', ...)` |
| `context.go('/users/42')` | `context.go(UserRoute(id: 42))` |
| `context.push('/settings')` | `context.push(const SettingsRoute())` |
| `GoRouter.redirect` | `FlowGuard` / `RedirectGuard` |
| `ShellRoute` | `FlowShellNode` |
| `StatefulShellRoute` | `FlowStatefulShellNode` |
| `extra` | `extra` parameter on `go`/`push` |
| `GoRouterState.of(context)` | `context.routeState` |

### Path migration helper

```dart
import 'package:flow_routing/flow_routing.dart';

final definition = goRouterPathToDefinition<UserRoute>(
  name: 'user',
  path: '/users/:id',
  builder: (context, route) => UserPage(id: route.id),
  factory: (params) => UserRoute(id: int.parse(params['id']!)),
);
```

## From Navigator 1.0

| Navigator 1.0 | Flow |
|---------------|------|
| `Navigator.pushNamed(context, '/user', arguments: 42)` | `context.push(UserRoute(id: 42))` |
| `Navigator.pop(context)` | `context.pop()` |
| `routes: {'/': ...}` | `FlowRouter(routes: [...])` |

## From AutoRoute

AutoRoute generated route classes map directly to Flow:

```dart
// AutoRoute: context.router.push(UserRoute(id: 42))
// Flow:       context.push(UserRoute(id: 42))
```

Remove `@RoutePage` and code generation; define `FlowRoute` subclasses manually.

## From Beamer

| Beamer | Flow |
|--------|------|
| `BeamLocation` | `FlowShellNode` or feature module routes |
| `beamToNamed('/users/42')` | `context.go(UserRoute(id: 42))` |
| `locationBuilder` | `FlowRouter` route tree |

## From Navigator 2.0

Flow replaces your custom `RouterDelegate`, `RouteInformationParser`, and matching logic:

```dart
// Before: MaterialApp.router(routerDelegate: ..., routeInformationParser: ...)
// After:  FlowApp.router(router: flowRouter)
```

Your `Page` building logic moves into `FlowRouteDefinition.builder`.
