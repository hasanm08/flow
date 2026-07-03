import 'package:flow/flow.dart';
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
      FlowLeafNode(
        FlowRouteDefinition<HomeRoute>(
          name: 'home',
          pathTemplate: '/home',
          pageKey: 'main-tabs',
          builder: (context, route) => const MainTabScaffold(),
          factory: (_) => const HomeRoute(),
          transition: const FlowTransition.none(),
        ),
      ),
      FlowLeafNode(
        FlowRouteDefinition<ExploreRoute>(
          name: 'explore',
          pathTemplate: '/explore',
          pageKey: 'main-tabs',
          builder: (context, route) => const MainTabScaffold(),
          factory: (_) => const ExploreRoute(),
          transition: const FlowTransition.none(),
        ),
      ),
      FlowLeafNode(
        FlowRouteDefinition<ProfileRoute>(
          name: 'profile',
          pathTemplate: '/profile',
          pageKey: 'main-tabs',
          builder: (context, route) => const MainTabScaffold(),
          factory: (_) => const ProfileRoute(),
          transition: const FlowTransition.none(),
        ),
      ),
      FlowLeafNode(
        FlowRouteDefinition<UserRoute>(
          name: 'user',
          pathTemplate: '/users/:id',
          builder: (context, route) => UserPage(route: route),
          factory: (params) {
            final tabName = params['tab'];
            final tab = UserTab.values.asNameMap()[tabName] ?? UserTab.overview;
            return UserRoute(
              id: int.parse(params['id']!),
              tab: tab,
            );
          },
          transition: const FlowTransition.slide(),
        ),
      ),
      FlowLeafNode(
        FlowRouteDefinition<SettingsRoute>(
          name: 'settings',
          pathTemplate: '/settings',
          builder: (context, route) => const SettingsPage(),
          factory: (_) => const SettingsRoute(),
          guards: const [SettingsGuard()],
        ),
      ),
      FlowLeafNode(
        FlowRouteDefinition<LoginRoute>(
          name: 'login',
          pathTemplate: '/login',
          builder: (context, route) => LoginPage(route: route),
          factory: (params) =>
              LoginRoute(returnTo: params['returnTo']),
          transition: const FlowTransition.fade(),
        ),
      ),
      FlowLeafNode(
        FlowRouteDefinition<AboutRoute>(
          name: 'about',
          pathTemplate: '/about',
          builder: (context, route) => const AboutPage(),
          factory: (_) => const AboutRoute(),
          transition: const FlowTransition.slide(),
        ),
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
              onPressed: () => context.go(const HomeRoute()),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
