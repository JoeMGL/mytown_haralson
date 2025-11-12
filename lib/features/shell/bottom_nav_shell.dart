import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../dev/dev_drawer.dart';

class BottomNavShell extends StatelessWidget {
  final int index;
  final Widget child;

  const BottomNavShell({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dev-only hamburger:
      appBar: kDebugMode
          ? AppBar(
              title: const Text('Visit Haralson (DEV)'),
            )
          : null,

      // Drawer automatically adds the hamburger button to the AppBar
      drawer: kDebugMode ? const DevDrawer() : null,

      body: child,

      // your existing bottom nav...
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          // keep your go_router tab switching here if you have it
          // (example)
          switch (i) {
            case 0: // home
              // context.go('/');
              break;
            case 1: // explore
              // context.go('/explore');
              break;
            case 2: // events
              // context.go('/events');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined), label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.event_outlined), label: 'Events'),
        ],
      ),
    );
  }
}
