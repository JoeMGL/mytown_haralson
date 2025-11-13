import 'package:cloud_firestore/cloud_firestore.dart';

class EatAndDrink {
  final String id;
  final String name;
  final String city;
  final String category;
  final String description;
  final String imageUrl;
  final String? hours;
  final List<String> tags;
  final GeoPoint? coords;
  final String? phone;
  final String? website;
  final String? mapQuery;
  final bool featured;

  EatAndDrink({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.hours,
    this.tags = const [],
    this.coords,
    this.phone,
    this.website,
    this.mapQuery,
    this.featured = false,
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
      hours: data['hours'],
      tags: data['tags'] == null ? [] : List<String>.from(data['tags'] as List),
      coords: data['coords'],
      phone: data['phone'],
      website: data['website'],
      mapQuery: data['mapQuery'],
      featured: data['featured'] ?? false,
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
      'hours': hours,
      'tags': tags,
      'coords': coords,
      'phone': phone,
      'website': website,
      'mapQuery': mapQuery,
      'featured': featured,
    };
  }

  /// For Hero animation tags
  String get heroTag => 'eat_$id';
}
