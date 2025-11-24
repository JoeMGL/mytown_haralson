import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/favorites/favorites_repository.dart';

import '../../../widgets/favorite_button.dart';

import '../../../models/favorite.dart';

import '../../../models/place.dart';
import '../../../models/eat_and_drink.dart';
import '../../../models/clubs_model.dart';
import '../../../models/lodging.dart';
import '../../../models/shop.dart';

/// View-model that joins a Favorite with its underlying item data.
class ResolvedFavorite {
  final Favorite favorite;

  /// Human-readable title (e.g. place name, event title, club name)
  final String title;

  /// Smaller secondary line (e.g. city, venue, area)
  final String? subtitle;

  /// Optional thumbnail URL (e.g. hero or primary image)
  final String? imageUrl;

  ResolvedFavorite({
    required this.favorite,
    required this.title,
    this.subtitle,
    this.imageUrl,
  });

  String get type => favorite.type;
  String get itemId => favorite.itemId;
}

/// Provider that resolves a user's favorites into real items for display.
/// NOTE: This does NOT depend on Event/Place/Club models – it reads raw maps.
final resolvedFavoritesProvider =
    FutureProvider<List<ResolvedFavorite>>((ref) async {
  final favoritesMap = await ref.watch(userFavoritesProvider.future);

  // 🔍 DEBUG: see what the favorites stream is giving us
  debugPrint(
      'resolvedFavoritesProvider: favoritesMap length = ${favoritesMap.length}');
  for (final fav in favoritesMap.values) {
    debugPrint(
        'favorite: id=${fav.id} type=${fav.type} itemId=${fav.itemId} addedAt=${fav.addedAt}');
  }

  final favorites = favoritesMap.values.toList();
  final db = FirebaseFirestore.instance;

  final List<ResolvedFavorite> results = [];

  // Group favorites by type for cleaner logic
  final events = <Favorite>[];
  final eats = <Favorite>[];
  final attractions = <Favorite>[];
  final clubs = <Favorite>[];
  final other = <Favorite>[]; // includes lodging + shop for now

  for (final fav in favorites) {
    switch (fav.type) {
      case 'event':
        events.add(fav);
        break;
      case 'eat_and_drink':
        eats.add(fav);
        break;
      case 'attraction':
        attractions.add(fav);
        break;
      case 'club':
        clubs.add(fav);
        break;
      case 'lodging':
      case 'shop':
        other.add(fav); // generic handling for now
        break;
      default:
        other.add(fav);
    }
  }

  Future<void> _resolveEvents(List<Favorite> list) async {
    for (final fav in list) {
      debugPrint('Resolving EVENT favorite: itemId=${fav.itemId}');
      final doc = await db.collection('events').doc(fav.itemId).get();
      if (!doc.exists) {
        debugPrint(
            '  -> No event doc for id=${fav.itemId}, using generic fallback');
        results.add(
          ResolvedFavorite(
            favorite: fav,
            title: 'Event • ${fav.itemId}',
          ),
        );
        continue;
      }

      final data = doc.data() ?? <String, dynamic>{};

      final title =
          (data['title'] as String?) ?? (data['name'] as String?) ?? 'Event';

      final venue = (data['venue'] as String?) ?? '';
      final city = (data['city'] as String?) ?? '';

      final subtitleParts = <String>[];
      if (venue.isNotEmpty) subtitleParts.add(venue);
      if (city.isNotEmpty) subtitleParts.add(city);

      final imageUrl = (data['imageUrl'] as String?) ?? '';

      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: title,
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        ),
      );
    }
  }

  Future<void> _resolveEats(List<Favorite> list) async {
    for (final fav in list) {
      debugPrint('Resolving EAT favorite: itemId=${fav.itemId}');
      final doc = await db.collection('eatAndDrink').doc(fav.itemId).get();
      if (!doc.exists) {
        debugPrint(
            '  -> No eatAndDrink doc for id=${fav.itemId}, using generic fallback');
        results.add(
          ResolvedFavorite(
            favorite: fav,
            title: 'Restaurant • ${fav.itemId}',
          ),
        );
        continue;
      }

      final data = doc.data() ?? <String, dynamic>{};

      final title = (data['name'] as String?) ??
          (data['title'] as String?) ??
          'Restaurant';

      final city = (data['city'] as String?) ?? '';
      final category = (data['category'] as String?) ?? '';

      final subtitleParts = <String>[];
      if (city.isNotEmpty) subtitleParts.add(city);
      if (category.isNotEmpty) subtitleParts.add(category);

      final imageUrl = (data['imageUrl'] as String?) ?? '';

      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: title,
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        ),
      );
    }
  }

  Future<void> _resolveAttractions(List<Favorite> list) async {
    for (final fav in list) {
      debugPrint('Resolving ATTRACTION favorite: itemId=${fav.itemId}');
      final doc = await db.collection('places').doc(fav.itemId).get();
      if (!doc.exists) {
        debugPrint(
            '  -> No place doc for id=${fav.itemId}, using generic fallback');
        results.add(
          ResolvedFavorite(
            favorite: fav,
            title: 'Attraction • ${fav.itemId}',
          ),
        );
        continue;
      }

      final data = doc.data() ?? <String, dynamic>{};

      final title = (data['title'] as String?) ??
          (data['name'] as String?) ??
          'Attraction';

      final city = (data['city'] as String?) ?? '';
      final areaName = (data['areaName'] as String?) ?? '';

      final subtitleParts = <String>[];
      if (city.isNotEmpty) subtitleParts.add(city);
      if (areaName.isNotEmpty) subtitleParts.add(areaName);

      final imageUrl = (data['imageUrl'] as String?) ?? '';

      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: title,
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        ),
      );
    }
  }

  Future<void> _resolveClubs(List<Favorite> list) async {
    for (final fav in list) {
      debugPrint('Resolving CLUB favorite: itemId=${fav.itemId}');
      final doc = await db.collection('clubs').doc(fav.itemId).get();
      if (!doc.exists) {
        debugPrint(
            '  -> No club doc for id=${fav.itemId}, using generic fallback');
        results.add(
          ResolvedFavorite(
            favorite: fav,
            title: 'Club • ${fav.itemId}',
          ),
        );
        continue;
      }

      final data = doc.data() ?? <String, dynamic>{};

      final title =
          (data['name'] as String?) ?? (data['title'] as String?) ?? 'Club';

      final areaName = (data['areaName'] as String?) ?? '';
      final meetingLocation = (data['meetingLocation'] as String?) ?? '';

      final subtitleParts = <String>[];
      if (areaName.isNotEmpty) subtitleParts.add(areaName);
      if (meetingLocation.isNotEmpty) subtitleParts.add(meetingLocation);

      final bannerImageUrl = (data['bannerImageUrl'] as String?) ?? '';
      final imageUrls =
          (data['imageUrls'] as List?)?.cast<String>() ?? const <String>[];

      final imageUrl = bannerImageUrl.isNotEmpty
          ? bannerImageUrl
          : (imageUrls.isNotEmpty ? imageUrls.first : '');

      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: title,
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
        ),
      );
    }
  }

  Future<void> _resolveOther(List<Favorite> list) async {
    for (final fav in list) {
      debugPrint(
          'Resolving OTHER favorite: type=${fav.type} itemId=${fav.itemId}');
      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: '${fav.type} • ${fav.itemId}',
        ),
      );
    }
  }

  await Future.wait([
    _resolveEvents(events),
    _resolveEats(eats),
    _resolveAttractions(attractions),
    _resolveClubs(clubs),
    _resolveOther(other),
  ]);

  // Sort by addedAt (newest first)
  results.sort((a, b) {
    final ad = a.favorite.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.favorite.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });

  debugPrint(
      'resolvedFavoritesProvider: resolved results length = ${results.length}');
  return results;
});

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedAsync = ref.watch(resolvedFavoritesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
      ),
      body: resolvedAsync.when(
        data: (resolved) {
          if (resolved.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group by type so we can show section headers
          final Map<String, List<ResolvedFavorite>> grouped = {};
          for (final rf in resolved) {
            grouped.putIfAbsent(rf.type, () => []).add(rf);
          }

          final typeKeys = grouped.keys.toList()..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Small visible debug/summary at the top
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Total saved: ${resolved.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: typeKeys.length,
                  itemBuilder: (context, index) {
                    final type = typeKeys[index];
                    final list = grouped[type]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index > 0) const SizedBox(height: 8),
                        Text(
                          _labelForType(type),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 0),
                            itemBuilder: (context, i) {
                              final rf = list[i];
                              final fav = rf.favorite;

                              return ListTile(
                                leading: _buildLeadingAvatar(type, rf, cs),
                                title: Text(
                                  rf.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((rf.subtitle ?? '').isNotEmpty)
                                      Text(
                                        rf.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (fav.addedAt != null)
                                      Text(
                                        'Saved on ${_formatDate(fav.addedAt!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                                trailing: FavoriteButton(
                                  type: fav.type,
                                  itemId: fav.itemId,
                                ),
                                onTap: () {
                                  _handleTap(context, rf);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading favorites: $err'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on places, events, clubs, and restaurants to save them here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingAvatar(
    String type,
    ResolvedFavorite rf,
    ColorScheme cs,
  ) {
    final icon = _iconForType(type);

    if (rf.imageUrl == null || rf.imageUrl!.isEmpty) {
      return CircleAvatar(
        backgroundColor: cs.surfaceVariant,
        child: Icon(icon, color: cs.onSurfaceVariant),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        rf.imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return CircleAvatar(
            backgroundColor: cs.surfaceVariant,
            child: Icon(icon, color: cs.onSurfaceVariant),
          );
        },
      ),
    );
  }

  String _labelForType(String type) {
    switch (type) {
      case 'event':
        return 'Events';
      case 'eat_and_drink':
        return 'Eat & Drink';
      case 'attraction':
        return 'Attractions';
      case 'club':
        return 'Clubs & Groups';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'eat_and_drink':
        return Icons.restaurant;
      case 'attraction':
        return Icons.landscape;
      case 'club':
        return Icons.groups;
      default:
        return Icons.star;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _handleTap(BuildContext context, ResolvedFavorite rf) async {
    final type = rf.type;
    final id = rf.itemId;
    final db = FirebaseFirestore.instance;

    try {
      if (type == 'attraction') {
        // 🔹 Load Place from Firestore and go to ExploreDetailPage
        final doc = await db.collection('places').doc(id).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('This attraction is no longer available.')),
          );
          return;
        }

        final place = Place.fromFirestore(doc);
        context.pushNamed(
          'exploreDetail', // from router: path 'explore/detail'
          extra: place,
        );
      } else if (type == 'eat_and_drink') {
        // 🔹 Load EatAndDrink and go to EatAndDrinkDetailsPage
        final doc = await db.collection('eatAndDrink').doc(id).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This place is no longer available.')),
          );
          return;
        }

        final eat = EatAndDrink.fromDoc(doc);
        context.pushNamed(
          'eatDetail', // from router: /eat/detail
          extra: eat,
        );
      } else if (type == 'club') {
        // 🔹 Load Club and go to ClubDetailPage
        final doc = await db.collection('clubs').doc(id).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This club is no longer available.')),
          );
          return;
        }

        // Assuming you have a similar factory: Club.fromDoc(...)
        final club = Club.fromDoc(doc);
        context.pushNamed(
          'clubDetail', // from router: /clubs/detail
          extra: club,
        );
      } else if (type == 'lodging') {
        final doc = await db.collection('lodging').doc(id).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This stay is no longer available.')),
          );
          return;
        }

        final stay = Stay.fromDoc(doc);
        context.pushNamed(
          'stayDetail',
          extra: stay,
        );
      } else if (type == 'shop') {
        context.pushNamed('shop');
      } else if (type == 'event') {
        context.push('/events');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No detail page wired for type "$type".')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this item right now.')),
      );
    }
  }
}
