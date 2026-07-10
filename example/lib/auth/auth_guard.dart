import 'package:flow_routing/flow_routing.dart';

import '../auth/auth_state.dart';
import '../routes/app_routes.dart';

/// Redirects unauthenticated users to login.
final class AuthGuard extends FlowGuard {
  const AuthGuard();

  @override
  GuardResult canActivate(GuardContext context) {
    final route = context.targetRoute;
    if (route.isName('login')) return const GuardAllow();
    if (!authState.isLoggedIn) {
      return GuardRedirect(Routes.loginWithReturn(route.location));
    }
    return const GuardAllow();
  }
}

/// Protects settings behind authentication.
final class SettingsGuard extends FlowGuard {
  const SettingsGuard();

  @override
  GuardResult canActivate(GuardContext context) {
    if (context.targetRoute.isName('settings') && !authState.isLoggedIn) {
      return GuardRedirect(Routes.loginWithReturn('/settings'));
    }
    return const GuardAllow();
  }
}
