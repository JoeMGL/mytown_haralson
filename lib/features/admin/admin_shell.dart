import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/responsive.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (Responsive.isDesktop(context))
            NavigationRail(
              selectedIndex: _indexForLocation(GoRouterState.of(context).uri.toString()),
              onDestinationSelected: (i) => _goTo(i, context),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.place_outlined), label: Text('Attractions')),
                NavigationRailDestination(icon: Icon(Icons.event_outlined), label: Text('Events')),
                NavigationRailDestination(icon: Icon(Icons.campaign_outlined), label: Text('Announcements')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      appBar: Responsive.isDesktop(context) ? null : AppBar(title: const Text('Admin')),
      drawer: Responsive.isDesktop(context) ? null : Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Visit Haralson Admin')),
            ListTile(title: const Text('Dashboard'), onTap: (){ context.go('/admin'); }),
            ListTile(title: const Text('Attractions'), onTap: (){ context.go('/admin/attractions'); }),
            ListTile(title: const Text('Announcements'), onTap: (){ context.go('/admin/announcements'); }),
          ],
        ),
      ),
    );
  }

  int _indexForLocation(String loc) {
    if (loc.contains('/admin/attractions')) return 1;
    if (loc.contains('/admin/events')) return 2;
    if (loc.contains('/admin/announcements')) return 3;
    return 0;
  }
  void _goTo(int i, BuildContext context) {
    switch (i) {
      case 0: context.go('/admin'); break;
      case 1: context.go('/admin/attractions'); break;
      case 2: context.go('/admin/events'); break;
      case 3: context.go('/admin/announcements'); break;
      case 4: context.go('/admin/settings'); break;
    }
  }
}
