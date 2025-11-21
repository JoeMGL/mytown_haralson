import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/favorite.dart';

class FavoritesRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FavoritesRepository(this._db, this._auth);

  /// Stream of all favorites for the current user, keyed by docId.
  Stream<Map<String, Favorite>> watchFavorites() {
    final user = _auth.currentUser;
    if (user == null) {
      // No user -> empty map
      return const Stream<Map<String, Favorite>>.empty();
    }

    final ref = _db.collection('users').doc(user.uid).collection('favorites');

    return ref.snapshots().map((snapshot) {
      final map = <String, Favorite>{};
      for (final doc in snapshot.docs) {
        final fav = Favorite.fromSnapshot(doc);
        map[fav.id] = fav;
      }
      return map;
    });
  }

  Future<void> toggleFavorite(String type, String itemId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in to favorite items.');
    }

    final key = favoriteKey(type, itemId);
    final docRef =
        _db.collection('users').doc(user.uid).collection('favorites').doc(key);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      final fav = Favorite(
        id: key,
        itemId: itemId,
        type: type,
      );
      await docRef.set(fav.toMap());
    }
  }
}

// Riverpod providers
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final userFavoritesProvider = StreamProvider<Map<String, Favorite>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.watchFavorites();
});
