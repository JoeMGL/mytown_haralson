import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String? title;
  const AppShell({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final path = state.uri.toString();
    final isAdmin = path.startsWith('/admin');

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? (isAdmin ? 'Admin' : 'Visit Haralson')),
        actions: [
          const SizedBox(width: 8),
          _RoleSwitcher(
              isAdmin: false,
              active: !isAdmin,
              onTap: () {
                // Choose your public landing route (update if your home differs)
                if (!path.startsWith('/admin')) return;
                context.go('/');
              }),
          const SizedBox(width: 8),
          _RoleSwitcher(
              isAdmin: true,
              active: isAdmin,
              onTap: () {
                if (path.startsWith('/admin')) return;
                context.go('/admin');
              }),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final bool isAdmin;
  final bool active;
  final VoidCallback onTap;
  const _RoleSwitcher({
    required this.isAdmin,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = isAdmin ? 'Admin' : 'User';
    final scheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: active ? scheme.onPrimary : scheme.primary,
        backgroundColor: active ? scheme.primary : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
          size: 18),
      label: Text(label),
    );
  }
}
