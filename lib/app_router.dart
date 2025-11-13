import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visit_haralson/features/admin/add_announcement_page.dart';
import 'package:visit_haralson/features/admin/add_attraction_page.dart';
import 'package:visit_haralson/features/admin/add_event_page.dart';
import 'package:visit_haralson/features/admin/config/global.dart';
import 'app_shell.dart';

import 'models/place.dart';

// PUBLIC PAGES
import 'features/home/home_page.dart';
import 'features/explore/explore_page.dart';
import 'features/explore/explore_detail_page.dart';
import 'features/events/events_page.dart';

// ADMIN PAGES
import 'features/admin/dashboard_page.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/add_dining_page.dart';
import 'features/admin/add_lodging_page.dart';
import 'features/admin/add_shops_page.dart';
import 'features/admin/users_and_roles_page.dart';
// import other admin pages…

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // -------- PUBLIC --------
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const AppShell(
          title: 'Home',
          child: HomePage(), // your public home
        ),
      ),
      routes: [
        GoRoute(
          path: '/explore',
          name: 'explore',
          builder: (context, state) => const ExplorePage(),
          routes: [
            // 🔹 Explore detail page
            GoRoute(
              path: 'detail',
              name: 'exploreDetail',
              builder: (context, state) {
                final place = state.extra as Place;

                return ExploreDetailPage(
                  title: place.title,
                  imageUrl: place.imageUrl,
                  heroTag: place.heroTag,
                  description: place.description,
                  hours: place.hours,
                  tags: place.tags,
                  mapQuery: place.mapQuery,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'events',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Events',
              child: EventsPage(),
            ),
          ),
        ),
      ],
    ),

    // -------- ADMIN --------
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AdminShell(
          title: 'Dashboard',
          child: AdminDashboardPage(), // content-only widget
        ),
      ),
      routes: [
        GoRoute(
          path: 'attractions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Attractions',
              child: AddAttractionPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'events',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Events',
              child: AddEventPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'dining',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Dining',
              child: AddDiningPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'shops',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Shops',
              child: AddShopsPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'lodging',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Lodging',
              child: AddLodgingPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'users',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Users & Roles',
              child: UsersAndRolesPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Settings',
              child: AdminSettingsPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'announcements',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Announcements',
              child: AddAnnouncementPage(), // TODO: AnnouncementsAdminPage()
            ),
          ),
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminShell(
                  title: 'Add Announcement',
                  child: Placeholder(), // TODO: AddAnnouncementPage()
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
