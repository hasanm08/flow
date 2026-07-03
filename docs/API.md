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

Abstract base class. Subclass per destination.

| Property | Description |
|----------|-------------|
| `name` | Stable route identifier |
| `pathTemplate` | Pattern e.g. `/users/:id` |
| `pathParameters` | Path param values |
| `queryParameters` | Query param values |
| `fragment` | URI fragment |
| `location` | Canonical URL (computed) |

### `FlowRouteDefinition<T>`

Binds a route type to a page builder.

| Parameter | Description |
|-----------|-------------|
| `name` | Route name |
| `pathTemplate` | URL pattern |
| `builder` | `(context, route) => Widget` |
| `factory` | `Map<String,String> => FlowRoute` |
| `guards` | Per-route guards |
| `transition` | `FlowTransition` |
| `restorable` | State restoration flag |

## Navigation

### `BuildContext` extensions

```dart
context.flow          // FlowRouter
context.go(route)
context.push(route)
context.replace(route)
context.pop([result])
context.popUntil(route)
context.canPop()
context.routeState    // FlowRouteState
```

### `FlowNavigationMode`

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
  redirectTo: (ctx) => LoginRoute(returnTo: ctx.targetRoute.location),
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
  children: [...],
)
```

### `FlowStatefulShellNode`

Tab-based navigation with independent branch stacks.

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
await fake.go(const HomeRoute());
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
