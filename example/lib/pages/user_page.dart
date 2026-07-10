import 'package:flow_routing/flow_routing.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class UserPage extends StatefulWidget {
  const UserPage({required this.route, super.key});

  final FlowRoute route;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late UserTab _tab;
  late int _userId;

  @override
  void initState() {
    super.initState();
    _syncFromRoute();
  }

  @override
  void didUpdateWidget(covariant UserPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) {
      _syncFromRoute();
    }
  }

  void _syncFromRoute() {
    _userId = widget.route.intPathParam('id');
    _tab = _tabFromRoute(widget.route);
  }

  UserTab _tabFromRoute(FlowRoute route) {
    final tabName = route.queryParam('tab');
    return UserTab.values.asNameMap()[tabName] ?? UserTab.overview;
  }

  void _selectTab(UserTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    Router.neglect(
      context,
      () => context.replace(Routes.user(id: _userId, tab: tab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: FlowColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'User #$_userId',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        final location = Routes.user(id: _userId, tab: _tab)
                            .location;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Share: $location')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FlowColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: UserTab.values.map((tab) {
                    final selected = _tab == tab;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Material(
                          color: selected
                              ? FlowColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _selectTab(tab),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                tab.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : FlowColors.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _tabTitle(_tab),
                              key: ValueKey(_tab),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'Location',
                            value: Routes.user(id: _userId, tab: _tab).location,
                          ),
                          _InfoRow(label: 'User ID', value: '$_userId'),
                          _InfoRow(label: 'Tab', value: _tab.name),
                          const Spacer(),
                          _TabBody(tab: _tab, userId: _userId),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tabTitle(UserTab tab) => switch (tab) {
    UserTab.overview => 'Overview',
    UserTab.activity => 'Recent Activity',
    UserTab.settings => 'User Settings',
  };
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.tab, required this.userId});

  final UserTab tab;
  final int userId;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      UserTab.overview => Text(
        'Profile summary for user #$userId — posts, bio, and stats.',
      ),
      UserTab.activity => Text(
        'Recent activity for user #$userId — likes, comments, and shares.',
      ),
      UserTab.settings => Text(
        'Notification and privacy settings for user #$userId.',
      ),
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: FlowColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
