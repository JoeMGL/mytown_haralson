// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visit_haralson/features/stay/stay_detail_page.dart';
import 'package:visit_haralson/models/stay.dart';

// MODELS
import 'models/place.dart';
import 'models/eat_and_drink_model.dart';

// SHELLS
import 'app_shell.dart';
import 'features/admin/admin_shell.dart';

// PUBLIC PAGES
import 'features/home/home_page.dart';
import 'features/explore/explore_page.dart';
import 'features/explore/explore_detail_page.dart';
import 'features/events/events_page.dart';
import 'features/eat_and_drink/eat_and_drink_page.dart';
import 'features/eat_and_drink/eat_and_drink_details_page.dart';
import 'features/stay/stay_page.dart';

// ADMIN PAGES
import 'features/admin/dashboard_page.dart';
import 'features/admin/add_attraction_page.dart';
import 'features/admin/add_event_page.dart';
import 'features/admin/add_dining_page.dart';
import 'features/admin/add_lodging_page.dart';
import 'features/admin/add_shops_page.dart';
import 'features/admin/users_and_roles_page.dart';
import 'features/admin/add_announcement_page.dart';
import 'features/admin/config/global.dart'; // adjust if your file is named differently

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // -------- PUBLIC --------
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AppShell(
          title: 'Home',
          child: HomePage(),
        ),
      ),
      routes: [
        // /explore
        GoRoute(
          path: 'explore',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Explore',
              child: ExplorePage(),
            ),
          ),
          routes: [
            // /explore/detail
            GoRoute(
              path: 'detail',
              name: 'exploreDetail',
              builder: (context, state) {
                final place = state.extra as Place;

                return ExploreDetailPage(
                  title: place.title, // Place.name (not title)
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

        // /events
        GoRoute(
          path: 'events',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Events',
              child: EventsPage(),
            ),
          ),
        ),

        // /eat
        GoRoute(
          path: 'eat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Eat & Drink',
              child: EatAndDrinkPage(),
            ),
          ),
          routes: [
            // /eat/detail
            GoRoute(
              path: 'detail',
              name: 'eatDetail',
              builder: (context, state) {
                final eat = state.extra as EatAndDrink;

                return EatAndDrinkDetailsPage(
                  title: eat.name,
                  imageUrl: eat.imageUrl,
                  heroTag: eat.heroTag,
                  description: eat.description,
                  hours: eat.hours,
                  tags: eat.tags,
                  mapQuery: eat.mapQuery,
                  phone: eat.phone,
                  website: eat.website,
                );
              },
            ),
          ],
        ),

        // /stay
        GoRoute(
          path: 'stay',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Stay',
              child: StayPage(),
            ),
          ),
          routes: [
            // /stay/detail
            GoRoute(
              path: 'detail',
              name: 'stayDetail',
              builder: (context, state) {
                final stay = state.extra as Stay;
                return StayDetailPage(stay: stay);
              },
            ),
          ],
        ),
      ],
    ),

    // -------- ADMIN --------
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AdminShell(
          title: 'Dashboard',
          child: AdminDashboardPage(),
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
              child: AddEatAndDrinkPage(),
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
              child: AddAnnouncementPage(),
            ),
          ),
        ),
      ],
    ),
  ],
);
