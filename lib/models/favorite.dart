import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id; // docId in favorites subcollection
  final String itemId; // ID of the underlying item
  final String type; // e.g. 'attraction', 'eat_and_drink', 'event', 'club'
  final DateTime? addedAt;

  Favorite({
    required this.id,
    required this.itemId,
    required this.type,
    this.addedAt,
  });

  factory Favorite.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['addedAt'] as Timestamp?;
    return Favorite(
      id: doc.id,
      itemId: data['itemId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      addedAt: ts?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'type': type,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Helper for a unique doc id, if you're using it
String favoriteKey(String type, String itemId) => '${type}_$itemId';
