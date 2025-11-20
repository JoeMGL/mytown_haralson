// lib/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;

  final String title;

  // Address pieces
  final String address; // street line 1
  final String city;
  final String state;
  final String zip;

  final String category;
  final String venue;

  final String description;
  final String? website;

  final bool featured;
  final bool allDay;
  final bool free;
  final double price;

  final DateTime start;
  final DateTime end;

  final String? imageUrl; // main image
  final List<String> tags;
  final List<String> search;

  // 🔹 New: gallery + banner
  final List<String> galleryImageUrls;
  final String bannerImageUrl;

  // 🔹 Location fields (mirroring Clubs)
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;

  Event({
    required this.id,
    required this.title,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.category,
    required this.venue,
    required this.description,
    required this.website,
    required this.featured,
    required this.allDay,
    required this.free,
    required this.price,
    required this.start,
    required this.end,
    required this.imageUrl,
    required this.tags,
    required this.search,
    this.galleryImageUrls = const [],
    this.bannerImageUrl = '',
    this.stateId = '',
    this.stateName = '',
    this.metroId = '',
    this.metroName = '',
    this.areaId = '',
    this.areaName = '',
  });

  /// Create from Firestore document
  factory Event.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Event(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      state: (data['state'] ?? '') as String,
      zip: (data['zip'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      venue: (data['venue'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      website: data['website'] as String?,
      featured: (data['featured'] ?? false) as bool,
      allDay: (data['allDay'] ?? false) as bool,
      free: (data['free'] ?? false) as bool,
      price: _toDouble(data['price']),
      start: _toDate(data['start']),
      end: _toDate(data['end']),
      imageUrl: data['imageUrl'] as String?,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      search: (data['search'] as List?)?.cast<String>() ?? const [],

      // 🔹 New gallery fields (safe defaults for old docs)
      galleryImageUrls:
          (data['galleryImageUrls'] as List?)?.cast<String>() ?? const [],
      bannerImageUrl: (data['bannerImageUrl'] ?? '') as String,

      // 🔹 Location (safe defaults for old docs)
      stateId: (data['stateId'] ?? '') as String,
      stateName: (data['stateName'] ?? '') as String,
      metroId: (data['metroId'] ?? '') as String,
      metroName: (data['metroName'] ?? '') as String,
      areaId: (data['areaId'] ?? '') as String,
      areaName: (data['areaName'] ?? '') as String,
    );
  }

  /// Convert to Firestore data (without id)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'category': category,
      'venue': venue,
      'description': description,
      'website': website,
      'featured': featured,
      'allDay': allDay,
      'free': free,
      'price': price,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'imageUrl': imageUrl,
      'tags': tags,
      'search': search,

      // 🔹 Gallery fields
      'galleryImageUrls': galleryImageUrls,
      'bannerImageUrl': bannerImageUrl.isEmpty ? null : bannerImageUrl,

      // 🔹 Location
      'stateId': stateId,
      'stateName': stateName,
      'metroId': metroId,
      'metroName': metroName,
      'areaId': areaId,
      'areaName': areaName,
    };
  }

  // ---- Helpers ----

  static DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    throw Exception('Invalid date value: $v');
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    final parsed = double.tryParse(v.toString());
    return parsed ?? 0;
  }
}
