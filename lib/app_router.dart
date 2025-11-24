// lib/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ADMIN
import 'package:visit_haralson/features/admin/events/admin_events_page.dart';
import 'package:visit_haralson/features/admin/locations/admin_location_setup_page.dart';
import 'package:visit_haralson/features/admin/shop/admin_shop_page.dart';
import 'package:visit_haralson/features/user/stay/stay_detail_page.dart';
import 'package:visit_haralson/models/lodging.dart';

// MODELS
import 'models/place.dart';
import 'models/eat_and_drink.dart';
import 'models/clubs_model.dart';
import 'models/shop.dart';

// SHELLS
import 'app_shell.dart';
import 'features/admin/admin_shell.dart';

// PUBLIC PAGES
import 'features/user/home/home_page.dart';
import 'features/user/explore/explore_page.dart';
import 'features/user/explore/explore_detail_page.dart';
import 'features/user/events/events_page.dart';
import 'features/user/eat_and_drink/eat_and_drink_page.dart' as eat_list;
import 'features/user/eat_and_drink/eat_and_drink_details_page.dart'
    as eat_details;
import 'features/user/settings/settings_page.dart';
import 'features/support/contact_feedback_page.dart';
import 'features/user/stay/stay_page.dart';
import 'features/user/shop/shop_page.dart';
import 'features/user/shop/shop_detail_page.dart';
import 'features/claims/claim_business_page.dart';
import 'features/user/favorites/favorites_page.dart';

// clubs
import 'features/user/clubs/clubs_page.dart';
import 'features/user/clubs/clubs_detail_page.dart';

// ADMIN PAGES
import 'features/admin/dashboard/dashboard_page.dart';
import 'features/admin/explore/admin_explore_page.dart';
import 'features/admin/explore/add_attraction_page.dart';
import 'features/admin/explore/edit_attraction_page.dart';
import 'features/admin/clubs/edit_club_page.dart';
import 'features/admin/eat_and_drink/admin_add_eat_and_drink_page.dart';
import 'features/admin/eat_and_drink/admin_eat_and_drink_page.dart';
import 'features/admin/eat_and_drink/edit_eat_and_drink_page.dart';
import 'features/admin/lodging/admin_lodging_page.dart';
import 'features/admin/lodging/add_lodging_page.dart';
import 'features/admin/lodging/edit_lodging_page.dart';
import 'features/admin/shop/add_shops_page.dart';
import 'features/admin/shop/admin_edit_shop_page.dart';
import 'features/admin/users_and_roles_page.dart';
import 'features/admin/add_announcement_page.dart';
import 'features/admin/clubs/add_club_page.dart';
import 'features/admin/clubs/admin_clubs_page.dart';
import 'features/admin/categories/admin_sections_page.dart';
import 'features/admin/categories/admin_categories_page.dart';
import 'features/admin/feedback/admin_feedback_detail_page.dart';
import 'features/admin/feedback/admin_feedback_page.dart';
import 'features/admin/claims/admin_claims_page.dart';
import 'features/admin/config/global.dart';

// 🔐 Auth UI
import 'features/auth/login_page.dart';

// 🧭 Onboarding
import 'features/onboarding/onboarding_flow_page.dart';

/// Helper to make GoRouter rebuild when auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  // 👇 Re-run redirect when FirebaseAuth authStateChanges fires
  refreshListenable:
      GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loggingIn = state.matchedLocation == '/login';
    final isAdminRoute = state.matchedLocation.startsWith('/admin');
    final isOnboardingRoute = state.matchedLocation == '/onboarding';

    // -------- PUBLIC APP / NON-ADMIN --------
    if (!isAdminRoute) {
      // /login is always allowed for public side (for now)
      if (loggingIn) {
        if (user != null) {
          // Already logged in → bounce away from /login
          final from = state.uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            return from;
          }
          return '/admin';
        }
        return null; // allow access to login page
      }

      // Avoid redirect loops on /onboarding
      if (isOnboardingRoute) {
        return null;
      }

      // If there is no Firebase user at all, send them to onboarding.
      // OnboardingFlowPage will handle anonymous sign-in + profile creation.
      if (user == null) {
        return '/onboarding';
      }

      // Otherwise, allow normal public routes.
      return null;
    }

    // -------- ADMIN ROUTES (require login via /login) --------

    // Not logged in → must go to /login
    if (user == null) {
      final from = state.uri.toString(); // remember where they were headed
      return '/login?from=$from';
    }

    // Logged in and trying to access /login from /admin...
    if (loggingIn) {
      final from = state.uri.queryParameters['from'];
      if (from != null && from.isNotEmpty) {
        return from;
      }
      return '/admin';
    }

    // Logged in & admin route → allow
    return null;
  },

  routes: [
    // -------- LOGIN (public, but used by admin redirects) --------
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),

    // -------- ONBOARDING (public, but gated via redirect above) --------
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OnboardingFlowPage(),
      ),
    ),

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
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          builder: (context, state) => const FavoritesPage(),
        ),

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
                return ExploreDetailPage(place: place);
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
              child: eat_list.EatAndDrinkPage(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'detail',
              name: 'eatDetail',
              builder: (context, state) {
                final eat = state.extra as EatAndDrink;
                return eat_details.EatAndDrinkDetailsPage(
                  place: eat,
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
            GoRoute(
              path: 'detail',
              name: 'clubDetail',
              builder: (context, state) {
                final club = state.extra as Club;
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

        GoRoute(
          path: '/claim',
          name: 'claim',
          builder: (context, state) {
            final docPath = state.extra as String;
            return ClaimBusinessPage(docPath: docPath);
          },
        ),

        GoRoute(
          path: 'contact',
          name: 'contact',
          builder: (context, state) => const ContactFeedbackPage(),
        ),

        GoRoute(
          path: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AppShell(
              title: 'Settings',
              child: SettingsPage(),
            ),
          ),
        ),
      ],
    ),

    // -------- ADMIN (requires login via redirect above) --------
    ShellRoute(
      builder: (context, state, child) {
        final loc = state.matchedLocation;

        // Simple title resolver based on current admin path
        String title = 'Admin';
        if (loc == '/admin') {
          title = 'Dashboard';
        } else if (loc.startsWith('/admin/feedback')) {
          title = 'Feedback';
        } else if (loc.startsWith('/admin/claims')) {
          title = 'Claims';
        } else if (loc.startsWith('/admin/attractions')) {
          title = 'Attractions';
        } else if (loc.startsWith('/admin/events')) {
          title = 'Events';
        } else if (loc.startsWith('/admin/eat')) {
          title = 'Eat & Drink';
        } else if (loc.startsWith('/admin/lodging')) {
          title = 'Lodging';
        } else if (loc.startsWith('/admin/shops')) {
          title = 'Shops';
        } else if (loc.startsWith('/admin/clubs')) {
          title = 'Clubs & Groups';
        } else if (loc.startsWith('/admin/users')) {
          title = 'Users & Roles';
        } else if (loc.startsWith('/admin/locations')) {
          title = 'Locations';
        } else if (loc.startsWith('/admin/sections')) {
          title = 'Sections';
        } else if (loc.startsWith('/admin/categories')) {
          title = 'Categories';
        } else if (loc.startsWith('/admin/settings')) {
          title = 'Settings';
        } else if (loc.startsWith('/admin/announcements')) {
          title = 'Announcements';
        }

        return AdminShell(
          title: title,
          child: child,
        );
      },
      routes: [
        // /admin (dashboard)
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardPage(),
        ),

        // /admin/feedback
        GoRoute(
          path: '/admin/feedback',
          builder: (context, state) => const AdminFeedbackPage(),
        ),

        // /admin/feedback/:id
        GoRoute(
          path: '/admin/feedback/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AdminFeedbackDetailPage(id: id);
          },
        ),

        // /admin/claims
        GoRoute(
          path: '/admin/claims',
          name: 'adminClaims',
          builder: (context, state) => const AdminClaimsPage(),
        ),

        // /admin/attractions
        GoRoute(
          path: '/admin/attractions',
          builder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return AdminExplorePage(
              initialStateId: stateId,
              initialMetroId: metroId,
            );
          },
          routes: [
            GoRoute(
              path: 'add', // -> /admin/attractions/add
              builder: (context, state) => const AddAttractionPage(),
            ),
            GoRoute(
              path: 'edit', // -> /admin/attractions/edit
              name: 'adminEditAttraction',
              builder: (context, state) {
                final place = state.extra as Place;
                return EditAttractionPage(place: place);
              },
            ),
            GoRoute(
              path: 'categories', // -> /admin/attractions/categories
              builder: (context, state) => const AdminCategoriesPage(),
            ),
          ],
        ),

        // /admin/events
        GoRoute(
          path: '/admin/events',
          builder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return AdminEventsPage(
              initialStateId: stateId,
              initialMetroId: metroId,
            );
          },
        ),

        // /admin/eat
        GoRoute(
          path: '/admin/eat',
          builder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return AdminEatAndDrinkPage(
              initialStateId: stateId,
              initialMetroId: metroId,
            );
          },
          routes: [
            GoRoute(
              path: 'add', // -> /admin/eat/add
              builder: (context, state) => const AddEatAndDrinkPage(),
            ),
            GoRoute(
              path: 'edit', // -> /admin/eat/edit
              builder: (context, state) {
                final place = state.extra as EatAndDrink;
                return EditEatAndDrinkPage(place: place);
              },
            ),
          ],
        ),

        // /admin/shops
        GoRoute(
          path: '/admin/shops',
          builder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return AdminShopsPage(
              initialStateId: stateId,
              initialMetroId: metroId,
            );
          },
          routes: [
            GoRoute(
              path: 'add', // -> /admin/shops/add
              builder: (context, state) => const AddShopPage(),
            ),
            GoRoute(
              path: 'edit', // -> /admin/shops/edit
              builder: (context, state) {
                final shop = state.extra as Shop;
                return EditShopPage(shop: shop);
              },
            ),
          ],
        ),

        // /admin/lodging
        GoRoute(
          path: '/admin/lodging',
          builder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return AdminLodgingPage(
              initialStateId: stateId,
              initialMetroId: metroId,
            );
          },
          routes: [
            GoRoute(
              path: 'add', // -> /admin/lodging/add
              builder: (context, state) => const AddLodgingPage(),
            ),
            GoRoute(
              path: 'edit', // -> /admin/lodging/edit
              builder: (context, state) {
                final stay = state.extra as Stay;
                return EditLodgingPage(stay: stay);
              },
            ),
          ],
        ),

        // /admin/clubs
        GoRoute(
          path: '/admin/clubs',
          builder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return AdminClubsPage(
              initialStateId: stateId,
              initialMetroId: metroId,
            );
          },
          routes: [
            GoRoute(
              path: 'add', // -> /admin/clubs/add
              builder: (context, state) => const AddClubPage(),
            ),
            GoRoute(
              path: 'edit', // -> /admin/clubs/edit
              builder: (context, state) {
                final club = state.extra as Club;
                return EditClubPage(club: club);
              },
            ),
          ],
        ),

        // /admin/users
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UsersAndRolesPage(),
        ),

        // /admin/locations
        GoRoute(
          path: '/admin/locations',
          builder: (context, state) => const AdminLocationSetupPage(),
        ),

        // /admin/sections
        GoRoute(
          path: '/admin/sections',
          builder: (context, state) => const AdminSectionsPage(),
        ),

        // /admin/categories
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const AdminCategoriesPage(),
        ),

        // /admin/settings
        GoRoute(
          path: '/admin/settings',
          builder: (context, state) => const AdminSettingsPage(),
        ),

        // /admin/announcements
        GoRoute(
          path: '/admin/announcements',
          builder: (context, state) => const AddAnnouncementPage(),
        ),
      ],
    ),
  ],
);
