# FAQ

## How is Flow different from GoRouter?

Flow uses **typed routes as the source of truth** with separated declarative/overlay stacks. GoRouter is string-first with a dual-purpose `RouteMatchList`.

## Do I need code generation?

No. Define `FlowRoute` subclasses manually. Optional `flow_generator` may come in future releases.

## Can I use string paths?

Flow is designed for typed routes. For legacy strings, use `SetLocationIntent` or migration helpers.

## How does `go` differ from `push`?

- **`go`** — replaces the location stack; clears overlays
- **`push`** — adds to overlay stack; URL unchanged by default

## How do guards work?

Guards run in a pipeline: global → route-level. They return `Allow`, `Block`, or `Redirect`.

## Does Flow work on web?

Yes. URLs sync via `FlowRouteInformationProvider`. Refresh rebuilds state from the URL.

## How do I test navigation?

Use `NavigationEngine` directly for unit tests, `FakeFlowRouter` for intent recording, or `FlowApp` in widget tests.

## Can I migrate from GoRouter?

See [MIGRATION.md](MIGRATION.md). Use `goRouterPathToDefinition()` for route scaffolding.

## What about shell routes / tabs?

Use `FlowShellNode` or `FlowStatefulShellNode`, or a layout widget with `context.go` between tabs (see example app).

## How do I pass data between routes?

Use typed route parameters, query parameters, or the `extra` argument on `go`/`push`.
