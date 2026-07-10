# FAQ

## How is Flow different from GoRouter?

Flow uses **typed routes as the source of truth** with separated declarative/overlay stacks. GoRouter is string-first with a dual-purpose `RouteMatchList`.

## Do I need code generation?

No. Define route instances in a `Routes` class. Optional `flow_generator` may come in future releases.

## Can I use string paths?

Flow is designed for typed routes. Use `context.flowNamed()` for name-based navigation, or `SetLocationIntent` for raw URL strings.

## How does `flow` differ from `flow(..., push: true)`?

- **`context.flow(route)`** — replaces the location stack; clears overlays; updates URL
- **`context.flow(route, push: true)`** — adds to overlay stack; URL unchanged by default
- **`context.pop()`** — dismisses overlay or goes back in history

## How do guards work?

Guards run in a pipeline: global → route-level. They return `Allow`, `Block`, or `Redirect`.

## Does Flow work on web?

Yes. URLs sync via `FlowRouteInformationProvider`. Refresh rebuilds state from the URL.

## How do I test navigation?

Use `NavigationEngine` directly for unit tests, `FakeFlowRouter` for intent recording, or `FlowApp` in widget tests.

## Can I migrate from GoRouter?

See [MIGRATION.md](MIGRATION.md). Use `goRouterPathToDefinition()` for route scaffolding.

## What about shell routes / tabs?

Use `FlowShellNode` or `FlowStatefulShellNode`, or a layout widget with `context.flow` between tabs (see example app).

## How do I pass data between routes?

Use typed route parameters, query parameters, or the `extra` argument on `context.flow`.
