import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('userProfiles');

  /// Load existing profile or create a new one with defaults.
  static Future<UserProfile> getOrCreateProfile(String userId) async {
    final docRef = _collection.doc(userId);
    final snap = await docRef.get();

    if (snap.exists) {
      return UserProfile.fromDoc(snap);
    } else {
      final profile = UserProfile.initial(userId);
      await docRef.set(profile.toMap());
      return profile;
    }
  }

  /// Save (merge) profile fields to Firestore.
  static Future<void> saveProfile(UserProfile profile) async {
    await _collection.doc(profile.userId).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }
}
