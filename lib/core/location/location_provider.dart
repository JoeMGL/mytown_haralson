import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_location.dart';

final locationProvider = StreamProvider<AppLocation>((ref) {
  final doc = FirebaseFirestore.instance
      .collection('admin')
      .doc('config')
      .collection('meta')
      .doc('global');

  return doc.snapshots().map((snap) {
    return AppLocation.fromData(snap.data());
  });
});
