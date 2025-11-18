// lib/models/clubs_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;

  // Core
  final String name;
  final String category;

  // Images
  final List<String> imageUrls;
  final String imageUrl; // primary image (first gallery image)
  final String bannerImageUrl; // hero / cover

  // Meeting info
  final String meetingLocation;
  final String meetingSchedule;

  // Contact
  final String contactName;
  final String contactEmail;
  final String contactPhone;

  // Links
  final String website;
  final String facebook;

  // Flags
  final bool featured;
  final bool active;

  // Location (logical)
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  // Postal address parts + combined
  final String street;
  final String city;
  final String state;
  final String zip;
  final String address;

  Club({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrls,
    required this.imageUrl,
    required this.bannerImageUrl,
    required this.meetingLocation,
    required this.meetingSchedule,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.website,
    required this.facebook,
    required this.featured,
    required this.active,
    required this.stateId,
    required this.stateName,
    required this.metroId,
    required this.metroName,
    required this.areaId,
    required this.areaName,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.address,
  });

  // Helper to safely convert dynamic -> List<String>
  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Used when you already have a typed DocumentSnapshot
  factory Club.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Club(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      category: (data['category'] as String?)?.trim() ?? '',

      // Images
      imageUrls: _stringList(data['imageUrls']),
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      bannerImageUrl: (data['bannerImageUrl'] as String?)?.trim() ?? '',

      // Meeting info
      meetingLocation: (data['meetingLocation'] as String?)?.trim() ?? '',
      meetingSchedule: (data['meetingSchedule'] as String?)?.trim() ?? '',

      // Contact
      contactName: (data['contactName'] as String?)?.trim() ?? '',
      contactEmail: (data['contactEmail'] as String?)?.trim() ?? '',
      contactPhone: (data['contactPhone'] as String?)?.trim() ?? '',

      // Links
      website: (data['website'] as String?)?.trim() ?? '',
      facebook: (data['facebook'] as String?)?.trim() ?? '',

      // Flags
      featured: data['featured'] as bool? ?? false,
      active: data['active'] as bool? ?? true,

      // Location (logical)
      stateId: (data['stateId'] as String?) ?? '',
      stateName: (data['stateName'] as String?) ?? '',
      metroId: (data['metroId'] as String?) ?? '',
      metroName: (data['metroName'] as String?) ?? '',
      areaId: (data['areaId'] as String?) ?? '',
      areaName: (data['areaName'] as String?) ?? '',

      // Postal address
      street: (data['street'] as String?)?.trim() ?? '',
      city: (data['city'] as String?)?.trim() ?? '',
      state: (data['state'] as String?)?.trim() ?? '',
      zip: (data['zip'] as String?)?.trim() ?? '',
      address: (data['address'] as String?)?.trim() ?? '',
    );
  }

  /// Flexible factory so existing code like `Club.fromFirestore(...)` still works.
  ///
  /// Supports:
  ///   Club.fromFirestore(doc)                // DocumentSnapshot
  ///   Club.fromFirestore(map, 'docId')       // Map + explicit id
  factory Club.fromFirestore(dynamic source, [String? explicitId]) {
    if (source is DocumentSnapshot<Map<String, dynamic>>) {
      return Club.fromDoc(source);
    }

    if (source is DocumentSnapshot) {
      final doc = source as DocumentSnapshot<Map<String, dynamic>>;
      return Club.fromDoc(doc);
    }

    if (source is Map<String, dynamic>) {
      final data = source;
      final id = explicitId ?? '';

      return Club(
        id: id,
        name: (data['name'] as String?)?.trim() ?? '',
        category: (data['category'] as String?)?.trim() ?? '',
        imageUrls: _stringList(data['imageUrls']),
        imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
        bannerImageUrl: (data['bannerImageUrl'] as String?)?.trim() ?? '',
        meetingLocation: (data['meetingLocation'] as String?)?.trim() ?? '',
        meetingSchedule: (data['meetingSchedule'] as String?)?.trim() ?? '',
        contactName: (data['contactName'] as String?)?.trim() ?? '',
        contactEmail: (data['contactEmail'] as String?)?.trim() ?? '',
        contactPhone: (data['contactPhone'] as String?)?.trim() ?? '',
        website: (data['website'] as String?)?.trim() ?? '',
        facebook: (data['facebook'] as String?)?.trim() ?? '',
        featured: data['featured'] as bool? ?? false,
        active: data['active'] as bool? ?? true,
        stateId: (data['stateId'] as String?) ?? '',
        stateName: (data['stateName'] as String?) ?? '',
        metroId: (data['metroId'] as String?) ?? '',
        metroName: (data['metroName'] as String?) ?? '',
        areaId: (data['areaId'] as String?) ?? '',
        areaName: (data['areaName'] as String?) ?? '',
        street: (data['street'] as String?)?.trim() ?? '',
        city: (data['city'] as String?)?.trim() ?? '',
        state: (data['state'] as String?)?.trim() ?? '',
        zip: (data['zip'] as String?)?.trim() ?? '',
        address: (data['address'] as String?)?.trim() ?? '',
      );
    }

    throw ArgumentError(
      'Unsupported source type for Club.fromFirestore: ${source.runtimeType}',
    );
  }
}
