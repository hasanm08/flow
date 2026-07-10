import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../auth/auth_state.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({required this.route, super.key});

  final FlowRoute route;

  @override
  Widget build(BuildContext context) {
    final returnTo = route.queryParam('returnTo');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: FlowColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: FlowColors.gradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lock_open,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome to Flow',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to access protected routes',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FlowColors.textSecondary),
                        ),
                        if (returnTo != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Return to: $returnTo',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: FlowColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              authState.login();
                              if (returnTo != null && returnTo.isNotEmpty) {
                                context.flowRouter.engine.dispatch(
                                  SetLocationIntent(returnTo),
                                );
                              } else {
                                context.flow(Routes.home);
                              }
                            },
                            child: const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.flow(Routes.home),
                          child: const Text('Continue as Guest'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
