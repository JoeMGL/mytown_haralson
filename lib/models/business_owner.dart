import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessOwner {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;

  BusinessOwner({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  factory BusinessOwner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BusinessOwner(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
