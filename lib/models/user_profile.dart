import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final bool hasCompletedOnboarding;

  // Location defaults
  final String defaultStateId;
  final String defaultMetroId;
  final String defaultAreaId;

  // Interests & section
  final List<String> interests; // ['eat', 'events', 'parks']
  final String defaultSection;

  // Notifications
  final bool notifGeneral;
  final bool notifEvents;
  final bool notifEatDrink;
  final bool notifClubs;
  final bool notifSavedPlaces;

  // Account info
  final String accountType; // 'anonymous' | 'email' | 'google'

  // Timestamps
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserProfile({
    required this.userId,
    required this.hasCompletedOnboarding,
    required this.defaultStateId,
    required this.defaultMetroId,
    required this.defaultAreaId,
    required this.interests,
    required this.defaultSection,
    required this.notifGeneral,
    required this.notifEvents,
    required this.notifEatDrink,
    required this.notifClubs,
    required this.notifSavedPlaces,
    required this.accountType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Initial empty profile
  factory UserProfile.initial(String userId) {
    final now = Timestamp.now();
    return UserProfile(
      userId: userId,
      hasCompletedOnboarding: false,
      defaultStateId: 'GA',
      defaultMetroId: 'haralson',
      defaultAreaId: 'tallapoosa',
      interests: const [],
      defaultSection: 'home',
      notifGeneral: true,
      notifEvents: true,
      notifEatDrink: false,
      notifClubs: false,
      notifSavedPlaces: true,
      accountType: 'anonymous',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert Firestore → Model
  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: data['userId'] ?? '',
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      defaultStateId: data['defaultStateId'] ?? '',
      defaultMetroId: data['defaultMetroId'] ?? '',
      defaultAreaId: data['defaultAreaId'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      defaultSection: data['defaultSection'] ?? 'home',
      notifGeneral: data['notifGeneral'] ?? true,
      notifEvents: data['notifEvents'] ?? true,
      notifEatDrink: data['notifEatDrink'] ?? false,
      notifClubs: data['notifClubs'] ?? false,
      notifSavedPlaces: data['notifSavedPlaces'] ?? true,
      accountType: data['accountType'] ?? 'anonymous',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Convert Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'defaultStateId': defaultStateId,
      'defaultMetroId': defaultMetroId,
      'defaultAreaId': defaultAreaId,
      'interests': interests,
      'defaultSection': defaultSection,
      'notifGeneral': notifGeneral,
      'notifEvents': notifEvents,
      'notifEatDrink': notifEatDrink,
      'notifClubs': notifClubs,
      'notifSavedPlaces': notifSavedPlaces,
      'accountType': accountType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Immutable model copy
  UserProfile copyWith({
    bool? hasCompletedOnboarding,
    String? defaultStateId,
    String? defaultMetroId,
    String? defaultAreaId,
    List<String>? interests,
    String? defaultSection,
    bool? notifGeneral,
    bool? notifEvents,
    bool? notifEatDrink,
    bool? notifClubs,
    bool? notifSavedPlaces,
    String? accountType,
    Timestamp? updatedAt,
  }) {
    return UserProfile(
      userId: userId,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      defaultStateId: defaultStateId ?? this.defaultStateId,
      defaultMetroId: defaultMetroId ?? this.defaultMetroId,
      defaultAreaId: defaultAreaId ?? this.defaultAreaId,
      interests: interests ?? List<String>.from(this.interests),
      defaultSection: defaultSection ?? this.defaultSection,
      notifGeneral: notifGeneral ?? this.notifGeneral,
      notifEvents: notifEvents ?? this.notifEvents,
      notifEatDrink: notifEatDrink ?? this.notifEatDrink,
      notifClubs: notifClubs ?? this.notifClubs,
      notifSavedPlaces: notifSavedPlaces ?? this.notifSavedPlaces,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt, // always keep original
      updatedAt: updatedAt ?? Timestamp.now(),
    );
  }
}
