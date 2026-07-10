import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlowApp builds with router', (tester) async {
    final router = FlowRouter(
      routes: [
        flow(
          '/',
          name: 'test',
          builder: (context, route) =>
              const Scaffold(body: Center(child: Text('Hello Flow'))),
        ),
      ],
    );

    await tester.pumpWidget(FlowApp.router(router: router, title: 'Test'));
    await tester.pumpAndSettle();

    expect(find.text('Hello Flow'), findsOneWidget);
  });

  testWidgets('context.flow navigates', (tester) async {
    const detail = FlowRoute(name: 'detail', pathTemplate: '/detail');

    final router = FlowRouter(
      routes: [
        flow(
          '/',
          name: 'home',
          builder: (context, route) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.flow(detail),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
        flow(
          '/detail',
          name: 'detail',
          builder: (context, route) =>
              const Scaffold(body: Center(child: Text('Detail'))),
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
