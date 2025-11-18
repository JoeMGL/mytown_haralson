import 'package:cloud_firestore/cloud_firestore.dart';

class EatAndDrink {
  final String id;

  // Core
  final String name;
  final String city;
  final String category; // slug
  final String description;
  final String imageUrl;
  final String heroTag;

  // Details
  final String? hours;
  final List<String> tags;
  final GeoPoint? coords;
  final String? phone;
  final String? website;
  final String? mapQuery;

  // Flags
  final bool featured;
  final bool active;

  // Search + location
  final List<String> search;
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  // NEW: media
  final List<String> galleryImageUrls;
  final String bannerImageUrl;

  EatAndDrink({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.heroTag,
    this.hours,
    required this.tags,
    this.coords,
    this.phone,
    this.website,
    this.mapQuery,
    required this.featured,
    required this.active,
    required this.search,
    required this.stateId,
    required this.stateName,
    required this.metroId,
    required this.metroName,
    required this.areaId,
    required this.areaName,
    required this.galleryImageUrls,
    required this.bannerImageUrl,
  });

  factory EatAndDrink.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    List<String> _readStringList(String key) {
      final raw = data[key];
      if (raw is Iterable) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return EatAndDrink(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      heroTag: (data['heroTag'] ?? '').toString(),
      hours: data['hours']?.toString(),
      tags: _readStringList('tags'),
      coords: data['coords'] is GeoPoint ? data['coords'] as GeoPoint : null,
      phone: data['phone']?.toString(),
      website: data['website']?.toString(),
      mapQuery: data['mapQuery']?.toString(),
      featured: (data['featured'] ?? false) as bool,
      active: (data['active'] ?? true) as bool,
      search: _readStringList('search'),
      stateId: (data['stateId'] ?? '').toString(),
      stateName: (data['stateName'] ?? '').toString(),
      metroId: (data['metroId'] ?? '').toString(),
      metroName: (data['metroName'] ?? '').toString(),
      areaId: (data['areaId'] ?? '').toString(),
      areaName: (data['areaName'] ?? '').toString(),
      galleryImageUrls: _readStringList('galleryImageUrls'),
      bannerImageUrl: (data['bannerImageUrl'] ?? '').toString(),
    );
  }

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
      'stateId': stateId,
      'stateName': stateName,
      'metroId': metroId,
      'metroName': metroName,
      'areaId': areaId,
      'areaName': areaName,
      'galleryImageUrls': galleryImageUrls,
      'bannerImageUrl': bannerImageUrl,
    };
  }

  EatAndDrink copyWith({
    String? name,
    String? city,
    String? category,
    String? description,
    String? imageUrl,
    String? heroTag,
    String? hours,
    List<String>? tags,
    GeoPoint? coords,
    String? phone,
    String? website,
    String? mapQuery,
    bool? featured,
    bool? active,
    List<String>? search,
    String? stateId,
    String? stateName,
    String? metroId,
    String? metroName,
    String? areaId,
    String? areaName,
    List<String>? galleryImageUrls,
    String? bannerImageUrl,
  }) {
    return EatAndDrink(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      heroTag: heroTag ?? this.heroTag,
      hours: hours ?? this.hours,
      tags: tags ?? this.tags,
      coords: coords ?? this.coords,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      mapQuery: mapQuery ?? this.mapQuery,
      featured: featured ?? this.featured,
      active: active ?? this.active,
      search: search ?? this.search,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      metroId: metroId ?? this.metroId,
      metroName: metroName ?? this.metroName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      galleryImageUrls: galleryImageUrls ?? this.galleryImageUrls,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
    );
  }
}
