import 'package:flutter/material.dart';

import '../core/flow_router.dart';

/// Convenience wrapper for [MaterialApp.router] with Flow.
class FlowApp extends StatelessWidget {
  const FlowApp.router({
    required this.router,
    this.title = 'Flow App',
    this.theme,
    this.darkTheme,
    this.themeMode,
    super.key,
  });

  final FlowRouter router;
  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router.config,
    );
  }
}
