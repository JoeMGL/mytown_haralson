import 'package:cloud_firestore/cloud_firestore.dart';

class Section {
  final String id; // Firestore document id
  final String name; // Human label, e.g. "Eat & Drink"
  final String slug; // Key used in code, e.g. "eat"
  final bool isActive;
  final int sortOrder;

  Section({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.sortOrder,
  });

  factory Section.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Section(
      id: doc.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      isActive: (data['isActive'] ?? true) as bool,
      sortOrder: (data['sortOrder'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  Section copyWith({
    String? name,
    String? slug,
    bool? isActive,
    int? sortOrder,
  }) {
    return Section(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
