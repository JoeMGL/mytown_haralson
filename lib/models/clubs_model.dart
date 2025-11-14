// lib/models/club.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;
  final String name;
  final String city;
  final String category;

  final String meetingLocation;
  final String meetingSchedule;

  final String contactName;
  final String contactEmail;
  final String contactPhone;

  final String website;
  final String facebook;

  final bool featured;
  final bool active;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Club({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.meetingLocation,
    required this.meetingSchedule,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.website,
    required this.facebook,
    required this.featured,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a Club object from Firestore
  factory Club.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Club(
      id: doc.id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      meetingLocation: data['meetingLocation'] ?? '',
      meetingSchedule: data['meetingSchedule'] ?? '',
      contactName: data['contactName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      website: data['website'] ?? '',
      facebook: data['facebook'] ?? '',
      featured: data['featured'] ?? false,
      active: data['active'] ?? true,
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  /// Convert Club to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'category': category,
      'meetingLocation': meetingLocation,
      'meetingSchedule': meetingSchedule,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'facebook': facebook,
      'featured': featured,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Helper to convert a Firestore Timestamp to DateTime
  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return value as DateTime?;
  }
}
