// lib/core/location/location_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocation {
  final String? stateId;
  final String? metroId;
  final String? areaId;

  const AppLocation({
    this.stateId,
    this.metroId,
    this.areaId,
  });

  AppLocation copyWith({
    String? stateId,
    String? metroId,
    String? areaId,
  }) {
    return AppLocation(
      stateId: stateId ?? this.stateId,
      metroId: metroId ?? this.metroId,
      areaId: areaId ?? this.areaId,
    );
  }
}

/// StreamProvider that listens to /admin/config/meta/global
/// and maps app.defaultLocation → AppLocation.
final locationProvider = StreamProvider<AppLocation>((ref) {
  final docRef = FirebaseFirestore.instance
      .collection('admin')
      .doc('config')
      .collection('meta')
      .doc('global');

  return docRef.snapshots().map((snap) {
    final data = snap.data() ?? {};
    final app = (data['app'] ?? {}) as Map<String, dynamic>;
    final loc = (app['defaultLocation'] ?? {}) as Map<String, dynamic>;

    final stateId = loc['stateId'] as String?;
    final metroId = loc['metroId'] as String?;
    final areaId = loc['areaId'] as String?;

    return AppLocation(
      stateId: stateId,
      metroId: metroId,
      areaId: areaId,
    );
  });
});
