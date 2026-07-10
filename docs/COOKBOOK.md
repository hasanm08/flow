# Flow Cookbook

## Authentication Guard

```dart
final authGuard = RedirectGuard(
  condition: (ctx) =>
      !authService.isLoggedIn && !ctx.targetRoute.isName('login'),
  redirectTo: (ctx) => Routes.loginWithReturn(ctx.targetRoute.location),
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
flow(
  '/detail',
  name: 'detail',
  builder: (context, route) => const DetailPage(),
  transition: const FlowTransition.slide(),
)
```

## Push Modal Without URL Change

```dart
context.flow(Routes.about, push: true);
// URL stays at current location (declarativeOnly policy)
context.pop();
```

## Navigate by Name

```dart
context.flowNamed('user', pathParameters: {'id': '42'});
context.flowNamed('about', push: true);
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
static FlowRoute search({required String query}) => FlowRoute(
  name: 'search',
  pathTemplate: '/search',
  queryParameters: {'q': query},
);

// Routes.search(query: 'flutter').location → "/search?q=flutter"
```

## Testing Navigation

```dart
test('navigates to user', () async {
  final registry = RouteRegistry(routes: testRoutes);
  final engine = NavigationEngine(registry: registry);
  await engine.dispatch(GoIntent(Routes.user(id: 1)));
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
