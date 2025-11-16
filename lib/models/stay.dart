import 'package:cloud_firestore/cloud_firestore.dart';

class Stay {
  final String id;

  final String name;
  final String city;
  final String category; // e.g. Hotel, Cabin, Campground
  final String address;
  final String description;

  final String imageUrl;
  final String heroTag;
  final String? hours;
  final String? mapQuery;
  final String? phone;
  final String? website;

  final bool featured;
  final bool active;
  final GeoPoint? coords;

  final List<String> tags;
  final List<String> search;

  // 🔹 Location fields
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  Stay({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.address,
    required this.description,
    required this.imageUrl,
    required this.heroTag,
    this.hours,
    this.mapQuery,
    this.phone,
    this.website,
    this.featured = false,
    this.active = true,
    this.coords,
    this.tags = const [],
    this.search = const [],
    this.stateId = '',
    this.stateName = '',
    this.metroId = '',
    this.metroName = '',
    this.areaId = '',
    this.areaName = '',
  });

  factory Stay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Stay(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      heroTag: (data['heroTag'] ?? doc.id) as String,
      hours: data['hours'] as String?,
      mapQuery: data['mapQuery'] as String?,
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      featured: (data['featured'] ?? false) as bool,
      active: (data['active'] ?? true) as bool,
      coords: data['coords'] is GeoPoint ? data['coords'] as GeoPoint? : null,
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'category': category,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'heroTag': heroTag,
      'hours': hours,
      'mapQuery': mapQuery,
      'phone': phone,
      'website': website,
      'featured': featured,
      'active': active,
      'coords': coords,
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
