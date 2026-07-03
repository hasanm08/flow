import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../auth/auth_state.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/main_shell.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
          SliverToBoxAdapter(
            child: FlowHeroHeader(
              title: 'Profile',
              subtitle: authState.isLoggedIn ? 'Signed in' : 'Guest mode',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: FlowColors.gradient,
                      boxShadow: [
                        BoxShadow(
                          color: FlowColors.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    authState.isLoggedIn ? 'Flow Developer' : 'Guest User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _ActionTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.go(const SettingsRoute()),
                ),
                _ActionTile(
                  icon: Icons.person_outline,
                  label: 'View My Profile',
                  subtitle: const UserRoute(id: 42).location,
                  onTap: () => context.go(const UserRoute(id: 42)),
                ),
                _ActionTile(
                  icon: authState.isLoggedIn ? Icons.logout : Icons.login,
                  label: authState.isLoggedIn ? 'Sign Out' : 'Sign In',
                  onTap: () {
                    if (authState.isLoggedIn) {
                      authState.logout();
                      context.go(const LoginRoute());
                    } else {
                      context.go(const LoginRoute(returnTo: '/profile'));
                    }
                  },
                ),
              ]),
            ),
          ),
        ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: FlowColors.primary),
          title: Text(label),
          subtitle: subtitle != null
              ? Text(subtitle!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
