import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../services/user_profile_service.dart';
import '../../models/user_profile.dart';

import 'package:google_sign_in/google_sign_in.dart';

/// Call this before any action that should require a "real" account
/// (saving favorites, joining clubs, posting, etc.)
///
/// If the user is already non-anonymous, [action] runs immediately.
/// If they're anonymous, we show a bottom sheet prompting upgrade.
Future<void> requireFullAccount(
  BuildContext context, {
  required Future<void> Function(User user) action,
}) async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;

  // No user at all? Very rare with your flow, but handle gracefully.
  if (user == null) {
    await showCompleteAccountSheet(context);
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null && !refreshed.isAnonymous) {
      await action(refreshed);
    }
    return;
  }

  // Already a full account → just run the action
  if (!user.isAnonymous) {
    await action(user);
    return;
  }

  // Anonymous user → prompt upgrade
  await showCompleteAccountSheet(context);

  // After sheet completes, refresh user
  final upgradedUser = FirebaseAuth.instance.currentUser;
  if (upgradedUser != null && !upgradedUser.isAnonymous) {
    await action(upgradedUser);
  }
}

Future<void> showCompleteAccountSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return const _CompleteAccountSheet();
    },
  );
}

class _CompleteAccountSheet extends StatefulWidget {
  const _CompleteAccountSheet();

  @override
  State<_CompleteAccountSheet> createState() => _CompleteAccountSheetState();
}

class _CompleteAccountSheetState extends State<_CompleteAccountSheet> {
  bool _loadingGoogle = false;
  bool _loadingEmail = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Complete your account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a free account so we can save your favorites, clubs, and trip plans across devices.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: cs.error),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingGoogle ? null : _handleGoogle,
              icon: _loadingGoogle
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.account_circle),
              label: Text(
                  _loadingGoogle ? 'Connecting...' : 'Continue with Google'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _loadingEmail ? null : _handleEmail,
              child:
                  Text(_loadingEmail ? 'Connecting...' : 'Continue with email'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // "Not now"
            },
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _loadingGoogle = true;
      _error = null;
    });

    try {
      await _upgradeAnonymousWithGoogle();
      if (mounted) Navigator.of(context).pop(); // close sheet on success
    } catch (e) {
      setState(() {
        _error = 'We couldn\'t connect your Google account. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGoogle = false;
        });
      }
    }
  }

  Future<void> _handleEmail() async {
    setState(() {
      _loadingEmail = true;
      _error = null;
    });

    try {
      // Navigate to your email sign-in/sign-up page
      if (mounted) {
        Navigator.of(context).pop();
        context.push('/login'); // or a dedicated /signup route
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingEmail = false;
        });
      }
    }
  }
}

Future<void> _upgradeAnonymousWithGoogle() async {
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;

  if (currentUser == null) {
    throw Exception('No current user to upgrade.');
  }

  // 1. Get Google credential
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) {
    throw Exception('Google sign-in aborted.');
  }

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  User userAfter;

  if (currentUser.isAnonymous) {
    // 2A. Upgrade existing anonymous account by linking
    final linked = await currentUser.linkWithCredential(credential);
    userAfter = linked.user!;
  } else {
    // 2B. Already non-anonymous, just sign in with Google
    final result = await auth.signInWithCredential(credential);
    userAfter = result.user!;
  }

  // 3. Update profile.accountType in Firestore
  final profile = await UserProfileService.getOrCreateProfile(userAfter.uid);
  final updated = profile.copyWith(accountType: 'google');
  await UserProfileService.saveProfile(updated);
}
