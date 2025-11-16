import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          // 🔽 DEV: Metro selector (backed by Firestore)
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
            tile('Eat & Drink', '/admin/eat', Icons.restaurant_outlined),
            tile('Lodging', '/admin/lodging', Icons.hotel_outlined),
            tile('Shops', '/admin/shops', Icons.storefront_outlined),
            tile('Clubs', '/admin/clubs', Icons.group_add_outlined),
            tile('Announcements', '/admin/announcements',
                Icons.campaign_outlined),
            tile('Media', '/admin/media', Icons.perm_media_outlined),
            tile('Users & Roles', '/admin/users', Icons.group_outlined),
            tile('Add Locations', '/admin/locations',
                Icons.location_city_outlined),
            tile('Manage Categories', '/admin/categories',
                Icons.category_outlined),
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

/// DEV: Metro dropdown in the AppBar, backed by Firestore.
/// Uses collectionGroup('metros') so it works across all states.
class _MetroDropdown extends StatefulWidget {
  const _MetroDropdown();

  @override
  State<_MetroDropdown> createState() => _MetroDropdownState();
}

class _MetroDropdownState extends State<_MetroDropdown> {
  /// Selected metro's document path:
  /// e.g. "states/ga/metros/haralson"
  String? _selectedPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('metros')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Small spinner in place of dropdown while loading
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.error_outline, size: 20),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'No metros',
              style: TextStyle(fontSize: 12),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // Default to first metro if nothing selected yet
        final defaultPath = docs.first.reference.path;
        final effectiveSelected = _selectedPath ?? defaultPath;

        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: effectiveSelected,
            icon: const Icon(Icons.arrow_drop_down),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 14,
            ),
            dropdownColor: scheme.surface,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedPath = value);

              // TODO: DEV ONLY
              // Hook this into your "user view" location logic.
              //
              // For example later:
              //   - Parse stateId + metroId from the path
              //   - Update a LocationScope / provider
              //   - Or pass it as a query param when navigating to / (user)
              //
              // final ref = FirebaseFirestore.instance.doc(value);
              // final metroId = ref.id;
              // final stateId = ref.parent.parent?.id;
            },
            items: docs.map((d) {
              final data = d.data();
              final name = (data['name'] as String?) ?? d.id;
              // If you stored stateId on the metro doc, you can show it
              final stateId = data['stateId'] as String?;
              final label = stateId != null ? '$name ($stateId)' : name;

              final path = d.reference.path; // unique value for this metro

              return DropdownMenuItem<String>(
                value: path,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_city_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
