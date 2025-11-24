import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/require_full_account.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.type,
    required this.itemId,
  });

  /// e.g. 'attraction', 'eat', 'event', 'shop', 'stay'
  final String type;

  /// Firestore doc id for the item (place.id, event.id, etc.)
  final String itemId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    // If we don't have a user yet, just show "not favorite" icon.
    // When tapped, requireFullAccount will handle auth and toggle.
    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.favorite_border),
        onPressed: () async {
          await _handleToggle(context);
        },
      );
    }

    final docRef = FirebaseFirestore.instance
        .collection('userFavorites')
        .doc(uid)
        .collection('items')
        .doc(_favoriteDocId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        final exists = snapshot.data?.exists == true;
        final isFavorite = exists;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          onPressed: () async {
            await _handleToggle(context);
          },
        );
      },
    );
  }

  /// Combines type + itemId into one doc id, so a user can favorite
  /// the same item across sections without collisions.
  String get _favoriteDocId => '${type}_$itemId';

  Future<void> _handleToggle(BuildContext context) async {
    await requireFullAccount(
      context,
      action: (User user) async {
        final uid = user.uid;

        final docRef = FirebaseFirestore.instance
            .collection('userFavorites')
            .doc(uid)
            .collection('items')
            .doc(_favoriteDocId);

        final snap = await docRef.get();

        if (snap.exists) {
          // Already favorite → remove
          await docRef.delete();
        } else {
          // Not favorite → add
          await docRef.set({
            'type': type,
            'itemId': itemId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      },
    );
  }
}
