import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DevDrawer extends StatelessWidget {
  const DevDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide entirely outside debug
    if (!kDebugMode) return const SizedBox.shrink();

    final items = <_DevItem>[
      _DevItem('Home', '/', Icons.home),
      _DevItem('Explore', '/explore', Icons.travel_explore),
      _DevItem('Events', '/events', Icons.event),
      _DevItem('—', null, null), // divider
      _DevItem('Admin Panel', '/admin', Icons.admin_panel_settings),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final it = items[i];
            if (it.route == null) {
              return const SizedBox(height: 8); // spacer/divider row
            }
            return ListTile(
              leading: Icon(it.icon),
              title: Text(it.label),
              onTap: () {
                Navigator.of(context).pop(); // close drawer
                context.go(it.route!);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DevItem {
  final String label;
  final String? route;
  final IconData? icon;
  _DevItem(this.label, this.route, this.icon);
}
