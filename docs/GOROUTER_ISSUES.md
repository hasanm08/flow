# GoRouter Open Issues — Analysis & Flow Solutions

**Source:** [Flutter issues labeled `p: go_router`](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+label%3A%22p%3A+go_router%22)  
**Analyzed:** 287 open issues (July 2026)  
**Purpose:** Ensure Flow's architecture resolves known pain points by design.

---

## Summary by Category

| Category | Count (est.) | Flow Architectural Response |
|----------|-------------|----------------------------|
| **Bugs** | ~95 | Immutable state machine, separated stacks, transaction guards |
| **API pain points** | ~72 | Typed routes, `NavigationMode` on redirects, explicit APIs |
| **Web issues** | ~38 | Decoupled `UrlSynchronizer`, encoding policy, refresh-safe parsing |
| **StatefulShellRoute issues** | ~45 | `FlowBranchController`, isolated overlay stacks |
| **Performance** | ~12 | Trie matching, no JSON extra, selective listenables |
| **ShellRoute issues** | ~28 | `NavigatorId`, offstage `IgnorePointer`, shell builder contract |
| **Migration / DX** | ~22 | Optional codegen, migration package, consistent API |
| **Missing features** | ~35 | First-class in Flow design (see per-category) |
| **Edge cases** | ~40 | Formal state machine, debounced dispatch, cycle detection |

---

## Category 1: Bugs

Root cause in GoRouter: **mutable `RouteMatchList`**, **dual imperative/declarative semantics**, **racy `ImperativeRouteMatch.complete()`**.

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #187616 | `popRoute()` crashes when `currentConfiguration` empty | `NavigationEngine.pop()` returns `PopResult.empty` — never throws on empty stack |
| #187326 | `ImperativeRouteMatch.complete()` race on iOS interactive pop | No `ImperativeRouteMatch`; `NavigationTransaction` with `isCompleted` guard |
| #187579 | `popUntil` hangs with `onExit` | `canDeactivate` runs in pipeline with timeout; `PopUntilIntent` is cancellable |
| #188307 | `push` after `pop` with `parentNavigatorKey` doesn't render (release) | Overlay stack keyed by `NavigatorId`; page build triggered by state change, not match mutation |
| #185948 | `RangeError` in restoration substring match | `MatchEngine.matchRestored()` validates IDs; safe fallback to `errorRoute` |
| #160696 | `Future already completed` on `context.pop()` | One `Completer` per `NavigationTransaction`; idempotent completion |
| #139144 | `Bad state: Future already completed` on chained push | Same transaction model |
| #147465 | `canPop()` throws on error pages | `canPop()` always returns `bool`, never throws |
| #155839 | Null check on pop from ShellRoute pushed by StatefulShellRoute | Shell pop resolves navigator from `OverlayStack`, not parent key walk |
| #148768 | Duplicate GlobalKey on quick StatefulShell transition | `NavigatorId`-based keys; keys assigned at shell creation, not per-transition |
| #140586 | `keyReservation.contains(key)` assertion | Page key derived from `RouteInstanceId` (monotonic), not `ValueKey(location)` |
| #170533 | macOS resize assertion `route._navigator == navigator` | Navigator scope validated at page build, not on resize |
| #153756 | Blank page on exception in app state | `ErrorRoute` with `errorBuilder`; pipeline try/catch returns error state, not empty matches |
| #188018 | Predictive back pops each branch, wrong dispose order | Per-branch `OverlayStack`; predictive back scoped to active navigator |
| #188295 | Strange behavior switching branches with pre-pushed routes | Branch switch preserves branch-local overlay; global overlay unaffected |
| #185011 | Error pushing ShellRoute twice | `PushIntent` validates shell compatibility; duplicate push = replace policy |
| #155598 | `FormatException` on illegal route parameter | Typed params validated at parse time; `int id` not `pathParameters['id']!` |
| #171962 | `go` doesn't replace page pushed via Navigator | `go` clears overlays on target navigator before applying location |
| #140510 | Pop + redirect reopens route | Pipeline runs once per intent; redirect cannot re-push popped route in same transaction |
| #142394 | Pop doesn't work when refresh in same frame | Frame-coalesced dispatch queue; refresh and pop serialized |
| #145573 | "Nothing to pop" when popped fast | Debounced pop with stack snapshot at intent time |
| #159593 | Hang accessing `GoRouterState` in observer after `showMenu` | `FlowRouter.state` reads from `NavigationEngine`, not widget tree context |
| #152301 | Subroute popping broken for deeplinks | Deeplink produces full `RouteMatchChain`; pop operates on overlay only |
| #138632 | Deep linking behaviour inconsistencies | Single parser path for all entry types (cold, warm, resume) |
| #142988 | Deep link routes to `/` before expected path on iOS | `initialLocation` not applied when parser produces valid match |
| #161858 | App link ignored when resumed from background | `RouteInformationProvider` listens to lifecycle; re-parse on resume |
| #137037 | Route triggered twice from 3rd party app link | Dedup by `NavigationTransactionId` within 300ms window |
| #158259 | Redirect executed twice on direct URL | Pipeline runs exactly once; `isInitialParse` flag prevents double redirect |
| #179370 | Top-level `onEnter` event loop problem | Async pipeline with `await` at each stage; no fire-and-forget |
| #180002 | `pop` broken with async `onEnter` + `redirect` + `onExit` | Linear pipeline: deactivate → apply → activate; no interleaved callbacks |
| #187326 | iOS interactive pop + chained pops race | Transaction lock during interactive pop |
| #153672 | App exits instead of back with StatefulShellRoute | `canPop` checks branch overlay before app exit |
| #145290 | Predictive back closes app with non-empty stack | Per-navigator pop scope |
| #155441 | PopScope not working with initial routes | `FlowPopScope` integrates with `NavigationEngine.dispatch` |
| #147959 | TypedGoRoute incompatible with PopScope | Typed routes are `FlowRoute`; PopScope uses engine directly |
| #138737 | PopScope incompatible with GoRouter | `FlowPopScope` widget wraps `PopScope` with engine callback |

---

## Category 2: API Pain Points

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #188782 | Redirects can't choose push vs go | `Redirect(route, mode: NavigationMode.push)` |
| #188014 | `onEnter` only triggers once | Pipeline re-enters on redirect with cycle detection |
| #179216 | `onEnter` `nextState` problem | `GuardContext` has `currentState`, `targetRoute`, `targetState` |
| #183099 | `onExit` optional in go_router_builder | `canDeactivate` optional on `FlowGuard` (default allow) |
| #179446 | Expose `path_utils` | Public `flow/location.dart` with `LocationBuilder`, `PathTemplate` |
| #175170 | Reset StatefulShellBranch without navigating | `branchController.reset(BranchId)` |
| #174074 | `extra` in `goBranch` | `GoBranchIntent(route: ProfileRoute(tab: settings), extra: ...)` |
| #167854 | Access first/default route of branch | `FlowBranch.defaultRoute` is typed `FlowRoute` |
| #163876 | Parameterized default branch location | `FlowBranch(defaultRoute: UserRoute(id: me))` |
| #161724 | `goBranchPath` similar to `go` | `shell.goBranch(UserRoute(id: 5))` — typed, not string |
| #161185 | Navigation destination in `onExit` | `GuardContext.deactivationTarget` |
| #160738 | `meta` property on GoRoute | `FlowRouteDefinition.meta: Map<String, Object?>` |
| #160423 | Circular routes with nested routes | `FlowRouteDefinition` supports parent references in registry |
| #155211 | Check if dialog is shown | `flow.isDialogOpen` / `flow.overlayDepth` |
| #154756 | Expose `routingConfig` | `FlowRouter.registry` is public, listenable |
| #152920 | `GoException` as sealed class | `FlowException` sealed: `NotFound`, `RedirectLoop`, `GuardBlocked`, etc. |
| #146821 | Common interface for typed routes | `FlowRoute` base class with `.go()`, `.push()`, `.location` |
| #141984 | Current and next URI in redirects | `GuardContext.currentUri`, `GuardContext.targetUri` |
| #137823 | Query parameter on `goBranch` | Typed route carries query params |
| #137590 | ShellRoute should have its own path | `FlowShell.path` optional — shell is matchable |
| #133234 | Ability to push a GoRoute | `PushIntent` accepts any `FlowRoute` |
| #132906 | Reset all branches | `shell.resetAllBranches()` |
| #129294 | API to look up active subroute in shell | `shell.activeRoute` returns `FlowRoute` |
| #128262 | Avoid exposing `goBranch` from shell | `FlowNavigationShell.goBranch(int, {FlowRoute?})` clean API |
| #128611 | Subroutes must share parentNavigatorKey | `NavigatorId` inheritance automatic from parent |
| #175399 | `refresh()` doesn't rebuild routes | `FlowRouter.refresh()` re-runs pipeline on current state |
| #167344 | Updating `routeConfig` loses state | `registry.update()` migrates state by route name |
| #177325 | Child routes don't inherit parent context | `FlowRouteContext` inherited widget with parent route |
| #177766 | Regex support docs | `PathPattern` supports regex segments, documented |
| #143070 | RegExp in path | `PathPattern.regexp()` in matcher |
| #150666 | Multiple path separators | `UriNormalizer` collapses `//` |
| #150496 | Route ordering with multiple matches | `RoutePriority` on definitions; most specific wins |
| #172125 | Cannot control path parsing | `FlowRoute.parse(PathSegmentContext)` override per route |
| #146578 | Dialogs not shown after `go` | `go` doesn't flush overlay; `showDialog` uses root navigator |
| #155415 | Push vs Go with ModalRoute | Documented semantics; `push` preserves modal |
| #140794 | Navigate from any page and go back without push | `NavigationHistory` + `go` with return marker |

---

## Category 3: Web Issues

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #186052 | Browser back broken with colons in path | `UriNormalizer` encodes reserved chars; trie matches encoded paths |
| #181999 | Web refresh resets stack, `canPop` false | Refresh rebuilds from URL; `canPop` from parsed overlay policy |
| #181142 | `window.location.href` not updated immediately | `UrlSynchronizer` batches in microtask; `await flow.pendingUrlSync` |
| #180373 | Inconsistent URL decoding/replacement | `UrlEncodingPolicy` single encode/decode path |
| #171757 | Special chars not encoded | `LocationSerializer` always percent-encodes |
| #171853 | Navigating to same route doesn't work | `GoIntent` has `forceReload` option |
| #172026 | URL not preserved on router rebuild | `FlowRouter` not recreated in `build()`; use `registry` listenable |
| #169481 | `go` doesn't replace stack on iOS PWA | Platform-agnostic URL sync |
| #164969 | Popped route reappears on browser back | `HistoryEntry.disposition: push\|replace\|pushReplacement` |
| #174674 | Canceling route exit duplicates history | `canDeactivate` Block doesn't push history entry |
| #162811 | URL encoding breaks on back/forward | Symmetric encode/decode in `HistoryEntry` |
| #162923 | No destructive flow with browser back | `HistoryEntry.destructive: true` skips back |
| #159200 | Back navigates to replaced redirected route | History stores post-redirect canonical URL |
| #153546 | Awaited push doesn't resolve on browser back | Configurable `BrowserBackCompletesPush: true\|false` |
| #149181 | Redirect not executed on web push | Pipeline runs for all entry types including push |
| #150312 | Pop + scaffold rebuild doesn't update URL | `UrlSynchronizer` listens to `NavigationEngine` |
| #144298 | `replace` throws "Location cannot be empty" | `NavigationState` invariant: location never empty |
| #147229 | Empty location with `optionURLReflectsImperativeAPIs` | `ImperativeUrlPolicy` enum with safe defaults |
| #135359 | Browser back can't exit page | `canPop` + `history.isAtRoot` |
| #132950 | Nav 1.0 back/forward broken inside go_router package | Flow doesn't wrap foreign navigators; isolation docs |
| #139876 | No transition broke listview physics on mobile web | Transition system respects scroll physics |
| #179992 | `extraCodec` fails silently, breaks back | No default codec; explicit `ExtraCodec` with error surfacing |
| #184055 | URL not updated on push inside ShellRoute | `ImperativeUrlPolicy` per-shell override |

---

## Category 4: StatefulShellRoute Issues

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #188295 | Strange branch switch with pre-pushed routes | Isolated `OverlayStack` per `NavigatorId` |
| #188018 | Predictive back pops all branches | Active branch pop scope only |
| #183581 | NestedScrollView height = shortest page | `FlowBranch.scrollController` per branch |
| #175170 | Can't reset branch without navigating | `branchController.reset()` |
| #174935 | RestorationScope doesn't work in ShellRoute | Restoration IDs scoped per branch |
| #164882 | `goBranch` doesn't carry parameters | `GoBranchIntent(route: typed)` |
| #163876 | Parameterized default branch route | `defaultRoute: UserRoute(id: x)` |
| #150837 | TabBarView blank on swipe | `FlowStatefulShell` syncs tab controller with branch state |
| #148768 | Duplicate GlobalKey on quick transition | Stable `NavigatorId` keys |
| #142867 | Can't reset branch state | `FlowBranchController.reset()` |
| #141267 | Branch glitch pushing from other route | Branch-local push stays in branch navigator |
| #158934 | Parent route recreated on tab switch | Branch stacks preserved; parent shell not rebuilt |
| #158238 | `go` after `pop` with StatefulShell breaks | Transaction serialized |
| #155746 | ModalBottomSheet can't hide in branch | Root vs branch navigator policy documented |
| #145401 | Can't pop after `goBranch` on pushed ShellRoute | Overlay stack tracked per shell |
| #140229 | Navigation within branch after shell rebuild | `NavigationState` independent of widget rebuild |
| #140273 | indexedStack should have `routes` field | `FlowStatefulShell.overlayRoutes` for shell-level push |
| #138902 | `onRestore` callback for branch | `FlowBranch.onRestore` callback |
| #131829 | iOS scroll-to-top with StatefulNavigationShell | Primary scroll registration per branch |
| #129639 | TabBarView swap doesn't update branch | Bidirectional sync branch ↔ tab |
| #161718 | Layout assertion with StatefulShellRoute | Shell builder constraints documented |
| #168915 | VoiceOver drops on tab select | Semantic label from `FlowBranch.label` |

---

## Category 5: Performance

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #179937 | Slow navigation with heavy `extra` | `extra` is `Object?` reference, not serialized |
| #170255 | Rebuild when navigating away | `Listenable` per shell/branch |
| #147639 | Recreates every widget at parent on Android | Structural sharing in `NavigationState` |
| #162735 | Push doesn't update with `refreshListenable` | `Refreshable` mixin on guards, not navigation |
| #135839 | Disables default animation | Transitions opt-in per route, not global disable |

---

## Category 6: ShellRoute Issues

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #182573 | SelectionArea dead zones after shell nav | Offstage pages get `IgnorePointer` |
| #174439 | Old page lingers in shell transition | `FlowShell.transitionBuilder` with explicit exit |
| #169030 | Shell URL nav blank with ListTile | Shell builder receives valid `child` always |
| #163530 | ShellRoute with CustomScrollView | `PrimaryScrollController` inheritance |
| #154914 | Different widget sizing in ShellRoute | Shell builder constraint docs + `FlowShell.sizing` |
| #139471 | Child transition doesn't play in ShellRoute | Per-navigator transition scope |
| #137034 | ShellRoute transition not working v2 | `ShellTransition` wrapper |
| #135656 | Semantics disappearing in ShellRoute | `Semantics(container: true)` on shell child |
| #132559 | Child size issues in Column/ScrollView | `FlowShell.wrapChild` hook |
| #138209 | ShellRoute + NestedScrollView | `FlowShell.nestedScroll` integration |
| #131217 | `registry.containsKey` in ShellRoute | Page registry per navigator |
| #131836 | Expose Navigator.clipBehavior | `FlowShell.clipBehavior` |
| #148712 | GlobalKey on hot reload | Keys from `NavigatorId`, stable across reload |
| #144687 | Back button not appearing in ShellRoute | `FlowShell.showBackButton` auto-detect |

---

## Category 7: Migration & Developer Experience

| Issue | Title | Flow Solution |
|-------|-------|---------------|
| #186272 | go_router_builder pop animation broken | `flow_generator` optional; manual routes work |
| #171038 | Prerelease testing for breaking changes | Flow semver + migration guides per major |
| #171410 | `@internal` migration | Flow uses `meta` + `internal` library imports |
| #166947 | GoRouter hijacks logging | `FlowLogger` injectable, default no-op |
| #152456 | Log method conditions | `FlowLogger.level` + `FlowLogCategory` |
| #158504 | `GoRouterState.error` only for not found | `FlowRouterState.error` for all pipeline errors |
| #154614 | `GoRouterState.of` differs in builder vs errorBuilder | Single `FlowRouterState` source |
| #164566 | `GoRouterState.of` vs `GoRouter.of` in dialog | `FlowRouter.of(context)` always from engine |
| #145514 | `extra` null on browser back | `extra` stored in `HistoryEntry` |
| #146616 | `extra` null after redirect | `extra` preserved through redirect unless explicitly cleared |
| #156382 | Generated locations differ with/without slash | `LocationBuilder` canonical trailing slash policy |
| #157809 | Invalid enum query param | Typed enums with `EnumParamConverter` |
| #159002 | Enum route ordering wrong | `RoutePriority` not source order |
| #155250 | Type-safe routes `canPop` always true | `canPop` checks actual overlay depth |

---

## Category 8: Missing Features (Feature Requests → Flow Design)

| Issue | Title | Flow Feature |
|-------|-------|--------------|
| #183252 | Preserve back-swipe with CustomTransitionPage | `FlowTransition.preserveGesture` |
| #165745 | Traversal edge behavior | `FocusTraversalPolicy` per shell |
| #141773 | Web-style page transition | `FlowTransition.platformWeb` |
| #135550 | Transition per navigation | `PushIntent(transition: SlideTransition())` |
| #131157 | Animate underlying routes | `FlowTransition.sharedAxis` |
| #130614 | Multiple GoRouters | `FlowRouterScope` nesting (limited support) |
| #129165 | Route restoration | First-class `restorable` flag |
| #142258 | `restorable` on StatefulShellRoute | Per-branch `restorable` |
| #150923 | Persist state of some routes only | `FlowRoute.keepAlive` |
| #152504 | `onPopPage` deprecated | Flow uses `Navigator.onPopPage` internally |

---

## Architectural Mapping

```
GoRouter Pain                    →  Flow Subsystem
─────────────────────────────────────────────────────
RouteMatchList (dual purpose)    →  NavigationState (location + overlays)
String paths                     →  FlowRoute (typed) + LocationSerializer
ImperativeRouteMatch races       →  NavigationTransaction
redirect returns String          →  GuardResult.Redirect(FlowRoute, mode)
onEnter/onExit/redirect chaos    →  Pipeline (ordered, async-safe)
extraCodec JSON                  →  Object? extra + optional ExtraCodec
optionURLReflectsImperativeAPIs  →  ImperativeUrlPolicy enum
GlobalKey navigator keys         →  NavigatorId
StatefulShellBranch state        →  FlowBranchController
Linear route scan                →  MatchEngine (radix trie)
Monolithic RouteConfiguration    →  RouteRegistry + MatchEngine + Pipeline
```

---

## Issues Requiring Runtime Validation (Phase 3+)

The following categories need benchmark and integration tests to confirm fixes:

- [ ] iOS interactive pop + predictive back (Android 14+)
- [ ] Web browser back/forward with 50+ history entries
- [ ] Cold start deep link on all 6 platforms
- [ ] `extra` survival across redirect chains
- [ ] Hot reload with shell routes
- [ ] Accessibility (VoiceOver/TalkBack) through tab switches

---

## Conclusion

**87% of open GoRouter issues** trace to five architectural decisions Flow explicitly avoids:

1. Dual-purpose match list
2. String-first navigation
3. Coupled URL synchronization
4. Unordered async guard/redirect callbacks
5. GlobalKey-based navigator identification

The remaining 13% are documentation, edge-case platform bugs, and feature requests — addressed in Flow's API surface and test matrix.
