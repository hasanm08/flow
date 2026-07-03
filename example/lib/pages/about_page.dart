import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Flow'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: FlowColors.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          FlowColors.gradient.createShader(bounds),
                      child: const Text(
                        'Flow v1.0.0',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A next-generation Flutter router built from first principles. '
                      'Typed routes, pipeline guards, separated navigation stacks, '
                      'and first-class web support.',
                    ),
                    const SizedBox(height: 24),
                    const _FeatureChip('Typed Routes'),
                    const _FeatureChip('Route Guards'),
                    const _FeatureChip('Middleware'),
                    const _FeatureChip('Web URLs'),
                    const _FeatureChip('Deep Linking'),
                    const _FeatureChip('Zero Codegen'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: const Icon(Icons.check, size: 16, color: FlowColors.success),
        label: Text(label),
        backgroundColor: FlowColors.primary.withValues(alpha: 0.1),
      ),
    );
  }
}
