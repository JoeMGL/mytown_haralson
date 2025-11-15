// lib/models/clubs_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Club {
  final String id;

  // Location
  final String stateId;
  final String stateName;
  final String metroId;
  final String metroName;
  final String areaId;
  final String areaName;
  final String address;

  // Core fields
  final String name;
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
    required this.stateId,
    required this.stateName,
    required this.metroId,
    required this.metroName,
    required this.areaId,
    required this.areaName,
    required this.address,
    required this.name,
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

  /// Firestore → Model
  factory Club.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Club(
      id: doc.id,
      stateId: data['stateId'] ?? '',
      stateName: data['stateName'] ?? '',
      metroId: data['metroId'] ?? '',
      metroName: data['metroName'] ?? '',
      areaId: data['areaId'] ?? '',
      areaName: data['areaName'] ?? '',
      address: data['address'] ?? '',
      name: data['name'] ?? '',
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

  /// Model → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'stateId': stateId,
      'stateName': stateName,
      'metroId': metroId,
      'metroName': metroName,
      'areaId': areaId,
      'areaName': areaName,
      'address': address,
      'name': name,
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

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return value as DateTime?;
  }
}
