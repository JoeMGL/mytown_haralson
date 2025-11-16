// lib/models/shop_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;

  final String name;
  final String category;
  final String city;
  final String address;
  final String description;

  final String? phone;
  final String? website;
  final String? facebook;
  final String? hours;
  final String? imageUrl;

  final bool featured;
  final bool active;

  final List<String> tags;
  final List<String> search;

  // 🔹 Location fields (same pattern as Clubs/Events)
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.address,
    required this.description,
    this.phone,
    this.website,
    this.facebook,
    this.hours,
    this.imageUrl,
    this.featured = false,
    this.active = true,
    this.tags = const [],
    this.search = const [],
    this.stateId = '',
    this.stateName = '',
    this.metroId = '',
    this.metroName = '',
    this.areaId = '',
    this.areaName = '',
  });

  /// Firestore → Model
  factory Shop.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Shop(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      facebook: data['facebook'] as String?,
      hours: data['hours'] as String?,
      imageUrl: data['imageUrl'] as String?,
      featured: (data['featured'] ?? false) as bool,
      active: (data['active'] ?? true) as bool,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      search: (data['search'] as List?)?.cast<String>() ?? const [],
      stateId: (data['stateId'] ?? '') as String,
      stateName: (data['stateName'] ?? '') as String,
      metroId: (data['metroId'] ?? '') as String,
      metroName: (data['metroName'] ?? '') as String,
      areaId: (data['areaId'] ?? '') as String,
      areaName: (data['areaName'] ?? '') as String,
    );
  }

  /// Model → Firestore (without id)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'city': city,
      'address': address,
      'description': description,
      'phone': phone,
      'website': website,
      'facebook': facebook,
      'hours': hours,
      'imageUrl': imageUrl,
      'featured': featured,
      'active': active,
      'tags': tags,
      'search': search,
      'stateId': stateId,
      'stateName': stateName,
      'metroId': metroId,
      'metroName': metroName,
      'areaId': areaId,
      'areaName': areaName,
    };
  }
}
