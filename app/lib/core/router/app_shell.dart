import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Five-tab shell. The Shield tab is always index 0 so SOS is one tap away.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.shield_outlined, Icons.shield_rounded, 'Shield'),
    (Icons.map_outlined, Icons.map_rounded, 'Map'),
    (Icons.directions_walk_outlined, Icons.directions_walk_rounded, 'Escort'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Guardian'),
    (Icons.tune_outlined, Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final (icon, selected, label) in _tabs)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label, tooltip: label),
        ],
      ),
    );
  }
}
