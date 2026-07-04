import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlowApp builds with router', (tester) async {
    final router = FlowRouter(
      routes: [
        FlowLeafNode(
          FlowRouteDefinition<_TestRoute>(
            name: 'test',
            pathTemplate: '/',
            builder: (context, route) =>
                const Scaffold(body: Center(child: Text('Hello Flow'))),
            factory: (_) => const _TestRoute(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(FlowApp.router(router: router, title: 'Test'));
    await tester.pumpAndSettle();

    expect(find.text('Hello Flow'), findsOneWidget);
  });

  testWidgets('context.go navigates', (tester) async {
    final router = FlowRouter(
      routes: [
        FlowLeafNode(
          FlowRouteDefinition<_HomeRoute>(
            name: 'home',
            pathTemplate: '/',
            builder: (context, route) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => context.go(const _DetailRoute()),
                  child: const Text('Go'),
                ),
              ),
            ),
            factory: (_) => const _HomeRoute(),
          ),
        ),
        FlowLeafNode(
          FlowRouteDefinition<_DetailRoute>(
            name: 'detail',
            pathTemplate: '/detail',
            builder: (context, route) =>
                const Scaffold(body: Center(child: Text('Detail'))),
            factory: (_) => const _DetailRoute(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(FlowApp.router(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.text('Detail'), findsOneWidget);
  });
}

final class _TestRoute extends FlowRoute {
  const _TestRoute();
  @override
  String get name => 'test';
  @override
  String get pathTemplate => '/';
}

final class _HomeRoute extends FlowRoute {
  const _HomeRoute();
  @override
  String get name => 'home';
  @override
  String get pathTemplate => '/';
}

final class _DetailRoute extends FlowRoute {
  const _DetailRoute();
  @override
  String get name => 'detail';
  @override
  String get pathTemplate => '/detail';
}
