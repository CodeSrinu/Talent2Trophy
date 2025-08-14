import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import 'scout_dashboard_screen.dart';
import 'scout_inbox_screen.dart';

class ScoutShell extends ConsumerStatefulWidget {
  const ScoutShell({super.key});

  @override
  ConsumerState<ScoutShell> createState() => _ScoutShellState();
}

class _ScoutShellState extends ConsumerState<ScoutShell> {
  int _index = 0;

  final _pages = const [
    ScoutDashboardScreen(),
    ScoutInboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Inbox'),
        ],
        backgroundColor: AppConstants.surfaceColor,
        indicatorColor: AppConstants.primaryColor.withAlpha(20),
      ),
    );
  }
}

