## 2.0.0

**Instance-based routing — no route classes required.**

### Breaking changes
- `FlowRoute` is now a concrete `final class` — define route **instances** instead of subclasses
- `FlowRouteDefinition` is no longer generic; `factory` is optional (auto-generated from path params)
- `goRouterPathToDefinition` no longer takes a type parameter

### New API
- `flow()` top-level helper for concise route registration
- `FlowRouteAccess` extension: `pathParam`, `intPathParam`, `queryParam`, `isName`
- `FlowRoute.isName()` for guard checks without `is` type tests
- `FlowRoute.copyWith()` and optional `extra` payload

### Performance (120+ FPS target)
- Multi-level **route trie** — O(depth) candidate lookup instead of O(routes) for shared prefixes
- **MatchEngine** scratch buffers — zero per-match list/map allocation on hot path
- **`matchLeaf` fast path** — typed `context.flow()` skips full tree scan (O(1) name lookup)
- **Page cache** — reuses unchanged `Page` instances when `pageKey` / location is stable
- **Location caching** — `FlowRoute.location` and `NavigationState.location` computed once
- **URL sync skip** — platform URL updated only when URI actually changes
- **Sync guard/middleware fast path** — no microtask overhead for synchronous guards
- **Single `FlowRouterScope`** — removed per-page inherited notifier overhead

### Navigation API
- `context.flow(route)` — unified go navigation
- `context.flow(route, push: true)` — overlay push
- `context.flowNamed(name, ...)` — goNamed / pushNamed equivalent
- `context.pop()` — pop overlay or history

### Example
```dart
context.flow(Routes.user(id: 42));
context.flow(Routes.about, push: true);
context.pop();
```

## 1.0.3

- add benchmark image to README for performance tracking.

## 1.0.2

- Add segment-indexed route matching for faster lookups on large route trees
- Cache route definitions by name in `RouteRegistry` for O(1) lookup
- Gate `LoggingMiddleware` output behind `kDebugMode` for production builds
- Harden CI with format checks and example app analysis
- Tighten analyzer rules and Flutter SDK constraint (`>=3.12.0`)

## 1.0.1
- fix lint issues, and clean up imports across the codebase
## 1.0.0

**Flow Routing (`flow_routing` on pub.dev) is production-ready.**

### Core Router
- Typed `FlowRoute` system with automatic URL generation (`.location`)
- `FlowRouter` with Navigator 2.0 integration via `FlowApp.router`
- Navigation intents: `go`, `push`, `pop`, `replace`, `popUntil`, `goBranch`
- Separated declarative location stack and imperative overlay stacks
- Segment-based `MatchEngine` with path parameters and query support

### Guards & Middleware
- `FlowGuard` pipeline with `GuardAllow`, `GuardBlock`, `GuardRedirect`
- `RedirectGuard` for common auth patterns
- `FlowMiddleware` with `LoggingMiddleware`

### Web
- `FlowRouteInformationParser` and `FlowRouteInformationProvider`
- `ImperativeUrlPolicy` for URL synchronization control
- Refresh-safe URL parsing

### Shell Routes
- `FlowShellNode` for nested navigation
- `FlowStatefulShellNode` for tab-based branch navigation

### Transitions
- `FlowTransition.material`, `.fade`, `.slide`, `.none`

### Testing
- `FakeFlowRouter` for intent recording
- Unit tests for matcher, engine, location builder
- Widget tests for `FlowApp`

### Migration
- `goRouterPathToDefinition` and `migrateGoRouterPath` helpers

### Example
- Beautiful Material 3 demo app with auth guards, typed user routes, and web support

### Documentation
- Getting Started, API Reference, Cookbook, Migration Guide, Architecture

## 0.1.0

- Phase 1: Architecture proposal and GoRouter issue analysis
