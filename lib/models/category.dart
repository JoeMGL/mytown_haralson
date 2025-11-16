import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String slug;
  final String section;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.section,
    required this.isActive,
    required this.sortOrder,
  });

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      section: data['section'] ?? '',
      isActive: (data['isActive'] ?? true) as bool,
      sortOrder: (data['sortOrder'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'section': section,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  Category copyWith({
    String? name,
    String? slug,
    String? section,
    bool? isActive,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      section: section ?? this.section,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
