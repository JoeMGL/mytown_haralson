// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visit_haralson/features/admin/events/admin_events_page.dart';
import 'package:visit_haralson/features/admin/locations/admin_location_setup_page.dart';
import 'package:visit_haralson/features/admin/shop/admin_shop_page.dart';
import 'package:visit_haralson/features/user/stay/stay_detail_page.dart';
import 'package:visit_haralson/models/stay.dart';

// MODELS
import 'models/place.dart';
import 'models/eat_and_drink_model.dart';
import 'models/clubs_model.dart';

// SHELLS
import 'app_shell.dart';
import 'features/admin/admin_shell.dart';

// PUBLIC PAGES
import 'features/home/home_page.dart';
import 'features/user/explore/explore_page.dart';
import 'features/user/explore/explore_detail_page.dart';
import 'features/user/events/events_page.dart';
import 'features/eat_and_drink/eat_and_drink_page.dart';
import 'features/eat_and_drink/eat_and_drink_details_page.dart';
import 'features/user/stay/stay_page.dart';
import 'features/user/shop/shop_page.dart';
import 'features/user/shop/shop_detail_page.dart';

// clubs
import 'features/user/clubs/clubs_page.dart';
import 'features/user/clubs/clubs_detail_page.dart';

// ADMIN PAGES
// MODELS
import 'models/place.dart';
import 'models/eat_and_drink_model.dart';
import 'models/clubs_model.dart';
import 'models/shop.dart'; // 👈 ADD THIS
import 'models/stay.dart'; // you can keep this here instead of top if you want

// SHELLS
import 'app_shell.dart';
import 'features/admin/admin_shell.dart';

// ADMIN PAGES
import 'features/admin/dashboard_page.dart';
import 'features/admin/add_attraction_page.dart';
import 'features/admin/events/admin_add_event_page.dart';
import 'features/admin/clubs/edit_club_page.dart';
import 'features/admin/add_dining_page.dart';
import 'features/admin/add_lodging_page.dart';
import 'features/admin/shop/admin_shop_page.dart';
import 'features/admin/shop/add_shops_page.dart';
import 'features/admin/shop/admin_edit_shop_page.dart';
import 'features/admin/users_and_roles_page.dart';
import 'features/admin/add_announcement_page.dart';
import 'features/admin/clubs/add_club_page.dart';
import 'features/admin/clubs/admin_clubs_page.dart';
import 'features/admin/config/global.dart';

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
                  title: place.title, // fixed: Place.name instead of title
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

        // /clubs
        GoRoute(
          path: 'clubs',
          name: 'clubs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Clubs & Groups',
              child: ClubsPage(),
            ),
          ),
          routes: [
            // /clubs/detail
            GoRoute(
              path: 'detail',
              name: 'clubDetail',
              builder: (context, state) {
                final club =
                    state.extra as Club; // from models/clubs_model.dart
                return ClubDetailPage(club: club);
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
        // /shop
        GoRoute(
          path: 'shop',
          name: 'shop',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Shop Local',
              child: ShopPage(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'detail',
              name: 'shopDetail',
              builder: (context, state) {
                final shop = state.extra as Shop;
                return ShopDetailPage(shop: shop);
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
              child: AdminEventsPage(),
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
              child: AdminShopsPage(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminShell(
                  title: 'Add Shop / Business',
                  child: AddShopPage(),
                ),
              ),
            ),
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) {
                final shop = state.extra as Shop;
                return NoTransitionPage(
                  child: AdminShell(
                    title: 'Edit Shop / Business',
                    child: EditShopPage(shop: shop),
                  ),
                );
              },
            ),
          ],
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
          path: 'clubs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Clubs & Groups',
              child: AdminClubsPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'clubs/add',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Add Club / Group',
              child: AddClubPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'clubs/edit',
          pageBuilder: (context, state) {
            final club = state.extra as Club;

            return NoTransitionPage(
              child: AdminShell(
                title: 'Edit Club / Group',
                child: EditClubPage(club: club),
              ),
            );
          },
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
          path: 'locations',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Locations',
              child: AdminLocationSetupPage(),
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
