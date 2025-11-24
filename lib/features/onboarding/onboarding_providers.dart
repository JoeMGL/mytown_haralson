import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Loads (or creates) the user profile for the current Firebase user.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;

  if (user == null) {
    // ⚠️ THIS LINE: requires Anonymous sign-in to be enabled
    final cred = await auth.signInAnonymously();
    return UserProfileService.getOrCreateProfile(cred.user!.uid);
  }

  return UserProfileService.getOrCreateProfile(user.uid);
});

/// Onboarding state (mutable while user taps through steps)
class OnboardingState {
  final int stepIndex;

  final String stateId;
  final String metroId;
  final String areaId;

  final List<String> interests;
  final String defaultSection;

  final bool notifGeneral;
  final bool notifEvents;
  final bool notifEatDrink;
  final bool notifClubs;
  final bool notifSavedPlaces;

  final bool locationPermissionGranted;

  OnboardingState({
    required this.stepIndex,
    required this.stateId,
    required this.metroId,
    required this.areaId,
    required this.interests,
    required this.defaultSection,
    required this.notifGeneral,
    required this.notifEvents,
    required this.notifEatDrink,
    required this.notifClubs,
    required this.notifSavedPlaces,
    required this.locationPermissionGranted,
  });

  factory OnboardingState.fromProfile(UserProfile profile) {
    return OnboardingState(
      stepIndex: 0,
      stateId: profile.defaultStateId,
      metroId: profile.defaultMetroId,
      areaId: profile.defaultAreaId,
      interests: List<String>.from(profile.interests),
      defaultSection: profile.defaultSection,
      notifGeneral: profile.notifGeneral,
      notifEvents: profile.notifEvents,
      notifEatDrink: profile.notifEatDrink,
      notifClubs: profile.notifClubs,
      notifSavedPlaces: profile.notifSavedPlaces,
      locationPermissionGranted: false,
    );
  }

  OnboardingState copyWith({
    int? stepIndex,
    String? stateId,
    String? metroId,
    String? areaId,
    List<String>? interests,
    String? defaultSection,
    bool? notifGeneral,
    bool? notifEvents,
    bool? notifEatDrink,
    bool? notifClubs,
    bool? notifSavedPlaces,
    bool? locationPermissionGranted,
  }) {
    return OnboardingState(
      stepIndex: stepIndex ?? this.stepIndex,
      stateId: stateId ?? this.stateId,
      metroId: metroId ?? this.metroId,
      areaId: areaId ?? this.areaId,
      interests: interests ?? this.interests,
      defaultSection: defaultSection ?? this.defaultSection,
      notifGeneral: notifGeneral ?? this.notifGeneral,
      notifEvents: notifEvents ?? this.notifEvents,
      notifEatDrink: notifEatDrink ?? this.notifEatDrink,
      notifClubs: notifClubs ?? this.notifClubs,
      notifSavedPlaces: notifSavedPlaces ?? this.notifSavedPlaces,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState?> {
  OnboardingNotifier() : super(null);

  void loadFromProfile(UserProfile profile) {
    state = OnboardingState.fromProfile(profile);
  }

  void nextStep() {
    if (state == null) return;
    state = state!.copyWith(stepIndex: state!.stepIndex + 1);
  }

  void prevStep() {
    if (state == null) return;
    if (state!.stepIndex == 0) return;
    state = state!.copyWith(stepIndex: state!.stepIndex - 1);
  }

  void updateLocation({
    required String stateId,
    required String metroId,
    required String areaId,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      stateId: stateId,
      metroId: metroId,
      areaId: areaId,
    );
  }

  void toggleInterest(String key) {
    if (state == null) return;
    final interests = List<String>.from(state!.interests);
    if (interests.contains(key)) {
      interests.remove(key);
    } else {
      interests.add(key);
    }
    state = state!.copyWith(interests: interests);
  }

  void setDefaultSection(String section) {
    if (state == null) return;
    state = state!.copyWith(defaultSection: section);
  }

  void setNotifications({
    bool? general,
    bool? events,
    bool? eatDrink,
    bool? clubs,
    bool? savedPlaces,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      notifGeneral: general ?? state!.notifGeneral,
      notifEvents: events ?? state!.notifEvents,
      notifEatDrink: eatDrink ?? state!.notifEatDrink,
      notifClubs: clubs ?? state!.notifClubs,
      notifSavedPlaces: savedPlaces ?? state!.notifSavedPlaces,
    );
  }

  void setLocationPermissionGranted(bool granted) {
    if (state == null) return;
    state = state!.copyWith(locationPermissionGranted: granted);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState?>((ref) {
  return OnboardingNotifier();
});
