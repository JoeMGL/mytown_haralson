// lib/widgets/claim_banner.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClaimBanner extends StatelessWidget {
  const ClaimBanner({
    super.key,
    required this.docPath,
  });

  /// Full Firestore doc path, e.g.:
  /// - eatAndDrink/{id}
  /// - places/{id}
  /// - lodging/{id}
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
            onPressed: () {
              context.push(
                '/claim',
                extra: docPath, // ✅ pass path to claim page
              );
            },
            child: const Text('Claim'),
          ),
        ),
      ),
    );
  }
}
