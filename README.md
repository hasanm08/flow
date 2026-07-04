# Flow Routing

**The next-generation Flutter router** — typed, fast, and built from first principles.

Published on pub.dev as [`flow_routing`](https://pub.dev/packages/flow_routing).

[![version](https://img.shields.io/badge/version-1.0.2-indigo)](CHANGELOG.md)
[![flutter](https://img.shields.io/badge/flutter-%3E%3D3.12-blue)](https://flutter.dev)

```dart
context.go(HomeRoute());
context.push(UserRoute(id: 42, tab: UserTab.profile));
context.pop();

UserRoute(id: 5).location; // → "/users/5?tab=profile"
```

## Why Flow?

| Feature | Flow | GoRouter | AutoRoute |
|---------|------|----------|-----------|
| Typed routes | ✅ First-class | ⚠️ Codegen | ✅ Codegen required |
| No code generation | ✅ | ✅ | ❌ |
| Separated nav stacks | ✅ | ❌ | ⚠️ |
| Pipeline guards | ✅ | ⚠️ | ✅ |
| Web-first URLs | ✅ | ⚠️ | ✅ |
| Optional middleware | ✅ | ❌ | ❌ |

## Features

- **Typed routes** — `UserRoute(id: 42)` not `'/users/42'`
- **Reverse routing** — URLs generated automatically via `.location`
- **Pipeline guards** — composable auth, roles, async validation
- **Middleware** — logging, analytics, localization hooks
- **Separated stacks** — declarative `go` vs imperative `push` overlays
- **Web support** — clean URLs, browser history, refresh-safe parsing
- **Transitions** — material, fade, slide, none
- **Shell routes** — nested navigation and tab branches
- **Testing** — `FakeFlowRouter`, engine unit tests, widget tests
- **Migration** — helpers for GoRouter, Navigator, AutoRoute, Beamer

## Quick Start

```yaml
dependencies:
  flow_routing: ^1.0.0
```

```dart
import 'package:flow_routing/flow_routing.dart';

final router = FlowRouter(
  routes: [
    FlowLeafNode(FlowRouteDefinition<HomeRoute>(
      name: 'home',
      pathTemplate: '/',
      builder: (context, route) => const HomePage(),
      factory: (_) => const HomeRoute(),
    )),
  ],
);

void main() => runApp(FlowApp.router(router: router));
```

See [Getting Started](docs/GETTING_STARTED.md) for the full guide.

## Example App

A polished demo showcasing typed navigation, guards, middleware, and web URLs:

```bash
cd example
flutter run -d chrome   # Web
flutter run             # Mobile
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/GETTING_STARTED.md) | Install and first routes |
| [API Reference](docs/API.md) | Complete public API |
| [Architecture](docs/ARCHITECTURE.md) | System design |
| [Cookbook](docs/COOKBOOK.md) | Recipes and patterns |
| [Migration](docs/MIGRATION.md) | From GoRouter, AutoRoute, etc. |
| [GoRouter Issues](docs/GOROUTER_ISSUES.md) | How Flow addresses 287+ issues |

## Project Structure

```
flow/
├── lib/           # Package source
├── example/       # Demo application
├── docs/          # Documentation
├── test/          # Unit & widget tests
└── benchmark/     # Performance benchmarks
```

## License

MIT — see [LICENSE](LICENSE).
