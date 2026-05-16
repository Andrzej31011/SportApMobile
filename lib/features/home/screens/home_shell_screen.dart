import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static const _tabs = <_TabItem>[
    _TabItem(path: '/map', label: 'Mapa', icon: Icons.map_outlined),
    _TabItem(path: '/events', label: 'Wydarzenia', icon: Icons.event_outlined),
    _TabItem(path: '/teams', label: 'Druzyny', icon: Icons.groups_outlined),
    _TabItem(
      path: '/challenges',
      label: 'Wyzwania',
      icon: Icons.emoji_events_outlined,
    ),
    _TabItem(path: '/profile', label: 'Profil', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        destinations: _tabs
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
        onDestinationSelected: (index) {
          final path = _tabs[index].path;
          if (path != location) {
            context.go(path);
          }
        },
      ),
    );
  }

  int _indexForLocation(String value) {
    for (var i = 0; i < _tabs.length; i++) {
      if (value == _tabs[i].path || value.startsWith('${_tabs[i].path}/')) {
        return i;
      }
    }

    return 0;
  }
}

class _TabItem {
  const _TabItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;
}
