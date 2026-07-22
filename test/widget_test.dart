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

  testWidgets('FlowShellNode.builder wraps the matched page', (tester) async {
    var shellBuilds = 0;

    final router = FlowRouter(
      initialLocation: '/app/home',
      routes: [
        FlowShellNode(
          pathTemplate: '/app',
          navigatorId: const NavigatorId('shell'),
          builder: (context, child) {
            shellBuilds++;
            return Scaffold(
              appBar: AppBar(title: const Text('Shell')),
              body: child,
            );
          },
          children: [
            flow(
              '/home',
              name: 'home',
              builder: (context, route) => const Text('Home Body'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(FlowApp.router(router: router));
    await tester.pumpAndSettle();

    expect(shellBuilds, greaterThan(0));
    expect(find.text('Shell'), findsOneWidget);
    expect(find.text('Home Body'), findsOneWidget);
  });

  testWidgets('FlowStatefulShellNode.builder receives active child', (
    tester,
  ) async {
    var shellBuilds = 0;

    final router = FlowRouter(
      initialLocation: '/home',
      routes: [
        FlowStatefulShellNode(
          pathTemplate: '/',
          builder: (context, shell) {
            shellBuilds++;
            return Scaffold(
              body: shell.child,
              bottomNavigationBar: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: shell.goBranch,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
          branches: [
            FlowBranchNode(
              navigatorId: const NavigatorId('home'),
              defaultLocation: '/home',
              children: [
                flow(
                  '/home',
                  name: 'home',
                  builder: (context, route) => const Text('Home Tab'),
                ),
              ],
            ),
            FlowBranchNode(
              navigatorId: const NavigatorId('profile'),
              defaultLocation: '/profile',
              children: [
                flow(
                  '/profile',
                  name: 'profile',
                  builder: (context, route) => const Text('Profile Tab'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(FlowApp.router(router: router));
    await tester.pumpAndSettle();

    expect(shellBuilds, greaterThan(0));
    expect(find.text('Home Tab'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Tab'), findsOneWidget);
  });
}
