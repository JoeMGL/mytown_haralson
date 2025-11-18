// lib/models/clubs_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;

  // Location (logical location selection)
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  // Address (postal)
  final String street;
  final String city;
  final String state; // postal state (GA, AL, etc.)
  final String zip;
  final String address; // combined / legacy formatted address

  // Core fields
  final String name;
  final String category;

  // Images
  final List<String> imageUrls; // gallery
  final String bannerImageUrl; // banner / hero

  final String meetingLocation;
  final String meetingSchedule;

  final String contactName;
  final String contactEmail;
  final String contactPhone;

  final String website;
  final String facebook;

  final bool featured;
  final bool active;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Club({
    required this.id,
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
    required this.name,
    required this.category,
    required this.imageUrls,
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
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore → Model
  factory Club.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Multi-images (with legacy support)
    List<String> parsedImageUrls = [];
    final rawImageUrls = data['imageUrls'];

    if (rawImageUrls is List) {
      parsedImageUrls = rawImageUrls
          .where((e) => e != null)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    if (parsedImageUrls.isEmpty && data['imageUrl'] != null) {
      final legacy = data['imageUrl'].toString().trim();
      if (legacy.isNotEmpty) {
        parsedImageUrls = [legacy];
      }
    }

    // Banner: prefer explicit bannerImageUrl, fallback to imageUrl / first gallery image
    String banner = (data['bannerImageUrl'] ?? '').toString().trim();
    if (banner.isEmpty && data['imageUrl'] != null) {
      banner = data['imageUrl'].toString().trim();
    }
    if (banner.isEmpty && parsedImageUrls.isNotEmpty) {
      banner = parsedImageUrls.first;
    }

    final street = data['street'] ?? '';
    final city = data['city'] ?? '';
    final state = data['state'] ?? '';
    final zip = data['zip'] ?? '';

    // Legacy combined address (or derive from parts if missing)
    String addr = data['address'] ?? '';
    if ((addr as String).trim().isEmpty) {
      final parts = [street, city, state, zip]
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      addr = parts.join(', ');
    }

    return Club(
      id: doc.id,
      stateId: data['stateId'] ?? '',
      stateName: data['stateName'] ?? '',
      metroId: data['metroId'] ?? '',
      metroName: data['metroName'] ?? '',
      areaId: data['areaId'] ?? '',
      areaName: data['areaName'] ?? '',
      street: street,
      city: city,
      state: state,
      zip: zip,
      address: addr,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      imageUrls: parsedImageUrls,
      bannerImageUrl: banner,
      meetingLocation: data['meetingLocation'] ?? '',
      meetingSchedule: data['meetingSchedule'] ?? '',
      contactName: data['contactName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      website: data['website'] ?? '',
      facebook: data['facebook'] ?? '',
      featured: data['featured'] ?? false,
      active: data['active'] ?? true,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  /// Model → Firestore map
  Map<String, dynamic> toMap() {
    final combinedAddress = address.isNotEmpty
        ? address
        : [street, city, state, zip]
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join(', ');

    return {
      'stateId': stateId,
      'stateName': stateName,
      'metroId': metroId,
      'metroName': metroName,
      'areaId': areaId,
      'areaName': areaName,

      // Address parts
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'address': combinedAddress,

      'name': name,
      'category': category,

      // images
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
      'bannerImageUrl': bannerImageUrl,

      'meetingLocation': meetingLocation,
      'meetingSchedule': meetingSchedule,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'facebook': facebook,
      'featured': featured,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return value as DateTime?;
  }
}
