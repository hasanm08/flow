import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flow_example/main.dart';
import 'package:flow_example/router.dart';
import 'package:flow_example/routes/app_routes.dart';

void main() {
  testWidgets('Flow demo app renders home', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(FlowDemoApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Flow'), findsOneWidget);
    expect(find.text('The next-generation Flutter router'), findsOneWidget);
  });

  testWidgets('navigate to user via typed route', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(FlowDemoApp(router: router));
    await tester.pumpAndSettle();

    await router.go(const UserRoute(id: 42));
    await tester.pumpAndSettle();

    expect(find.text('User #42'), findsOneWidget);
  });
}
