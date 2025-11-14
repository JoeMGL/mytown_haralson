import 'package:cloud_firestore/cloud_firestore.dart';

class Stay {
  final String id;
  final String name;
  final String city;
  final String type; // Hotel / Motel, Cabin, RV Park, B&B, Vacation Rental
  final String address;
  final String phone;
  final String website;

  final bool hasBreakfast;
  final bool hasPool;
  final bool petFriendly;
  final bool featured;

  final List<String> search;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Stay({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.address,
    required this.phone,
    required this.website,
    required this.hasBreakfast,
    required this.hasPool,
    required this.petFriendly,
    required this.featured,
    required this.search,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert Firestore document → Stay model
  factory Stay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return Stay(
      id: doc.id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      type: data['type'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      website: data['website'] ?? '',
      hasBreakfast: data['hasBreakfast'] ?? false,
      hasPool: data['hasPool'] ?? false,
      petFriendly: data['petFriendly'] ?? false,
      featured: data['featured'] ?? false,
      search: List<String>.from(data['search'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert Stay → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'type': type,
      'address': address,
      'phone': phone,
      'website': website,
      'hasBreakfast': hasBreakfast,
      'hasPool': hasPool,
      'petFriendly': petFriendly,
      'featured': featured,
      'search': search,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Shallow copy with changes
  Stay copyWith({
    String? id,
    String? name,
    String? city,
    String? type,
    String? address,
    String? phone,
    String? website,
    bool? hasBreakfast,
    bool? hasPool,
    bool? petFriendly,
    bool? featured,
    List<String>? search,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Stay(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      type: type ?? this.type,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      hasBreakfast: hasBreakfast ?? this.hasBreakfast,
      hasPool: hasPool ?? this.hasPool,
      petFriendly: petFriendly ?? this.petFriendly,
      featured: featured ?? this.featured,
      search: search ?? this.search,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
