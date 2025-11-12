import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/place.dart';
import 'features/home/home_page.dart';
import 'features/explore/explore_page.dart';
import 'features/events/events_page.dart';
import 'features/shell/bottom_nav_shell.dart';
import 'features/explore/explore_detail_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final uri = state.uri.toString();
        int index = 0;
        if (uri.startsWith('/explore')) index = 1;
        if (uri.startsWith('/events')) index = 2;
        return BottomNavShell(index: index, child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/explore',
          name: 'explore',
          builder: (context, state) => const ExplorePage(),
          routes: [
            // ✅ nested paths are RELATIVE: 'detail' not '/explore/detail'
            GoRoute(
              path: 'detail',
              name: 'explore-detail',
              builder: (context, state) {
                final place = state.extra as Place; // must pass in navigation
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
          path: '/events',
          name: 'events',
          builder: (context, state) => const EventsPage(),
        ),
      ],
    ),
  ],
);
