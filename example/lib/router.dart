import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../auth/auth_guard.dart';
import '../auth/auth_state.dart';
import '../pages/about_page.dart';
import '../pages/login_page.dart';
import '../pages/settings_page.dart';
import '../pages/user_page.dart';
import '../routes/app_routes.dart';
import '../widgets/main_shell.dart';

FlowRouter createRouter() {
  return FlowRouter(
    initialLocation: '/home',
    routes: [
      flow(
        '/home',
        name: 'home',
        pageKey: 'main-tabs',
        builder: (context, route) => const MainTabScaffold(),
        transition: const FlowTransition.none(),
      ),
      flow(
        '/explore',
        name: 'explore',
        pageKey: 'main-tabs',
        builder: (context, route) => const MainTabScaffold(),
        transition: const FlowTransition.none(),
      ),
      flow(
        '/profile',
        name: 'profile',
        pageKey: 'main-tabs',
        builder: (context, route) => const MainTabScaffold(),
        transition: const FlowTransition.none(),
      ),
      flow(
        '/users/:id',
        name: 'user',
        builder: (context, route) => UserPage(route: route),
        transition: const FlowTransition.slide(),
      ),
      flow(
        '/settings',
        name: 'settings',
        builder: (context, route) => const SettingsPage(),
        guards: const [SettingsGuard()],
      ),
      flow(
        '/login',
        name: 'login',
        builder: (context, route) => LoginPage(route: route),
        transition: const FlowTransition.fade(),
      ),
      flow(
        '/about',
        name: 'about',
        builder: (context, route) => const AboutPage(),
        transition: const FlowTransition.slide(),
      ),
    ],
    guards: const [AuthGuard()],
    middleware: const [LoggingMiddleware()],
    refreshListenable: authState,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.location}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.flow(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
