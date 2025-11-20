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

    // Public routes (non-admin) are always allowed
    if (!isAdminRoute) {
      // If user is logged in and on /login, bounce them to either
      // the "from" param or admin dashboard or home
      if (loggingIn && user != null) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return from;
        }
        return '/admin';
      }
      return null;
    }

    // From here down, we're in /admin...

    // Not logged in → must go to /login
    if (user == null) {
      final from = state.uri.toString(); // remember where they were headed
      return '/login?from=$from';
    }

    // Logged in and trying to access /login (with from=/admin/...) – already handled above,
    // but keep this as a safety net.
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
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AdminShell(
          title: 'Dashboard',
          child: AdminDashboardPage(),
        ),
      ),
      routes: [
        // /admin/feedback
        GoRoute(
          path: 'feedback',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Feedback',
              child: AdminFeedbackPage(),
            ),
          ),
        ),

        // /admin/feedback/:id
        GoRoute(
          path: 'feedback/:id',
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return NoTransitionPage(
              child: AdminShell(
                title: 'Feedback Detail',
                child: AdminFeedbackDetailPage(id: id),
              ),
            );
          },
        ),

        GoRoute(
          path: '/admin/claims',
          name: 'adminClaims',
          builder: (context, state) => const AdminClaimsPage(),
        ),

        // /admin/attractions
        GoRoute(
          path: 'attractions',
          pageBuilder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return NoTransitionPage(
              child: AdminShell(
                title: 'Attractions',
                child: AdminExplorePage(
                  initialStateId: stateId,
                  initialMetroId: metroId,
                ),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminShell(
                  title: 'Add Attraction',
                  child: AddAttractionPage(),
                ),
              ),
            ),
            GoRoute(
              path: 'edit',
              name: 'adminEditAttraction',
              pageBuilder: (context, state) {
                final place = state.extra as Place;

                return NoTransitionPage(
                  child: AdminShell(
                    title: 'Edit Attraction',
                    child: EditAttractionPage(place: place),
                  ),
                );
              },
            ),
            GoRoute(
              path: 'categories',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminShell(
                  title: 'Attraction Categories',
                  child: AdminCategoriesPage(),
                ),
              ),
            ),
          ],
        ),

        // /admin/events
        GoRoute(
          path: 'events',
          pageBuilder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return NoTransitionPage(
              child: AdminShell(
                title: 'Events',
                child: AdminEventsPage(
                  initialStateId: stateId,
                  initialMetroId: metroId,
                ),
              ),
            );
          },
        ),

        // /admin/eat
        GoRoute(
          path: 'eat',
          pageBuilder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return NoTransitionPage(
              child: AdminShell(
                title: 'Eat',
                child: AdminEatAndDrinkPage(
                  initialStateId: stateId,
                  initialMetroId: metroId,
                ),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminShell(
                  title: 'Add Eat & Drink',
                  child: AddEatAndDrinkPage(),
                ),
              ),
            ),
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) {
                final place = state.extra as EatAndDrink;
                return NoTransitionPage(
                  child: AdminShell(
                    title: 'Edit Eat & Drink',
                    child: EditEatAndDrinkPage(place: place),
                  ),
                );
              },
            ),
          ],
        ),

        // /admin/shops
        GoRoute(
          path: 'shops',
          pageBuilder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return NoTransitionPage(
              child: AdminShell(
                title: 'Shops',
                child: AdminShopsPage(
                  initialStateId: stateId,
                  initialMetroId: metroId,
                ),
              ),
            );
          },
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

        // /admin/lodging
        GoRoute(
          path: 'lodging',
          pageBuilder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return NoTransitionPage(
              child: AdminShell(
                title: 'Lodging',
                child: AdminLodgingPage(
                  initialStateId: stateId,
                  initialMetroId: metroId,
                ),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AdminShell(
                  title: 'Add Lodging',
                  child: AddLodgingPage(),
                ),
              ),
            ),
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) {
                final stay = state.extra as Stay;
                return NoTransitionPage(
                  child: AdminShell(
                    title: 'Edit Lodging',
                    child: EditLodgingPage(stay: stay),
                  ),
                );
              },
            ),
          ],
        ),

        // /admin/clubs
        GoRoute(
          path: 'clubs',
          pageBuilder: (context, state) {
            final stateId = state.uri.queryParameters['stateId'];
            final metroId = state.uri.queryParameters['metroId'];

            return NoTransitionPage(
              child: AdminShell(
                title: 'Clubs & Groups',
                child: AdminClubsPage(
                  initialStateId: stateId,
                  initialMetroId: metroId,
                ),
              ),
            );
          },
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
          path: 'sections',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Sections',
              child: AdminSectionsPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'categories',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminShell(
              title: 'Categories',
              child: AdminCategoriesPage(),
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
