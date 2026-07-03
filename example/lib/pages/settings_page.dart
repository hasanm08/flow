import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../auth/auth_state.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/main_shell.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: FlowColors.backgroundGradient),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: FlowHeroHeader(
              title: 'Settings',
              subtitle: 'Protected by SettingsGuard',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Always on in this demo'),
                  value: true,
                  onChanged: null,
                  secondary: const Icon(Icons.dark_mode),
                ),
                SwitchListTile(
                  title: const Text('Debug Logging'),
                  subtitle: const Text('LoggingMiddleware enabled'),
                  value: true,
                  onChanged: null,
                  secondary: const Icon(Icons.bug_report_outlined),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: FlowColors.error),
                  title: const Text('Sign Out'),
                  onTap: () {
                    authState.logout();
                    context.go(const LoginRoute());
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
