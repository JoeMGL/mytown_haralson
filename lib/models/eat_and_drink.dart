import 'package:cloud_firestore/cloud_firestore.dart';

class EatAndDrink {
  final String id;

  final String name;
  final String city;
  final String category;
  final String description;
  final String imageUrl;
  final String heroTag;
  final String? hours;
  final List<String> tags;

  final GeoPoint? coords;
  final String? phone;
  final String? website;
  final String? mapQuery;

  final bool featured;
  final bool active;

  final List<String> search;

  // LOCATION FIELDS
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  EatAndDrink({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.heroTag,
    required this.hours,
    required this.tags,
    required this.coords,
    required this.phone,
    required this.website,
    required this.mapQuery,
    required this.featured,
    required this.active,
    required this.search,
    required this.stateId,
    required this.stateName,
    required this.metroId,
    required this.metroName,
    required this.areaId,
    required this.areaName,
  });

  /// Firestore → Model
  factory EatAndDrink.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return EatAndDrink(
      id: doc.id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      heroTag: data['heroTag'] ?? doc.id, // fallback unique tag
      hours: data['hours'],
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      coords: data['coords'],
      phone: data['phone'],
      website: data['website'],
      mapQuery: data['mapQuery'],
      featured: data['featured'] ?? false,
      active: data['active'] ?? true,
      search: (data['search'] as List?)?.cast<String>() ?? const [],

      stateId: data['stateId'] ?? '',
      stateName: data['stateName'] ?? '',
      metroId: data['metroId'] ?? '',
      metroName: data['metroName'] ?? '',
      areaId: data['areaId'] ?? '',
      areaName: data['areaName'] ?? '',
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'heroTag': heroTag,
      'hours': hours,
      'tags': tags,
      'coords': coords,
      'phone': phone,
      'website': website,
      'mapQuery': mapQuery,
      'featured': featured,
      'active': active,
      'search': search,

      // LOCATION
      'stateId': stateId,
      'stateName': stateName,
      'metroId': metroId,
      'metroName': metroName,
      'areaId': areaId,
      'areaName': areaName,
    };
  }
}
