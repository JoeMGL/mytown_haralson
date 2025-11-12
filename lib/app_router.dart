import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/widgets/responsive.dart';
import 'features/home/home_page.dart';
import 'features/explore/explore_page.dart';
import 'features/events/events_page.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/dashboard_page.dart';
import 'features/admin/attractions_page.dart';
import 'features/admin/add_attraction_page.dart';
import 'features/admin/announcements_page.dart';
import 'features/admin/add_announcement_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'explore',
          name: 'explore',
          builder: (context, state) => const ExplorePage(),
        ),
        GoRoute(
          path: 'events',
          name: 'events',
          builder: (context, state) => const EventsPage(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/attractions',
          name: 'admin-attractions',
          builder: (context, state) => const AdminAttractionsPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'admin-attractions-add',
              builder: (context, state) => const AddAttractionPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/admin/announcements',
          name: 'admin-announcements',
          builder: (context, state) => const AdminAnnouncementsPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'admin-announcements-add',
              builder: (context, state) => const AddAnnouncementPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
