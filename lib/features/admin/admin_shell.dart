import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final String? title;

  const AdminShell({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final isAdminRoute = uri.startsWith('/admin');

    return Scaffold(
      drawer: const _AdminDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        title: Text(title ?? 'Admin Dashboard'),
        actions: [
          // User / Admin toggle buttons
          _RoleButton(
            label: 'User',
            icon: Icons.person_outline,
            active: !isAdminRoute,
            onTap: () {
              if (!uri.startsWith('/admin')) return;
              context.go('/'); // your main app home
            },
          ),
          const SizedBox(width: 8),
          _RoleButton(
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
            active: isAdminRoute,
            onTap: () {
              if (uri.startsWith('/admin')) return;
              context.go('/admin');
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}

/// Drawer with all admin sections
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();

    ListTile tile(String label, String route, IconData icon) {
      final selected = uri == route || uri.startsWith('$route/');
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: selected,
        onTap: () {
          Navigator.of(context).pop(); // close drawer
          context.go(route);
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text(
                'VISIT HARALSON',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Admin Panel'),
            ),
            const Divider(),
            tile('Dashboard', '/admin', Icons.dashboard_outlined),
            tile('Attractions', '/admin/attractions', Icons.park_outlined),
            tile('Events', '/admin/events', Icons.event_outlined),
            tile('Dining', '/admin/dining', Icons.restaurant_outlined),
            tile('Lodging', '/admin/lodging', Icons.hotel_outlined),
            tile('Shops', '/admin/shops', Icons.storefront_outlined),
            tile('Announcements', '/admin/announcements',
                Icons.campaign_outlined),
            tile('Media', '/admin/media', Icons.perm_media_outlined),
            tile('Users & Roles', '/admin/users', Icons.group_outlined),
            tile('Settings', '/admin/settings', Icons.settings_outlined),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        foregroundColor: active ? scheme.onPrimary : scheme.primary,
        backgroundColor: active ? scheme.primary : Colors.transparent,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
