import 'package:cloud_firestore/cloud_firestore.dart';

class Metro {
  final String id; // Firestore doc id
  final String stateId; // parent state
  final String name;
  final String slug;
  final String? tagline;
  final String? heroImageUrl;
  final bool isActive;
  final int sortOrder;

  Metro({
    required this.id,
    required this.stateId,
    required this.name,
    required this.slug,
    this.tagline,
    this.heroImageUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Firestore → Metro
  factory Metro.fromDoc({
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String stateId,
  }) {
    final data = doc.data() ?? {};

    return Metro(
      id: doc.id,
      stateId: stateId,
      name: (data['name'] ?? '') as String,
      slug: (data['slug'] ?? doc.id) as String,
      tagline: data['tagline'] as String?,
      heroImageUrl: data['heroImageUrl'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      sortOrder: (data['sortOrder'] ?? 0) as int,
    );
  }

  /// Metro → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'tagline': tagline,
      'heroImageUrl': heroImageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'stateId': stateId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
