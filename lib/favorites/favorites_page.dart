import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Favorites core
import '../../core/favorites/favorites_repository.dart';
import '../../models/favorite.dart';
import '../../widgets/favorite_button.dart';

// Your domain models
import '../../models/place.dart';
import '../../models/event.dart';
import '../../models/eat_and_drink.dart';
import '../../models/clubs_model.dart';

/// View-model that joins a Favorite with its underlying item.
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
final resolvedFavoritesProvider =
    FutureProvider<List<ResolvedFavorite>>((ref) async {
  final favoritesMap = await ref.watch(userFavoritesProvider.future);
  final favorites = favoritesMap.values.toList();
  final db = FirebaseFirestore.instance;

  final List<ResolvedFavorite> results = [];

  // Group favorites by type for cleaner logic
  final events = <Favorite>[];
  final eats = <Favorite>[];
  final attractions = <Favorite>[];
  final clubs = <Favorite>[];
  final other = <Favorite>[];

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
      default:
        other.add(fav);
    }
  }

  // Helper to resolve a list of favorites of the same type one-by-one.
  // (Simple & clear; you can optimize later with whereIn if needed.)
  Future<void> _resolveEvents(List<Favorite> list) async {
    for (final fav in list) {
      final doc = await db
          .collection('events')
          .doc(fav.itemId)
          .get(); // 🔧 adjust if needed
      if (!doc.exists) continue;
      final event = Event.fromDoc(doc);
      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: event.title,
          subtitle: [
            if (event.venue.isNotEmpty) event.venue,
            if (event.city.isNotEmpty) event.city,
          ].join(' • '),
          imageUrl: event.imageUrl,
        ),
      );
    }
  }

  Future<void> _resolveEats(List<Favorite> list) async {
    for (final fav in list) {
      final doc = await db
          .collection('eatAndDrink')
          .doc(fav.itemId)
          .get(); // 🔧 adjust if needed
      if (!doc.exists) continue;
      final eat = EatAndDrink.fromDoc(doc);
      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: eat.name,
          subtitle: [
            if (eat.city.isNotEmpty) eat.city,
            if (eat.category.isNotEmpty) eat.category,
          ].join(' • '),
          imageUrl: eat.imageUrl,
        ),
      );
    }
  }

  Future<void> _resolveAttractions(List<Favorite> list) async {
    for (final fav in list) {
      final doc = await db
          .collection('places')
          .doc(fav.itemId)
          .get(); // 🔧 adjust if needed
      if (!doc.exists) continue;
      final place = Place.fromFirestore(doc);
      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: place.title,
          subtitle: [
            if (place.city.isNotEmpty) place.city,
            if (place.areaName.isNotEmpty) place.areaName,
          ].join(' • '),
          imageUrl: place.imageUrl,
        ),
      );
    }
  }

  Future<void> _resolveClubs(List<Favorite> list) async {
    for (final fav in list) {
      final doc = await db
          .collection('clubs')
          .doc(fav.itemId)
          .get(); // 🔧 adjust if needed
      if (!doc.exists) continue;
      final club = Club.fromDoc(doc);
      results.add(
        ResolvedFavorite(
          favorite: fav,
          title: club.name,
          subtitle: [
            if (club.areaName.isNotEmpty) club.areaName,
            if (club.meetingLocation.isNotEmpty) club.meetingLocation,
          ].join(' • '),
          imageUrl: club.bannerImageUrl?.isNotEmpty == true
              ? club.bannerImageUrl
              : (club.imageUrls.isNotEmpty ? club.imageUrls.first : null),
        ),
      );
    }
  }

  Future<void> _resolveOther(List<Favorite> list) async {
    for (final fav in list) {
      // Generic fallback: we only know type + ID
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

  return results;
});
