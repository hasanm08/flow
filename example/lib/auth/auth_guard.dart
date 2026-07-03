import 'package:flow_routing/flow_routing.dart';

import '../auth/auth_state.dart';
import '../routes/app_routes.dart';

/// Redirects unauthenticated users to login.
final class AuthGuard extends FlowGuard {
  const AuthGuard();

  @override
  GuardResult canActivate(GuardContext context) {
    final route = context.targetRoute;
    if (route is LoginRoute) return const GuardAllow();
    if (!authState.isLoggedIn) {
      return GuardRedirect(
        LoginRoute(returnTo: route.location),
      );
    }
    return const GuardAllow();
  }
}

/// Protects settings behind authentication.
final class SettingsGuard extends FlowGuard {
  const SettingsGuard();

  @override
  GuardResult canActivate(GuardContext context) {
    if (context.targetRoute is SettingsRoute && !authState.isLoggedIn) {
      return GuardRedirect(const LoginRoute(returnTo: '/settings'));
    }
    return const GuardAllow();
  }
}
