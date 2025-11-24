// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String? title;

  const AppShell({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();

    return Scaffold(
      drawer: const _UserMainDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        title: Text(title ?? _titleForRoute(uri)),
      ),
      body: SafeArea(child: child),
    );
  }

  /// Fallback title based on route if none is provided.
  static String _titleForRoute(String uri) {
    if (uri.startsWith('/explore')) return 'Explore';
    if (uri.startsWith('/events')) return 'Events';
    if (uri.startsWith('/eat')) return 'Eat & Drink';
    if (uri.startsWith('/stay')) return 'Stay';
    if (uri.startsWith('/clubs')) return 'Clubs & Groups';
    if (uri.startsWith('/shop')) return 'Shop Local';
    if (uri.startsWith('/map')) return 'Map';
    if (uri.startsWith('/favorites')) return 'Favorites';
    if (uri.startsWith('/announcements')) return 'Announcements';
    if (uri.startsWith('/trip-planner')) return 'Trip Planner';
    if (uri.startsWith('/passport')) return 'Local Passport';
    if (uri.startsWith('/rewards')) return 'Rewards & Discounts';
    if (uri.startsWith('/visitor-guide')) return 'Visitor Guide';
    if (uri.startsWith('/faq')) return 'FAQ';
    if (uri.startsWith('/contact')) return 'Contact & Feedback';
    if (uri.startsWith('/settings')) return 'Settings';
    if (uri.startsWith('/legal')) return 'Legal';
    return 'Visit Haralson';
  }
}

/// Main drawer for public / user routes
class _UserMainDrawer extends StatelessWidget {
  const _UserMainDrawer();

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();

    ListTile navTile(String label, String route, IconData icon) {
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

    ListTile staticTile(String label, IconData icon, {VoidCallback? onTap}) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: () {
          Navigator.of(context).pop();
          onTap?.call();
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
              subtitle: Text('Discover • Eat • Stay • Shop'),
            ),
            const Divider(),

            // ⭐ CORE NAVIGATION (existing public routes)
            navTile('Home', '/', Icons.home_outlined),
            navTile('Explore', '/explore', Icons.explore_outlined),
            navTile('Events', '/events', Icons.event_outlined),
            navTile('Eat & Drink', '/eat', Icons.restaurant_outlined),
            navTile('Stay', '/stay', Icons.hotel_outlined),
            navTile('Clubs & Groups', '/clubs', Icons.groups_2_outlined),
            navTile('Shop Local', '/shop', Icons.storefront_outlined),

            const Divider(),

            // 🗺️ TOOLS / UTILITIES
            navTile('Map', '/map', Icons.map_outlined),
            navTile('Favorites', '/favorites', Icons.favorite_outline),
            navTile('Announcements', '/announcements', Icons.campaign_outlined),
            navTile('Trip Planner', '/trip-planner', Icons.event_note_outlined),

            const Divider(),

            // 🎮 ENGAGEMENT / GAMIFICATION
            navTile(
              'Local Passport',
              '/passport',
              Icons.emoji_events_outlined,
            ),
            navTile(
              'Rewards & Discounts',
              '/rewards',
              Icons.card_giftcard_outlined,
            ),

            const Divider(),

            // 📘 VISITOR INFORMATION
            navTile(
              'Visitor Guide',
              '/visitor-guide',
              Icons.menu_book_outlined,
            ),
            navTile('FAQ', '/faq', Icons.help_outline),
            navTile(
              'Contact & Feedback',
              '/contact',
              Icons.mail_outline,
            ),

            const Divider(),

            // ⚙️ SYSTEM / LEGAL
            navTile('Settings', '/settings', Icons.settings_outlined),
            navTile('Legal', '/legal', Icons.info_outline),

            const Divider(),

            // 👨‍💻 DEV / STAFF ONLY
            staticTile(
              'Admin (Staff)',
              Icons.admin_panel_settings_outlined,
              onTap: () {
                context.go('/admin');
              },
            ),
            staticTile(
              'Onboarding',
              Icons.app_registration_outlined,
              onTap: () {
                context.go('/onboarding');
              },
            )
          ],
        ),
      ),
    );
  }
}
