import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'web_url_strategy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebUrlStrategy();
  final router = createRouter();
  runApp(FlowDemoApp(router: router));
}

class FlowDemoApp extends StatelessWidget {
  const FlowDemoApp({required this.router, super.key});

  final FlowRouter router;

  @override
  Widget build(BuildContext context) {
    return FlowApp.router(
      router: router,
      title: 'Flow Demo',
      theme: buildFlowTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
    );
  }
}
