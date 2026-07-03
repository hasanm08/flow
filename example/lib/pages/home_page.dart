import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/main_shell.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
          SliverToBoxAdapter(
            child: FlowHeroHeader(
              title: 'Flow',
              subtitle: 'The next-generation Flutter router',
              trailing: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () => context.push(const AboutRoute()),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _LocationCard(),
                const SizedBox(height: 20),
                FeatureCard(
                  icon: Icons.bolt,
                  title: 'Typed Navigation',
                  description: 'Navigate with UserRoute(id: 42) — URLs auto-generated',
                  onTap: () => context.go(const UserRoute(id: 42)),
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.shield_outlined,
                  title: 'Route Guards',
                  description: 'AuthGuard protects routes via pipeline',
                  onTap: () => context.go(const SettingsRoute()),
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.layers_outlined,
                  title: 'Push & Overlay Stack',
                  description: 'Imperative push without changing URL',
                  onTap: () => context.push(const AboutRoute()),
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  icon: Icons.public,
                  title: 'Web Ready',
                  description: 'Clean URLs, browser history, refresh-safe',
                  onTap: () => context.go(const ExploreRoute()),
                ),
              ]),
            ),
          ),
        ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    final location = context.flow.location;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FlowColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: FlowColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.link, size: 18, color: FlowColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Current Location',
              style: TextStyle(
                color: FlowColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              location,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generated from ${const HomeRoute().runtimeType}',
              style: const TextStyle(
                color: FlowColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
