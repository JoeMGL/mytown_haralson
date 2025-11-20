import 'package:cloud_firestore/cloud_firestore.dart';

enum ClaimStatus { pending, approved, rejected }

class Claim {
  final String id;
  final String placeId;
  final String userId;
  final String placeTitle;
  final String placeAddress;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String verificationType; // email, document, phone, manual
  final List<String> documentUrls;
  final ClaimStatus status;
  final String? adminNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  Claim({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.placeTitle,
    required this.placeAddress,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.verificationType,
    required this.documentUrls,
    required this.status,
    required this.submittedAt,
    this.adminNotes,
    this.reviewedAt,
  });

  factory Claim.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Claim(
      id: doc.id,
      placeId: data['placeId'] as String,
      userId: data['userId'] as String,
      placeTitle: data['placeTitle'] as String? ?? '',
      placeAddress: data['placeAddress'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
      ownerPhone: data['ownerPhone'] as String? ?? '',
      verificationType: data['verificationType'] as String? ?? 'manual',
      documentUrls: List<String>.from(data['documentUrls'] ?? const []),
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      adminNotes: data['adminNotes'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
      'placeTitle': placeTitle,
      'placeAddress': placeAddress,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'verificationType': verificationType,
      'documentUrls': documentUrls,
      'status': _statusToString(status),
      'adminNotes': adminNotes,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  static ClaimStatus _statusFromString(String value) {
    switch (value) {
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      default:
        return ClaimStatus.pending;
    }
  }

  static String _statusToString(ClaimStatus value) {
    switch (value) {
      case ClaimStatus.approved:
        return 'approved';
      case ClaimStatus.rejected:
        return 'rejected';
      case ClaimStatus.pending:
      default:
        return 'pending';
    }
  }

  Claim copyWith({
    ClaimStatus? status,
    String? adminNotes,
    DateTime? reviewedAt,
  }) {
    return Claim(
      id: id,
      placeId: placeId,
      userId: userId,
      placeTitle: placeTitle,
      placeAddress: placeAddress,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
      verificationType: verificationType,
      documentUrls: documentUrls,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
