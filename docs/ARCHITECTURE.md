# Flow — Architecture Proposal

**Version:** 1.0.0  
**Status:** Production-ready  
**Package:** `flow_routing`

---

## Executive Summary

**Flow** is a ground-up Flutter routing framework built on Navigator 2.0 primitives. It treats **typed routes as the source of truth** and derives URLs from them — never the reverse. Navigation intents flow through a **single immutable pipeline** (parse → match → guard → redirect → build) that eliminates the class of bugs GoRouter accumulates from dual imperative/declarative state, string-based matching, and tightly coupled URL synchronization.

Flow is designed to:

1. Match or exceed every GoRouter capability
2. Resolve 287+ open GoRouter issues through architecture, not patches
3. Work without code generation; support optional codegen in `flow_generator`
4. Outperform GoRouter on route matching, redirect evaluation, and rebuild scope

---

## Table of Contents

1. [Research Summary](#1-research-summary)
2. [Comparative Analysis](#2-comparative-analysis)
3. [Design Principles](#3-design-principles)
4. [System Architecture](#4-system-architecture)
5. [Core Data Models](#5-core-data-models)
6. [Subsystems](#6-subsystems)
7. [Navigation Semantics](#7-navigation-semantics)
8. [Web & Deep Linking](#8-web--deep-linking)
9. [Guards & Middleware](#9-guards--middleware)
10. [Shell & Branch Navigation](#10-shell--branch-navigation)
11. [Performance Strategy](#11-performance-strategy)
12. [Testing Architecture](#12-testing-architecture)
13. [Migration Strategy](#13-migration-strategy)
14. [Package Structure](#14-package-structure)
15. [Phased Delivery Plan](#15-phased-delivery-plan)

---

## 1. Research Summary

### 1.1 GoRouter Architecture

GoRouter wraps Navigator 2.0 with four primary components:

| Component | Role |
|-----------|------|
| `GoRouteInformationProvider` | Bridges OS/browser URL ↔ internal state |
| `GoRouteInformationParser` | Parses `RouteInformation` → `RouteMatchList` |
| `GoRouterDelegate` | Builds `Navigator` pages from `RouteMatchList` |
| `RouteConfiguration` | Static route tree + matching + redirects |

**Internal flow:**

```
URL → findMatch() → RouteMatchList → redirect chain → pages
Navigation API → mutate RouteMatchList → optionally sync URL
```

**Strengths:** Low setup cost, declarative route tree, ShellRoute/StatefulShellRoute, official Flutter team backing, deep link support.

**Architectural weaknesses (root causes of 287 open issues):**

| Weakness | Impact |
|----------|--------|
| **String-first API** | `context.go('/users/42')` — no compile-time safety |
| **RouteMatchList as dual state** | Same structure represents declarative location AND imperative overlay stack; `optionURLReflectsImperativeAPIs` is a compatibility hack |
| **ImperativeRouteMatch lifecycle** | Race conditions on iOS interactive pop, `complete()` without guards (#187326) |
| **Redirect as string return** | Cannot express push-vs-go intent (#188782); recursive redirect gaps (#188014) |
| **Monolithic RouteConfiguration** | Matching, redirects, named routes, and error handling in one 700+ line class |
| **URL sync coupled to navigation** | `window.location` lag (#181142), encoding inconsistencies (#171757, #180373) |
| **ShellRoute key management** | GlobalKey collisions, offstage page interference (#182573, #148768) |
| **extra via JSON codec** | Performance (#179937), silent decode failures (#179992), null on back (#145514) |
| **onEnter/onExit/redirect ordering** | Event loop issues (#179370), pop hangs (#187579, #180002) |
| **StatefulShellBranch state** | Cannot reset branches (#175170, #142867), parameter loss (#164882) |

### 1.2 Navigator 2.0

The framework provides:

- `RouteInformationParser<T>` — URL ↔ app configuration
- `RouterDelegate<T>` — configuration → `Navigator` pages
- `RouteInformationProvider` — OS route events
- `BackButtonDispatcher` — system back

**Strengths:** Platform-correct, restoration-ready, full control.

**Weaknesses:** Extreme boilerplate; no route matching, guards, or URL generation. Every app reinvents routing.

**Flow's approach:** Use Navigator 2.0 as the *rendering layer only*. All routing intelligence lives in Flow's engine.

### 1.3 AutoRoute

Code-gen-first router with `@RoutePage`, `@AutoRouterConfig`, generated `$AppRouter`.

**Strengths:** Excellent compile-time type safety, clean `router.push(UserRoute(id: 42))` API, strong nested/tab support.

**Weaknesses:** Mandatory `build_runner`; generated code obscures behavior; debugging requires reading `.gr.dart`; maintenance concerns.

**Flow learns:** Typed route classes with `.location`, `.go()`, `.push()` — but **without requiring codegen**.

### 1.4 Beamer

`BeamLocation`-centric: each app region owns `pathPatterns`, `buildPages`, and `BeamState`.

**Strengths:** Clean separation of unrelated app regions; declarative page stacks; modular architecture.

**Weaknesses:** Two navigation modes (`beamTo` vs `beamToNamed`) with different semantics; still string-path based; smaller ecosystem.

**Flow learns:** **Location modules** for feature-based route registration; single navigation API regardless of entry point.

### 1.5 Web Framework Routers

| Framework | Strength | Weakness | Flow Adoption |
|-----------|----------|----------|---------------|
| **React Router** | Data routers, loaders, `useNavigate` | React-specific; loader model doesn't map to Flutter | Loader → Guard pipeline; `useNavigate` → `context.flow` |
| **Vue Router** | `beforeEach` guards, named views | String routes default | `beforeEach` → `FlowGuard` chain |
| **Angular Router** | Resolvers, lazy modules | Heavy config | Resolvers → async guards; lazy → deferred route registration |
| **Next.js App Router** | File-system routes, layouts | Server components N/A | Layout routes → `FlowShell`; file-based routing → optional codegen |
| **SwiftUI NavigationStack** | Typed `NavigationPath`, `navigationDestination` | iOS-only | `FlowPath` typed stack; `FlowDestination` registry |
| **Jetpack Navigation** | Safe Args, nested graphs | Android-only | Safe Args → typed route params; graphs → `FlowModule` |

---

## 2. Comparative Analysis

### Why a new router — not a GoRouter fork

GoRouter's issues are **architectural**, not incremental:

1. **Identity crisis:** `RouteMatchList` cannot cleanly represent both "where am I in the route tree" and "what's on the imperative overlay stack" without edge-case explosions.
2. **String coupling:** The entire matching pipeline starts from `Uri.parse(location)` even when the developer navigated with a typed intent.
3. **Synchronous assumptions in async world:** Guards, redirects, and `onExit` interleave without a formal state machine.

Flow solves these at the foundation:

```
GoRouter:  String/URI → MatchList → Pages
Flow:      FlowRoute (typed) → NavigationState → Location (derived) → Pages
```

The URL is an **output**, not an input, for programmatic navigation. URL input (deep links, browser back) goes through the parser to produce typed routes.

---

## 3. Design Principles

1. **Typed routes are canonical** — `UserRoute(id: 42)` not `'/users/42'`
2. **Immutable navigation state** — every transition produces a new `NavigationState`; no in-place mutation
3. **Intent-based navigation** — all APIs dispatch sealed `NavigationIntent` objects
4. **Pipeline, not callbacks** — guards, middleware, and redirects are composable pipeline stages
5. **Separation of stacks** — declarative location stack and imperative overlay stack are distinct data structures merged only at page-build time
6. **Lazy everything** — route tree compiled once; matching is O(path segments); params parsed on demand
7. **Zero unnecessary rebuilds** — `Listenable` granularity at branch/shell level, not whole-router
8. **Codegen optional** — manual route classes are first-class; `flow_generator` is convenience
9. **Testability by construction** — `FlowRouter` accepts injected `NavigationEngine`; no `BuildContext` required for logic
10. **Flutter-native** — implements `RouterConfig`, uses `Page`, `Navigator`, restoration IDs

---

## 4. System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Application Layer                               │
│  context.go(HomeRoute())  │  FlowRouter.config  │  FlowModule.register  │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼─────────────────────────────────────┐
│                         FlowRouter (facade)                               │
│  Implements RouterConfig — wires parser, delegate, provider, dispatcher   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ RouteRegistry │         │ NavigationEngine │         │  UrlSynchronizer │
│ (static tree) │◄───────►│ (state machine)  │◄───────►│  (web/platform)  │
└───────────────┘         └────────┬────────┘         └─────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
            ┌─────────────┐ ┌───────────┐ ┌──────────────┐
            │ MatchEngine │ │ Pipeline  │ │ PageBuilder  │
            │ (trie)      │ │ guards/   │ │ transitions  │
            │             │ │ middleware│ │ shells       │
            └─────────────┘ └───────────┘ └──────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │   FlowRouterDelegate         │
                    │   Navigator + Pages          │
                    └──────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Testable Without Widgets |
|-------|---------------|--------------------------|
| **RouteRegistry** | Compile route tree, named lookup, reverse routing | ✅ |
| **MatchEngine** | URI → `RouteMatch` with path/query/matrix params | ✅ |
| **NavigationEngine** | Apply intents, manage stacks, emit state | ✅ |
| **Pipeline** | Guards, middleware, redirects (ordered, async-safe) | ✅ |
| **PageBuilder** | `RouteMatch` + state → `Page` list per navigator | ✅ (with mock context) |
| **UrlSynchronizer** | Bidirectional URL ↔ state with encoding policy | ✅ |
| **FlowRouterDelegate** | Flutter integration, restoration, observers | Widget tests |

---

## 5. Core Data Models

### 5.1 FlowRoute (sealed hierarchy)

```dart
/// Base for all routes. Subclass per destination.
sealed class FlowRoute {
  const FlowRoute();

  /// Stable route name for named navigation and restoration.
  String get name;

  /// Canonical path pattern, e.g. '/users/:id'
  String get path;

  /// Serialize to URL location. Never construct URLs manually.
  String get location;

  /// Path parameters extracted/embedded in this route.
  Map<String, String> get pathParameters;

  /// Query parameters.
  Map<String, String> get queryParameters;

  /// Optional fragment (#section).
  String? get fragment;
}

/// Example typed route — no codegen required.
final class UserRoute extends FlowRoute {
  const UserRoute({required this.id, this.tab = UserTab.overview});

  final int id;
  final UserTab tab;

  @override
  String get name => 'user';

  @override
  String get path => '/users/:id';

  @override
  String get location => LocationBuilder(this).build();

  // ...
}
```

### 5.2 NavigationState (immutable)

```dart
@immutable
final class NavigationState {
  const NavigationState({
    required this.locationStack,    // declarative "go" stack
    required this.overlayStacks,    // per-navigator imperative pushes
    required this.activeBranches,   // shell branch selection
    this.extra,
    this.restorationId,
  });

  /// The matched route chain for the current declarative location.
  final RouteMatchChain locationStack;

  /// Imperative overlays keyed by NavigatorId (not GlobalKey).
  final Map<NavigatorId, OverlayStack> overlayStacks;

  /// Which branch is active per shell.
  final Map<ShellId, BranchIndex> activeBranches;

  final Object? extra;
  final String? restorationId;
}
```

**Key insight:** Separating `locationStack` from `overlayStacks` eliminates GoRouter's `ImperativeRouteMatch` race conditions and makes URL sync policy explicit.

### 5.3 RouteMatchChain

```dart
@immutable
final class RouteMatchChain {
  const RouteMatchChain({required this.matches, required this.uri});

  final List<RouteMatch> matches;  // root → leaf
  final Uri uri;                   // canonical resolved URI

  RouteMatch get leaf => matches.last;
  RouteMatch? get shellMatch => matches.whereType<ShellMatch>().lastOrNull;
}
```

### 5.4 NavigationIntent (sealed)

```dart
sealed class NavigationIntent {}

final class GoIntent extends NavigationIntent {
  const GoIntent(this.route, {this.extra});
  final FlowRoute route;
  final Object? extra;
}

final class PushIntent extends NavigationIntent {
  const PushIntent(this.route, {this.extra, this.navigatorId});
  final FlowRoute route;
  final Object? extra;
  final NavigatorId? navigatorId;
}

final class PopIntent extends NavigationIntent {
  const PopIntent({this.result, this.navigatorId});
  final Object? result;
  final NavigatorId? navigatorId;
}

// ReplaceIntent, PopUntilIntent, RemoveIntent, ClearStackIntent,
// GoBranchIntent, NavigateIntent (relative), etc.
```

---

## 6. Subsystems

### 6.1 Parser (`src/parser/`)

- **`UriNormalizer`** — trailing slash policy, encoding (RFC 3986), colon handling (#186052)
- **`LocationParser`** — URI → `RouteMatchChain` via MatchEngine
- **`LocationSerializer`** — `FlowRoute` → URI (reverse routing)
- **`MatrixParamParser`** — `;key=value` path matrix parameters
- **`ExtraCodec`** — optional pluggable serialization (not JSON-by-default)

### 6.2 Matcher (`src/matcher/`)

- **`RouteTreeCompiler`** — builds radix trie from `FlowRouteDefinition` list at startup
- **`MatchEngine`** — O(segments) matching with cached trie nodes
- **`RouteConflictDetector`** — compile-time validation (duplicate params, ambiguous patterns)
- **`WildcardMatcher`** — `*`, `**`, optional segments `:id?`

Trie structure (not linear scan like GoRouter's `_getLocRouteMatches`):

```
root
 ├── users/
 │    └── :id → UserRouteDefinition
 ├── settings/
 └── (shell) app/
      ├── dashboard → DashboardRouteDefinition
      └── profile → ProfileRouteDefinition
```

### 6.3 History (`src/history/`)

- **`NavigationHistory`** — records transitions for browser back/forward
- **`HistoryEntry`** — `{ state, source: user|browser|deepLink|restoration }`
- **`BackForwardController`** — manages browser history stack semantics
- **Destructive flow support** — entries can be marked `replace` vs `push` (#162923)

### 6.4 Navigation Engine (`src/navigation/`)

The heart of Flow. Single entry point:

```dart
abstract interface class NavigationEngine {
  NavigationState get state;
  Listenable get listenable;

  Future<NavigationResult> dispatch(NavigationIntent intent);
  Future<NavigationState> resolve(FlowRoute route, {NavigationMode mode});
}
```

**State machine phases for each dispatch:**

```
IDLE → VALIDATING → MATCHING → PIPELINE → APPLYING → SYNCING_URL → IDLE
         │              │           │          │
         └ cancelable   └ cached    └ async    └ immutable new state
```

- **No "Future already completed"** — each operation has a `NavigationTransaction` with single completion (#160696, #139144)
- **Debounced dispatch** — simultaneous taps coalesced (#160504)

### 6.5 Guards (`src/guards/`)

```dart
abstract interface class FlowGuard {
  FutureOr<GuardResult> canActivate(GuardContext context);
  FutureOr<GuardResult> canDeactivate(GuardContext context); // replaces onExit
}

sealed class GuardResult {}

final class Allow extends GuardResult {
  const Allow();
}

final class Redirect extends GuardResult {
  const Redirect(this.route, {this.mode = NavigationMode.go});
  final FlowRoute route;
  final NavigationMode mode; // go | push — solves #188782
}

final class Block extends GuardResult {
  const Block({this.reason});
  final String? reason;
}
```

Guards run in **pipeline order**: global → shell → route. Recursive guard evaluation with cycle detection (max depth configurable).

### 6.6 Middleware (`src/middleware/`)

Request/response pattern adapted for navigation:

```dart
abstract interface class FlowMiddleware {
  FutureOr<void> onBefore(NavigationContext context);
  FutureOr<void> onAfter(NavigationContext context, NavigationResult result);
}
```

Built-in: `LoggingMiddleware`, `AnalyticsMiddleware`, `AuthMiddleware`, `LocalizationMiddleware`.

Middleware cannot block navigation (use guards). Middleware can observe and annotate.

### 6.7 Transitions (`src/transitions/`)

- **`FlowTransition`** — per-route or per-navigation transitions
- **`CustomTransitionPage`** — GoRouter-compatible but decoupled from matching
- **Platform back swipe preservation** (#183252)
- **Per-navigation transition override** (#135550)

### 6.8 Web (`src/web/`)

- **`FlowRouteInformationProvider`** — canonical URL ownership
- **`FlowRouteInformationParser`** — implements `RouteInformationParser<NavigationState>`
- **`UrlSynchronizer`** — decoupled from navigation; batched `history.pushState` / `replaceState`
- **`UrlEncodingPolicy`** — consistent encode/decode (#171757, #162811, #137151)
- **`FlowUrlStrategy`** — wraps `setUrlStrategy` with refresh-safe base href
- **Imperative URL policy** — explicit enum, not boolean hack:

```dart
enum ImperativeUrlPolicy {
  /// URL reflects declarative location only (default, deep-link-safe).
  declarativeOnly,

  /// URL reflects top of merged stack (legacy GoRouter behavior).
  includeOverlays,

  /// URL never changes on push/pop (modal flows).
  frozen,
}
```

### 6.9 Restoration (`src/restoration/`)

- **`FlowRestorationMixin`** on delegate
- **Per-route `restorable` flag** — including shell branches (#142258)
- **RestorationScope compatible** — works inside shells (#174935)
- **Safe match on restore** — no `RangeError` on substring (#185948)

### 6.10 Observer (`src/observer/`)

- **`FlowNavigatorObserver`** — standard observer interface
- **`FlowRouteObserver`** — typed route lifecycle: `didPush(UserRoute)`, `didPop`
- **Dialog-aware state** — `FlowRouter.state` consistent in dialogs (#164566)

### 6.11 Typed Routes (`src/typed_routes/`)

- **`FlowRouteDefinition`** — binds `FlowRoute` subclass to builder, guards, transitions
- **`TypedRouteRegistry`** — `T extends FlowRoute` → definition lookup
- **`RouteAccessor`** — extension methods: `route.go(context)`, `route.push(context)`

### 6.12 Extensions (`src/extensions/`)

```dart
extension FlowNavigation on BuildContext {
  FlowRouter get flow => FlowRouter.of(this);

  Future<T?> push<T>(FlowRoute route, {Object? extra});
  void go(FlowRoute route, {Object? extra});
  void replace(FlowRoute route, {Object? extra});
  void pop<T>([T? result]);
  void popUntil(FlowRoute route, {bool inclusive = false});
  bool canPop({NavigatorId? navigatorId});
}
```

---

## 7. Navigation Semantics

### 7.1 `go` vs `push` vs `replace`

| Operation | Location Stack | Overlay Stack | URL (default) | Animation |
|-----------|---------------|---------------|---------------|-----------|
| `go` | Replace | Clear target navigator overlays | Updated | None for common parent prefix |
| `push` | Unchanged | Push on navigator | Unchanged | Push transition |
| `replace` | Replace leaf | Replace top overlay | Updated | Configurable (#168792) |
| `goBranch` | Switch branch | Preserve branch stacks | Updated | None |

### 7.2 Relative Navigation

```dart
context.navigate(UserSettingsRoute()); // relative to current parent
```

Resolved by walking up the `RouteMatchChain` to find the anchor, then resolving the child path. Debounced to prevent race on fast navigation (#175519).

### 7.3 Return Values

`push` returns `Future<T?>` that completes on:
- `pop(result)` 
- Browser back (configurable: complete with null or cancel)
- Replacement (configurable)

Solves #153546, #171130, #141251.

### 7.4 `extra` Parameter

- Stored in `NavigationState`, not URL
- **Not JSON-encoded by default** — typed `ExtraHolder<T>` for serialization when needed
- Survives back/forward when in history entry
- Solves #179937, #179992, #145514, #146616

---

## 8. Web & Deep Linking

### Cold Start Flow

```
Platform URL
    → FlowRouteInformationParser.parseRouteInformation()
    → UriNormalizer.normalize()
    → MatchEngine.match()
    → Pipeline (guards + redirects)
    → NavigationEngine.setInitialState()
    → FlowRouterDelegate.build() → Navigator pages
```

### Refresh Safety

On web refresh, the full URL is parsed into `NavigationState` from scratch. No dependency on in-memory imperative overlays. `canPop()` reflects the rebuilt state correctly (#181999).

### Deep Link Platforms

| Platform | Entry Point | Flow Handler |
|----------|-------------|--------------|
| Android | Intent URI | `FlowRouteInformationProvider` |
| iOS | Universal Links | same |
| macOS/Windows/Linux | protocol handler | same |
| Web | `window.location` | `FlowUrlStrategy` |

No additional Flow boilerplate beyond platform manifest configuration.

---

## 9. Guards & Middleware

### Pipeline Order

```
1. Global middleware (onBefore)
2. Global guards (canActivate)
3. Shell guards
4. Route guards
5. Global redirect
6. Route redirect
7. Apply navigation
8. Global middleware (onAfter)
9. Deactivate guards (canDeactivate) on popped routes
```

### Recursive Redirects

Unlike GoRouter's `onEnter` "only once" (#188014), Flow's pipeline re-enters from step 2 when a redirect is returned, with:

- Configurable `maxRedirects` (default 5)
- Cycle detection via visited route set
- `Redirect` carries `NavigationMode` (go/push)

### Auth Pattern

```dart
final authGuard = RedirectGuard(
  when: (ctx) => !ctx.auth.isLoggedIn,
  redirectTo: (ctx) => LoginRoute(returnTo: ctx.target.location),
);

FlowRouter(
  guards: [authGuard],
  routes: [...],
);
```

---

## 10. Shell & Branch Navigation

### FlowShell

```dart
FlowShell(
  navigatorId: NavigatorId('root-shell'),
  builder: (context, child) => Scaffold(body: child),
  routes: [...],
)
```

### FlowStatefulShell

```dart
FlowStatefulShell(
  branches: [
    FlowBranch(
      navigatorId: NavigatorId('home'),
      defaultRoute: HomeRoute(),
      routes: [...],
    ),
    FlowBranch(
      navigatorId: NavigatorId('profile'),
      defaultRoute: ProfileRoute(),
      routes: [...],
    ),
  ],
  builder: (context, shell) => NavigationBar(
    selectedIndex: shell.currentIndex,
    onDestinationSelected: shell.goBranch,
    destinations: [...],
  ),
)
```

### Architectural fixes for shell issues

| GoRouter Issue | Flow Solution |
|----------------|---------------|
| Branch state not reset (#142867, #175170) | `branch.reset()` API on `FlowBranchController` |
| Predictive back pops all branches (#188018) | Per-branch `OverlayStack` with isolated pop scope |
| `goBranch` parameter loss (#164882) | `GoBranchIntent` carries full `FlowRoute` |
| NestedScrollView height (#183581) | Shell builder receives `PrimaryScrollController` per branch |
| Offstage pages intercept events (#182573) | `Visibility.maintainState` with `IgnorePointer` on offstage |
| GlobalKey duplicates (#148768) | `NavigatorId` string keys, not auto-generated GlobalKeys |

---

## 11. Performance Strategy

### Targets (vs GoRouter 16.x)

| Benchmark | Target |
|-----------|--------|
| Cold route match (100 routes) | 3× faster |
| Redirect chain (5 deep) | 2× faster |
| `go()` widget rebuilds | 50% fewer |
| Memory per navigation | 40% fewer allocations |

### Techniques

1. **Compiled route trie** — cached at `FlowRouter` construction; invalidated only on `routingConfig` change
2. **Structural sharing** — `NavigationState.copyWith` reuses unchanged branches
3. **Selective listenables** — `ShellListenable`, `BranchListenable` instead of monolithic `refreshListenable`
4. **Lazy param parsing** — query params parsed on first access, not at match time
5. **No JSON for extra** — reference-type `Object?` by default
6. **Const route definitions** — `FlowRouteDefinition` can be `const` where possible
7. **Benchmark suite** — `flow/benchmark/` comparing GoRouter, Beamer, AutoRoute, raw Navigator

---

## 12. Testing Architecture

```dart
// Unit test — no widgets
test('match /users/42', () {
  final engine = NavigationEngine(registry: testRegistry);
  final state = engine.resolveUri(Uri.parse('/users/42'));
  expect(state.locationStack.leaf.route, isA<UserRoute>());
});

// Widget test
testWidgets('navigate to user', (tester) async {
  final router = FlowRouter(routes: testRoutes);
  await tester.pumpWidget(FlowApp(router: router));
  await tester.flow.go(UserRoute(id: 42));
  expect(find.byType(UserPage), findsOneWidget);
});

// Deep link test
test('cold start deep link', () {
  final parser = FlowRouteInformationParser(registry: testRegistry);
  final state = parser.parseSync(RouteInformation(uri: Uri.parse('/users/42')));
  expect(state.locationStack.leaf.route, isA<UserRoute>());
});
```

### Test utilities (`flow_test` package or `src/testing/`)

- `FakeFlowRouter` — records intents without building widgets
- `FlowTester` extension on `WidgetTester`
- `expectRouteIs<T>()` — navigation assertions
- `MockGuard`, `MockMiddleware`

---

## 13. Migration Strategy

### From GoRouter

```dart
// GoRouter
GoRoute(path: '/users/:id', builder: (c, s) => UserPage(id: s.pathParameters['id']!))

// Flow
class UserRoute extends FlowRoute { ... }
FlowRouteDefinition<UserRoute>(
  route: UserRoute,
  builder: (context, route) => UserPage(id: route.id),
)
```

Migration utility (`flow_migration` package):

- `goRouterPathToFlowRoute()` — string path → `FlowRouteDefinition` scaffold
- `GoRouteTreeParser` — parses GoRouter route tree to Flow registry
- Side-by-side running via `FlowGoRouterAdapter` (transitional)

### Compatibility Matrix

| Source | Migration Effort | Tooling |
|--------|-----------------|---------|
| Navigator 1.0 | Medium | `flow_migration` route name mapper |
| Navigator 2.0 | Low | Already close to Flow's model |
| GoRouter | Low-Medium | Path/binding converter |
| AutoRoute | Low | Route class reuse (minus generated router) |
| Beamer | Medium | BeamLocation → FlowModule converter |

---

## 14. Package Structure

```
flow/
├── lib/
│   ├── flow_routing.dart            # Public API barrel
│   └── src/
│       ├── core/                    # FlowRouter, RouterConfig, config
│       ├── parser/                  # URI ↔ route parsing
│       ├── matcher/                 # Route tree, trie matching
│       ├── history/                 # Back/forward, browser history
│       ├── navigation/              # Engine, intents, state machine
│       ├── guards/                  # Guard pipeline
│       ├── middleware/              # Observability middleware
│       ├── transitions/             # Page transitions
│       ├── web/                     # URL sync, platform web
│       ├── restoration/             # State restoration
│       ├── observer/                # Route observers
│       ├── typed_routes/            # FlowRoute, definitions
│       ├── extensions/              # BuildContext extensions
│       ├── shell/                   # Shell & branch routes
│       └── utils/                   # Shared utilities
├── flow_generator/                  # Optional codegen (future)
├── flow_migration/                  # Migration tools (future)
├── flow_test/                       # Testing utilities (future)
├── benchmark/                       # Performance benchmarks (future)
├── example/                         # Example apps (future)
├── docs/
│   ├── ARCHITECTURE.md              # This document
│   ├── GOROUTER_ISSUES.md           # Issue analysis
│   └── API_SPEC.md                  # Phase 2
└── test/
```

---

## 15. Phased Delivery Plan

| Phase | Deliverable | Status |
|-------|-------------|--------|
| **1** | Architecture proposal | ✅ Complete |
| **2** | Public API specification | ✅ [API.md](API.md) |
| **3** | Route matching engine | ✅ `MatchEngine` |
| **4** | Navigation engine | ✅ `NavigationEngine` |
| **5** | Web engine | ✅ Parser + Provider |
| **6** | Typed routing system | ✅ `FlowRoute` |
| **7** | Middleware system | ✅ `FlowMiddleware` |
| **8** | Guard system | ✅ `FlowGuard` |
| **9** | Transition system | ✅ `FlowTransition` |
| **10** | Migration layer | ✅ `go_router_migration.dart` |
| **11** | Benchmarks | ✅ `benchmark/match_benchmark.dart` |
| **12** | Test suite | ✅ 15 tests |
| **13** | Documentation | ✅ docs/ |
| **14** | Example application | ✅ example/ |
| **15** | Production-ready package | ✅ v1.0.0 |

---

## Open Questions for Review

1. **Should `FlowRoute` be a sealed class or an interface?** Sealed enables exhaustive switch; interface allows codegen flexibility.
2. **Separate `flow_web` package?** Keeps core lean for mobile-only apps.
3. **Default `ImperativeUrlPolicy`?** Recommend `declarativeOnly` (breaking from GoRouter default).
4. **`flow_test` as separate package or `package:flow_routing/testing.dart`?** Separate avoids test deps in production.

---

## Approval

This document requires review before proceeding to Phase 2 (Public API Specification).

**Reviewers should validate:**
- [ ] Core data model (`NavigationState` with separated stacks)
- [ ] Pipeline architecture for guards/redirects
- [ ] Typed-route-first API ergonomics
- [ ] GoRouter issue coverage (see `GOROUTER_ISSUES.md`)
- [ ] Package structure and phasing
