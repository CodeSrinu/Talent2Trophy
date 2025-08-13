import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../home/presentation/player_home_screen.dart';
import '../../drills/presentation/drills_screen.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';

class PlayerShell extends ConsumerStatefulWidget {
  const PlayerShell({super.key});

  @override
  ConsumerState<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends ConsumerState<PlayerShell> {
  int _index = 0;

  final _pages = const [
    PlayerHomeScreen(),
    DrillsScreen(),
    LeaderboardScreen(),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), selectedIcon: Icon(Icons.play_circle_fill), label: 'Drills'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Leaderboard'),
        ],
        backgroundColor: AppConstants.surfaceColor,
        indicatorColor: AppConstants.primaryColor.withAlpha(20),
      ),
    );
  }
}

