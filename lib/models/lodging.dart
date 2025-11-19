import 'package:cloud_firestore/cloud_firestore.dart';

import 'place.dart' show DayHours; // reuse DayHours from Place model

class Stay {
  final String id;

  final String name;
  final String city;
  final String category; // e.g. Hotel, Cabin, Campground

  /// ⭐ NEW: individual address parts
  final String street;
  final String state;
  final String zip;

  /// Combined address, e.g. "123 Main St, Tallapoosa, GA 30176"
  final String address;

  final String description;

  final String imageUrl;
  final String heroTag;

  /// Legacy free-text hours string (e.g. "24/7" or "Check-in 3pm").
  final String? hours;

  /// NEW: structured hours by day, shared with Explore / Eat & Drink.
  /// Stored in Firestore as:
  /// {
  ///   "monday": {"closed": false, "open": "9:00 AM", "close": "5:00 PM"},
  ///   ...
  /// }
  final Map<String, DayHours>? hoursByDay;

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
    this.hoursByDay,
    this.mapQuery,
    this.phone,
    this.website,
    this.featured = false,
    this.active = true,
    this.coords,
    this.tags = const [],
    this.search = const [],

    // ⭐ NEW: optional with defaults so older code still compiles
    this.street = '',
    this.state = '',
    this.zip = '',
    this.stateId = '',
    this.stateName = '',
    this.metroId = '',
    this.metroName = '',
    this.areaId = '',
    this.areaName = '',
  });

  factory Stay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Parse hoursByDay map from Firestore -> Map<String, DayHours>
    Map<String, DayHours>? parsedHoursByDay;
    final rawHoursByDay = data['hoursByDay'];

    if (rawHoursByDay is Map) {
      parsedHoursByDay = rawHoursByDay.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key as String, DayHours.fromMap(value));
        }
        if (value is Map) {
          // In case it's Map<dynamic, dynamic>
          return MapEntry(
            key.toString(),
            DayHours.fromMap(Map<String, dynamic>.from(value)),
          );
        }
        // Fallback: mark as closed if malformed
        return MapEntry(key.toString(), const DayHours(closed: true));
      });
    }

    return Stay(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      category: (data['category'] ?? '') as String,

      // ⭐ NEW: individual address parts (will be '' for old docs)
      street: (data['street'] ?? '') as String,
      state: (data['state'] ?? '') as String,
      zip: (data['zip'] ?? '') as String,

      address: (data['address'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      heroTag: (data['heroTag'] ?? doc.id) as String,

      // legacy text hours
      hours: data['hours'] as String?,

      // structured hours
      hoursByDay: parsedHoursByDay,

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

      // ⭐ NEW: individual address parts
      'street': street,
      'state': state,
      'zip': zip,

      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'heroTag': heroTag,

      // keep both for compatibility
      'hours': hours,
      'hoursByDay': hoursByDay?.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),

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
