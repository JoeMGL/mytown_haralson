import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/location/location_provider.dart'; // adjust path if needed
import '../../../widgets/featured_places_section.dart'; // 👈 keeps your featured section

import '../../../widgets/featured_clubs_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading location: $e')),
      ),
      data: (loc) {
        final stateId = loc.stateId;
        final metroId = loc.metroId;

        // If no location configured yet → generic Haralson home
        if (stateId == null || metroId == null) {
          return _buildScaffold(
            context,
            title: 'VISIT HARALSON',
            nearMeLabel: 'Haralson County',
            heroImageUrl:
                'https://images.unsplash.com/photo-1482192596544-9eb780fc7f66?q=80&w=1600',
            // no state/metro here, so no featured strip yet
          );
        }

        // Load the active metro doc:
        final metroRef = FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('metros')
            .doc(metroId);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: metroRef.snapshots(),
          builder: (context, snapshot) {
            // While metro doc loads, just use generic but still show app
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildScaffold(
                context,
                title: 'VISIT HARALSON',
                nearMeLabel: 'Haralson County',
                heroImageUrl:
                    'https://images.unsplash.com/photo-1482192596544-9eb780fc7f66?q=80&w=1600',
                stateId: stateId,
                metroId: metroId,
              );
            }

            final data = snapshot.data?.data() ?? {};

            final metroName =
                (data['name'] as String?)?.trim().isNotEmpty == true
                    ? data['name'] as String
                    : _prettyFromId(metroId);

            final heroImageUrl = (data['heroImageUrl'] as String?)
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? data['heroImageUrl'] as String
                : 'https://images.unsplash.com/photo-1482192596544-9eb780fc7f66?q=80&w=1600';

            final tagline = (data['tagline'] as String?)?.trim();

            // 🔹 Now load banners for this metro
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: metroRef
                  .collection('banners')
                  .orderBy('sortOrder')
                  .snapshots(),
              builder: (context, bannerSnap) {
                List<Map<String, dynamic>> banners = [];
                if (bannerSnap.hasData && bannerSnap.data!.docs.isNotEmpty) {
                  banners = bannerSnap.data!.docs
                      .map((d) => d.data())
                      .where(
                        (b) => (b['isActive'] ?? true) == true,
                      )
                      .toList();
                }

                return _buildScaffold(
                  context,
                  title: 'VISIT $metroName'.toUpperCase(),
                  nearMeLabel: metroName,
                  heroImageUrl: heroImageUrl,
                  tagline: tagline,
                  stateId: stateId,
                  metroId: metroId,
                  banners: banners,
                );
              },
            );
          },
        );
      },
    );
  }

  /// Main scaffold UI.
  Widget _buildScaffold(
    BuildContext context, {
    required String title,
    required String nearMeLabel,
    required String heroImageUrl,
    String? tagline,
    String? stateId,
    String? metroId,
    List<Map<String, dynamic>> banners = const [],
  }) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 16, bottom: 12),
              title: Text(title),
              background: _HomeHero(
                heroImageUrl: heroImageUrl,
                banners: banners,
                title: title,
                tagline: tagline,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _quick(context, Icons.explore, 'Explore',
                          () => context.go('/explore')),
                      _quick(context, Icons.restaurant, 'Eat & Drink',
                          () => context.go('/eat')),
                      _quick(context, Icons.hotel, 'Stay',
                          () => context.go('/stay')),
                      _quick(context, Icons.event, 'Events',
                          () => context.go('/events')),
                      _quick(context, Icons.group, 'Clubs',
                          () => context.goNamed('clubs')),
                      _quick(context, Icons.store, 'Shop',
                          () => context.goNamed('shop')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search restaurants, trails or festivals…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Now truly "Near Me in {metro name from Firestore}"
                  Text(
                    'Near Me in $nearMeLabel',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _nearMeCard(),
                  const SizedBox(height: 16),

                  _genericBanner(nearMeLabel),
                  const SizedBox(height: 24),

                  // ⭐ Featured Attractions (only if we know location)
                  if (stateId != null && metroId != null) ...[
                    FeaturedAttractionsSection(
                      title: 'Featured Attractions',
                      stateId: stateId,
                      metroId: metroId,
                      onPlaceTap: (place) {
                        context.pushNamed(
                          'exploreDetail',
                          extra: place,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // 🧩 Featured Clubs & Groups
                    FeaturedClubsSection(
                      title: 'Clubs & Groups',
                      stateId: stateId,
                      metroId: metroId,
                      onClubTap: (club) {
                        context.pushNamed(
                          'clubDetail', // whatever you named the route
                          extra: club,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(
          BuildContext ctx, IconData icon, String label, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _nearMeCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=400',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          title: const Text('Crocked Creek Park'),
          subtitle: const Text('⭐ 4.7 • 3 mi'),
          trailing: const Icon(Icons.chevron_right),
        ),
      );

  Widget _genericBanner(String nearMeLabel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: .4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        'Did You Know?\nDiscover hidden gems and local favorites around $nearMeLabel.',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  String _prettyFromId(String raw) {
    final lastSegment = raw.split('/').last;
    return lastSegment
        .split(RegExp(r'[_\\- ]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

/// Hero background for the SliverAppBar
/// - Uses metro banners if available
/// - Falls back to the static hero image
class _HomeHero extends StatefulWidget {
  const _HomeHero({
    required this.heroImageUrl,
    required this.banners,
    required this.title,
    this.tagline,
  });

  final String heroImageUrl;
  final List<Map<String, dynamic>> banners;
  final String title;
  final String? tagline;

  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  final PageController _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasBanners = widget.banners.isNotEmpty;

    Widget buildImage(Map<String, dynamic>? banner) {
      final imageUrl = banner != null
          ? (banner['imageUrl'] as String? ?? widget.heroImageUrl)
          : widget.heroImageUrl;

      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: cs.surfaceVariant,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          // Optional tagline overlay at bottom-left
          if (widget.tagline != null && widget.tagline!.trim().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                widget.tagline!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      );
    }

    if (!hasBanners) {
      // Just single hero image
      return buildImage(null);
    }

    final banners = widget.banners;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: banners.length,
          onPageChanged: (index) {
            setState(() => _current = index);
          },
          itemBuilder: (context, index) {
            final b = banners[index];
            return buildImage(b);
          },
        ),
        // Dots indicator
        Positioned(
          bottom: 8,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(banners.length, (i) {
              final isActive = _current == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 10 : 6,
                height: isActive ? 10 : 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
