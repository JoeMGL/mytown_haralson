import 'package:cloud_firestore/cloud_firestore.dart';

class StateModel {
  final String id; // Firestore doc ID
  final String name; // Full display name: "Georgia"
  final String slug; // "georgia" or "ga"
  final String? abbreviation; // "GA" (optional but useful)
  final String? heroImageUrl;
  final bool isActive;
  final int sortOrder;
  final String? timezone; // e.g. "America/New_York"

  StateModel({
    required this.id,
    required this.name,
    required this.slug,
    this.abbreviation,
    this.heroImageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.timezone,
  });

  /// Firestore → StateModel
  factory StateModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return StateModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      slug: (data['slug'] ?? doc.id) as String,
      abbreviation: data['abbreviation'] as String?,
      heroImageUrl: data['heroImageUrl'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      sortOrder: (data['sortOrder'] ?? 0) as int,
      timezone: data['timezone'] as String?,
    );
  }

  /// StateModel → Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'abbreviation': abbreviation,
      'heroImageUrl': heroImageUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
