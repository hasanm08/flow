import 'package:flow/flow.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/main_shell.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const _users = [
    (id: 1, name: 'Alex Chen', role: 'Designer'),
    (id: 2, name: 'Jordan Lee', role: 'Engineer'),
    (id: 3, name: 'Sam Rivera', role: 'Product'),
    (id: 4, name: 'Taylor Kim', role: 'DevRel'),
    (id: 5, name: 'Morgan Blake', role: 'Architect'),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
          const SliverToBoxAdapter(
            child: FlowHeroHeader(
              title: 'Explore',
              subtitle: 'Discover users with typed deep links',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = _users[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: FlowColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            user.name[0],
                            style: const TextStyle(
                              color: FlowColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user.role),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              UserRoute(id: user.id).location,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: FlowColors.textSecondary,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                        onTap: () => context.go(UserRoute(id: user.id)),
                      ),
                    ),
                  );
                },
                childCount: _users.length,
              ),
            ),
          ),
        ],
    );
  }
}
