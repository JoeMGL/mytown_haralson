import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Wraps the whole app and listens for `forceLogoutAt` changes
/// on the current user's Firestore doc.
///
/// When `forceLogoutAt` is non-null, the user is signed out.
class ForceLogoutListener extends StatefulWidget {
  final Widget child;

  const ForceLogoutListener({
    super.key,
    required this.child,
  });

  @override
  State<ForceLogoutListener> createState() => _ForceLogoutListenerState();
}

class _ForceLogoutListenerState extends State<ForceLogoutListener> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      // Whenever auth state changes, cancel any previous doc listener
      _userDocSub?.cancel();
      _userDocSub = null;

      if (user == null) {
        return; // not signed in → nothing to watch
      }

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      _userDocSub = docRef.snapshots().listen((snapshot) async {
        final data = snapshot.data();
        if (data == null) return;

        final forceLogoutAt = data['forceLogoutAt'];

        if (forceLogoutAt != null) {
          // Optional: message before sign out
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'You have been signed out by an administrator.',
                ),
              ),
            );
          }

          await FirebaseAuth.instance.signOut();
          // We do NOT clear forceLogoutAt here because after sign out we
          // no longer have permission to write this doc. Admin clears it
          // or switches to disabling if they want a long-term block.
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
