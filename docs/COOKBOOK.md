# Flow Cookbook

## Authentication Guard

```dart
final authGuard = RedirectGuard(
  condition: (ctx) => !authService.isLoggedIn && ctx.targetRoute is! LoginRoute,
  redirectTo: (ctx) => LoginRoute(returnTo: ctx.targetRoute.location),
);

FlowRouter(routes: [...], guards: [authGuard]);
```

## Async Guard

```dart
class RoleGuard extends FlowGuard {
  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    final role = await authService.getRole();
    if (role != 'admin') return const GuardBlock(reason: 'Admin only');
    return const GuardAllow();
  }
}
```

## Custom Transition

```dart
FlowRouteDefinition<DetailRoute>(
  ...
  transition: const FlowTransition.slide(),
)
```

## Push Modal Without URL Change

```dart
context.push(const AboutRoute());
// URL stays at current location (declarativeOnly policy)
```

## Refresh on Auth Change

```dart
FlowRouter(
  routes: [...],
  refreshListenable: authState,
);
```

## Error Page

```dart
FlowRouter(
  routes: [...],
  errorBuilder: (context, state) => NotFoundPage(location: state.location),
);
```

## Logging Middleware

```dart
FlowRouter(
  routes: [...],
  middleware: [LoggingMiddleware()],
);
```

## Query Parameters

```dart
final class SearchRoute extends FlowRoute {
  const SearchRoute({required this.query});
  final String query;

  @override
  String get pathTemplate => '/search';
  @override
  Map<String, String> get queryParameters => {'q': query};
}

// location → "/search?q=flutter"
```

## Testing Navigation

```dart
test('navigates to user', () async {
  final registry = RouteRegistry(routes: testRoutes);
  final engine = NavigationEngine(registry: registry);
  await engine.dispatch(const GoIntent(UserRoute(id: 1)));
  expect(engine.state.location, '/users/1');
});
```

## Widget Test

```dart
testWidgets('tap navigates', (tester) async {
  await tester.pumpWidget(FlowApp.router(router: router));
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
  expect(find.text('Detail'), findsOneWidget);
});
```
