import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents opening hours for a single day.
class DayHours {
  /// Whether the place is closed this day.
  final bool closed;

  /// Opening time as a display string, e.g. "9:00 AM".
  final String? open;

  /// Closing time as a display string, e.g. "5:00 PM".
  final String? close;

  const DayHours({
    required this.closed,
    this.open,
    this.close,
  });

  factory DayHours.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const DayHours(closed: true);
    }
    return DayHours(
      closed: data['closed'] as bool? ?? false,
      open: data['open'] as String?,
      close: data['close'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'closed': closed,
      'open': open,
      'close': close,
    };
  }
}

class Place {
  final String id;

  // Core fields
  final String title; // used by ExploreDetailPage
  final String name; // stored in Firestore too

  // Address
  final String street;
  final String city;
  final String state;
  final String zip;

  // Category / content
  final String category;
  final String imageUrl;
  final String heroTag;
  final String description;

  /// Legacy free-text hours (optional, e.g. "Mon–Sat 10–6")
  final String? hours;

  /// Structured hours by day, keyed by "mon","tue","wed","thu","fri","sat","sun".
  final Map<String, DayHours> hoursByDay;

  final List<String> tags;
  final String? mapQuery;

  final GeoPoint? coords;

  // Status flags
  final bool featured;
  final bool active;

  // Search
  final List<String> search;

  // Location fields (Visit Haralson multi-state / metro)
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
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.category,
    required this.imageUrl,
    required this.heroTag,
    required this.description,
    required this.hours,
    required this.hoursByDay,
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

    // Parse structured hours map if present
    final rawHoursByDay = data['hoursByDay'];
    final Map<String, DayHours> parsedHoursByDay = {};
    if (rawHoursByDay is Map<String, dynamic>) {
      rawHoursByDay.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedHoursByDay[key] = DayHours.fromMap(value);
        }
      });
    }

    return Place(
      id: doc.id,
      name: storedName,
      title: storedTitle.isNotEmpty ? storedTitle : storedName,

      // Address
      street: (data['street'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      state: (data['state'] ?? '') as String,
      zip: (data['zip'] ?? '') as String,

      category: (data['category'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      heroTag: (data['heroTag'] ?? doc.id) as String,
      description: (data['description'] ?? '') as String,

      // hours
      hours: data['hours'] as String?,
      hoursByDay: parsedHoursByDay,

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

      // Address
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,

      'category': category,
      'imageUrl': imageUrl,
      'heroTag': heroTag,
      'description': description,

      'hours': hours,
      'hoursByDay':
          hoursByDay.map((key, value) => MapEntry(key, value.toMap())),

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
