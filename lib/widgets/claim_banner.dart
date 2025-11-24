// lib/widgets/claim_banner.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/require_full_account.dart';

class ClaimBanner extends StatelessWidget {
  const ClaimBanner({
    super.key,
    required this.docPath,
  });

  final String docPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Card(
        elevation: 0,
        color: cs.surfaceVariant.withOpacity(0.8),
        child: ListTile(
          leading: const Icon(Icons.verified_user),
          title: const Text('Is this your business?'),
          subtitle: const Text(
            'Claim this page to update information, add photos, and post announcements.',
          ),
          trailing: TextButton(
            onPressed: () async {
              await _handleClaim(context);
            },
            child: const Text('Claim'),
          ),
        ),
      ),
    );
  }

  Future<void> _handleClaim(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // No user or anonymous user → require account upgrade
    if (user == null || user.isAnonymous) {
      await requireFullAccount(
        context,
        action: (fullUser) async {
          // After user signs in or upgrades from anonymous:
          context.push('/claim', extra: docPath);
        },
      );
      return;
    }

    // Already full account → proceed directly
    context.push('/claim', extra: docPath);
  }
}
