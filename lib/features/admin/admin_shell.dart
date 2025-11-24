// lib/features/admin/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final user = FirebaseAuth.instance.currentUser;

    // If somehow we're here with no user on an /admin route, push to login.
    if (user == null && isAdminRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login?from=$uri');
      });
      return const SizedBox.shrink();
    }

    // If no user AND not an admin route, just render normal shell (dev use)
    if (user == null && !isAdminRoute) {
      return _buildScaffold(context, uri, isAdminRoute);
    }

    // If user exists, check Firestore role
    if (!isAdminRoute) {
      // Not an admin route – no role enforcement needed, just render shell
      return _buildScaffold(context, uri, isAdminRoute);
    }

    final usersRef = FirebaseFirestore.instance.collection('users');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: usersRef.doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _UnauthorizedScaffold(
            title: title ?? 'Admin',
            reason: 'No user record found. Admin access is restricted.',
          );
        }

        final data = snapshot.data!.data()!;
        final role = data['role'] as String? ?? 'user';

        if (role != 'admin') {
          return _UnauthorizedScaffold(
            title: title ?? 'Admin',
            reason: 'You do not have admin access for this site.',
          );
        }

        // ✅ Authorized admin – render normal admin shell
        return _buildScaffold(context, uri, isAdminRoute, showLogout: true);
      },
    );
  }

  /// Builds the main Scaffold with drawers, role toggle, and optional Logout.
  Widget _buildScaffold(
    BuildContext context,
    String uri,
    bool isAdminRoute, {
    bool showLogout = false,
  }) {
    return Scaffold(
      drawer: isAdminRoute ? const _AdminDrawer() : const _UserDevDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        title: Text(
          title ?? (isAdminRoute ? 'Admin Dashboard' : 'Visit Haralson'),
        ),
        actions: [
          // 🔁 Quick user/admin toggle
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
          const SizedBox(width: 8),

          // 🔓 Logout icon (only when showLogout == true)
          if (showLogout)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go('/'); // back to public home
                }
              },
            ),
          const SizedBox(width: 12),
        ],
      ),

      // 🔑 KEY FIX: keep the same State for the current route
      body: SafeArea(
        child: KeyedSubtree(
          key: ValueKey(uri),
          child: child,
        ),
      ),
    );
  }
}

/// Unauthorized screen used when user is logged in but not an admin.
class _UnauthorizedScaffold extends StatelessWidget {
  final String title;
  final String reason;

  const _UnauthorizedScaffold({
    required this.title,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uri = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · $title'),
        actions: [
          IconButton(
            tooltip: 'Back to site',
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  'Admin Access Required',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Sign out current user (anon or non-admin)
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      context.go('/login?from=$uri');
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with staff account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to site'),
                ),
              ],
            ),
          ),
        ),
      ),
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
          // Close the drawer without touching Navigator stack ✅
          final scaffold = Scaffold.maybeOf(context);
          scaffold?.closeDrawer();

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
            tile('Claims', '/admin/claims', Icons.business_center_outlined),
            tile('Feedback', '/admin/feedback', Icons.feedback_outlined),
            tile('Manage Sections', '/admin/sections', Icons.category_rounded),
            tile('Manage Categories', '/admin/categories',
                Icons.category_outlined),
            tile('Settings', '/admin/settings', Icons.settings_outlined),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Go to User Home'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Dev drawer for the USER side routes (matching app_router.dart)
class _UserDevDrawer extends StatelessWidget {
  const _UserDevDrawer();

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
              subtitle: Text('User View (DEV)'),
            ),
            const Divider(),
            tile('Home', '/', Icons.home_outlined),
            tile('Explore', '/explore', Icons.explore_outlined),
            tile('Events', '/events', Icons.event_outlined),
            tile('Eat & Drink', '/eat', Icons.restaurant_outlined),
            tile('Stay', '/stay', Icons.hotel_outlined),
            tile('Clubs & Groups', '/clubs', Icons.groups_2_outlined),
            tile('Shop Local', '/shop', Icons.storefront_outlined),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Go to Admin'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/admin');
              },
            ),
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
  /// Selected metro's document path: e.g. "states/ga/metros/haralson"
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
              // TODO: hook into your location provider.
            },
            items: docs.map((d) {
              final data = d.data();
              final name = (data['name'] as String?) ?? d.id;
              final stateId = data['stateId'] as String?;
              final label = stateId != null ? '$name ($stateId)' : name;
              final path = d.reference.path;

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
