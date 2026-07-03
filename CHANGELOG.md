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
