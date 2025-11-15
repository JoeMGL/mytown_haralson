import 'package:cloud_firestore/cloud_firestore.dart';

class Area {
  final String id; // Firestore doc id
  final String stateId; // parent state
  final String metroId; // parent metro

  final String name;
  final String slug;
  final String type; // city | town | suburb | neighborhood

  final String? tagline;
  final String? heroImageUrl;
  final bool isActive;
  final int sortOrder;

  Area({
    required this.id,
    required this.stateId,
    required this.metroId,
    required this.name,
    required this.slug,
    required this.type,
    this.tagline,
    this.heroImageUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Firestore → Area
  factory Area.fromDoc({
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String stateId,
    required String metroId,
  }) {
    final data = doc.data() ?? {};

    return Area(
      id: doc.id,
      stateId: stateId,
      metroId: metroId,
      name: (data['name'] ?? '') as String,
      slug: (data['slug'] ?? doc.id) as String,
      type: (data['type'] ?? 'city') as String,
      tagline: data['tagline'] as String?,
      heroImageUrl: data['heroImageUrl'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      sortOrder: (data['sortOrder'] ?? 0) as int,
    );
  }

  /// Area → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'type': type,
      'tagline': tagline,
      'heroImageUrl': heroImageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'stateId': stateId,
      'metroId': metroId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
