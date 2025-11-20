import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/claim.dart';
import 'admin_claim_detail_page.dart';

class AdminClaimsPage extends StatelessWidget {
  const AdminClaimsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Claims'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('claims')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No claims yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final claim = Claim.fromDoc(docs[index]);
              final statusColor = _statusColor(claim.status, cs);

              return ListTile(
                title: Text(claim.placeTitle),
                subtitle: Text(
                  '${claim.ownerName} • ${claim.ownerEmail}\n${claim.placeAddress}',
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(_statusLabel(claim.status)),
                  backgroundColor: statusColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: statusColor),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminClaimDetailPage(claimId: claim.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(ClaimStatus status, ColorScheme cs) {
    switch (status) {
      case ClaimStatus.approved:
        return cs.primary;
      case ClaimStatus.rejected:
        return cs.error;
      case ClaimStatus.pending:
      default:
        return cs.secondary;
    }
  }

  String _statusLabel(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.pending:
      default:
        return 'Pending';
    }
  }
}
