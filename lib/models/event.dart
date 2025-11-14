// lib/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;

  final String title;
  final String city;
  final String category;
  final String venue;
  final String address;

  final String description;
  final String? website;

  final bool featured;
  final bool allDay;
  final bool free;
  final double price;

  final DateTime start;
  final DateTime end;

  final String? imageUrl; // optional, for future use
  final List<String> tags;
  final List<String> search;

  Event({
    required this.id,
    required this.title,
    required this.city,
    required this.category,
    required this.venue,
    required this.address,
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
  });

  /// Create from Firestore document
  factory Event.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Event(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      city: (data['city'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      venue: (data['venue'] ?? '') as String,
      address: (data['address'] ?? '') as String,
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
    );
  }

  /// Convert to Firestore data (without id)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'city': city,
      'category': category,
      'venue': venue,
      'address': address,
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
