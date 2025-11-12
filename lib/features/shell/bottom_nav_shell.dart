
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatefulWidget {
  final int index;
  final Widget child;
  const BottomNavShell({super.key, required this.index, required this.child});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  void _onTap(int i) {
    switch (i) {
      case 0: context.go('/'); break;
      case 1: context.go('/explore'); break;
      case 2: context.go('/events'); break;
      case 3: context.go('/explore'); break; // Discover = Explore for MVP
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.index,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Discover'),
        ],
      ),
    );
  }
}
