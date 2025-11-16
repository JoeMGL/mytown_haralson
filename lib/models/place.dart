import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;

  // Core fields
  final String title; // used by ExploreDetailPage
  final String name; // stored in Firestore too
  final String city;
  final String category;

  final String imageUrl;
  final String heroTag;
  final String description;
  final String? hours;
  final List<String> tags;
  final String? mapQuery;

  final GeoPoint? coords;

  // Status flags
  final bool featured;
  final bool active;

  // Search
  final List<String> search;

  // Location fields
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  Place({
    required this.id,
    required this.title,
    required this.name,
    required this.city,
    required this.category,
    required this.imageUrl,
    required this.heroTag,
    required this.description,
    required this.hours,
    required this.tags,
    required this.mapQuery,
    required this.coords,
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

  factory Place.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final storedName = (data['name'] ?? '') as String;
    final storedTitle = (data['title'] ?? '') as String;

    return Place(
      id: doc.id,
      name: storedName,
      title: storedTitle.isNotEmpty ? storedTitle : storedName,
      city: (data['city'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      heroTag: (data['heroTag'] ?? doc.id) as String,
      description: (data['description'] ?? '') as String,
      hours: data['hours'] as String?,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      mapQuery: data['mapQuery'] as String?,
      coords: data['coords'] is GeoPoint ? data['coords'] as GeoPoint? : null,
      featured: (data['featured'] ?? false) as bool,
      active: (data['active'] ?? true) as bool,
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
      'title': title,
      'city': city,
      'category': category,
      'imageUrl': imageUrl,
      'heroTag': heroTag,
      'description': description,
      'hours': hours,
      'tags': tags,
      'mapQuery': mapQuery,
      'coords': coords,
      'featured': featured,
      'active': active,
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
