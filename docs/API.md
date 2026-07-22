# Flow API Reference

## Core

### `FlowRouter`

Primary router configuration.

| Parameter | Type | Description |
|-----------|------|-------------|
| `routes` | `List<FlowRouteNode>` | Route tree |
| `initialLocation` | `String?` | Starting URL (default `/`) |
| `guards` | `List<FlowGuard>` | Global guards |
| `middleware` | `List<FlowMiddleware>` | Global middleware |
| `observers` | `List<FlowNavigatorObserver>` | Navigator observers |
| `refreshListenable` | `Listenable?` | Rebuild on state changes |
| `imperativeUrlPolicy` | `ImperativeUrlPolicy` | Web URL sync policy |
| `errorBuilder` | `Widget Function(...)?` | 404 page |

**Methods:** `go`, `push`, `replace`, `pop`, `popUntil`, `goBranch`, `canPop`, `refresh`

### `FlowApp`

Convenience `MaterialApp.router` wrapper.

```dart
FlowApp.router(router: router, title: 'My App', theme: theme)
```

## Typed Routes

### `FlowRoute`

Concrete route instance — no subclass required.

| Property | Description |
|----------|-------------|
| `name` | Stable route identifier |
| `pathTemplate` | Pattern e.g. `/users/:id` |
| `pathParameters` | Path param values |
| `queryParameters` | Query param values |
| `fragment` | URI fragment |
| `extra` | Optional navigation payload |
| `location` | Canonical URL (computed) |

### `flow()`

Top-level helper to register a leaf route.

```dart
flow('/users/:id', name: 'user', builder: (context, route) => UserPage(route: route))
```

### `FlowRouteDefinition`

Binds a route name to a page builder. `factory` is optional (auto-generated from path params).

| Parameter | Description |
|-----------|-------------|
| `name` | Route name |
| `pathTemplate` | URL pattern |
| `builder` | `(context, route) => Widget` |
| `factory` | Optional `Map<String,String> => FlowRoute` |
| `guards` | Per-route guards |
| `transition` | `FlowTransition` |
| `pageKey` | Shared navigator key for tab siblings |
| `restorable` | State restoration flag |

## Navigation

### `BuildContext` extensions

```dart
// Navigate with a route instance
context.flow(Routes.home);                         // go
context.flow(Routes.about, push: true);            // push overlay
context.flow(Routes.user(id: 42), extra: data);  // with extra payload

// Navigate by name (goNamed / pushNamed equivalent)
context.flowNamed('user', pathParameters: {'id': '42'});
context.flowNamed('about', push: true);

// Pop & stack utilities
context.pop([result]);
context.replace(route);
context.popUntil(route);

// Read state
context.flowRouter      // FlowRouter
context.location        // current URL
context.routeState      // FlowRouteState
context.canPop();
```

### Route parameter helpers

```dart
route.intPathParam('id');
route.queryParam('tab');
route.isName('login');
```

### `FlowNavigationMode`

Used internally by guards and redirects:

- `go` — replace location stack
- `push` — overlay stack
- `replace` — replace top

## Guards

### `FlowGuard`

```dart
abstract class FlowGuard {
  FutureOr<GuardResult> canActivate(GuardContext context);
  FutureOr<GuardResult> canDeactivate(GuardContext context);
}
```

### `GuardResult`

- `GuardAllow()` — proceed
- `GuardBlock(reason: ...)` — cancel
- `GuardRedirect(route, mode: ...)` — redirect

### `RedirectGuard`

```dart
RedirectGuard(
  condition: (ctx) => !isLoggedIn,
  redirectTo: (ctx) => Routes.loginWithReturn(ctx.targetRoute.location),
)
```

## Middleware

```dart
class AnalyticsMiddleware implements FlowMiddleware {
  @override
  void onBefore(MiddlewareContext context) { ... }

  @override
  void onAfter(MiddlewareContext context, NavigationResult result) { ... }
}
```

## Transitions

```dart
FlowTransition.material()  // default
FlowTransition.fade()
FlowTransition.slide()
FlowTransition.none()
```

## Shell Routes

### `FlowShellNode`

```dart
FlowShellNode(
  pathTemplate: '/app',
  navigatorId: NavigatorId('shell'),
  builder: (context, child) => Scaffold(body: child),
  children: [
    flow('/home', name: 'home', builder: ...), // full path: /app/home
  ],
)
```

Child paths are relative to the shell prefix. `builder` wraps the matched page.

### `FlowStatefulShellNode`

Tab-based navigation with independent branch stacks.

```dart
FlowStatefulShellNode(
  pathTemplate: '/',
  builder: (context, shell) => Scaffold(
    body: shell.child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: shell.goBranch,
      destinations: [...],
    ),
  ),
  branches: [...],
)
```

## Web

### `ImperativeUrlPolicy`

- `declarativeOnly` (default) — URL reflects location stack only
- `includeOverlays` — URL includes push stack
- `frozen` — URL never changes on push/pop

## Testing

### `FakeFlowRouter`

Records intents without widget tree.

```dart
final fake = FakeFlowRouter();
await fake.go(Routes.home);
expect(fake.hasGoIntents, isTrue);
```

## Exceptions

| Exception | When |
|-----------|------|
| `FlowNotFoundException` | No matching route |
| `FlowRedirectLoopException` | Too many redirects |
| `FlowGuardBlockedException` | Guard blocked navigation |
| `FlowNothingToPopException` | Empty stack pop |

## Migration

See [MIGRATION.md](MIGRATION.md) for GoRouter, Navigator, and AutoRoute migration.
