import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/claim.dart';
import '../../../models/business_owner.dart';

class AdminClaimDetailPage extends StatefulWidget {
  const AdminClaimDetailPage({
    super.key,
    required this.claimId,
  });

  final String claimId;

  @override
  State<AdminClaimDetailPage> createState() => _AdminClaimDetailPageState();
}

class _AdminClaimDetailPageState extends State<AdminClaimDetailPage> {
  Claim? _claim;
  bool _loading = true;
  String? _error;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClaim();
  }

  Future<void> _loadClaim() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('claims')
          .doc(widget.claimId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Claim not found.';
          _loading = false;
        });
        return;
      }

      final claim = Claim.fromDoc(doc);
      _notesCtrl.text = claim.adminNotes ?? '';

      setState(() {
        _claim = claim;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load claim: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // Local helper: convert enum -> string for Firestore
  String _statusToStringLocal(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return 'approved';
      case ClaimStatus.rejected:
        return 'rejected';
      case ClaimStatus.pending:
      default:
        return 'pending';
    }
  }

  Future<void> _updateStatus(ClaimStatus status) async {
    if (_claim == null) return;

    setState(() => _loading = true);

    final claim = _claim!;
    final now = DateTime.now();

    try {
      final batch = FirebaseFirestore.instance.batch();

      final claimRef =
          FirebaseFirestore.instance.collection('claims').doc(claim.id);
      batch.update(claimRef, {
        'status': _statusToStringLocal(status),
        'adminNotes': _notesCtrl.text.trim(),
        'reviewedAt': Timestamp.fromDate(now),
      });

      if (status == ClaimStatus.approved) {
        // Create / update business owner
        final ownerRef =
            FirebaseFirestore.instance.collection('businessOwners').doc();
        batch.set(
          ownerRef,
          BusinessOwner(
            id: ownerRef.id,
            userId: claim.userId,
            name: claim.ownerName,
            email: claim.ownerEmail,
            phone: claim.ownerPhone,
            createdAt: now,
          ).toMap(),
        );

        // Update place
        final placeRef = FirebaseFirestore.instance
            .collection('places') // 🔁 change if your places live elsewhere
            .doc(claim.placeId);
        batch.update(placeRef, {
          'claimed': true,
          'ownerUserId': claim.userId,
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop(); // back to claims list
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update claim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _claim == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim details')),
        body: Center(child: Text(_error ?? 'Unknown error')),
      );
    }

    final claim = _claim!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              claim.placeTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(claim.placeAddress),
            const Divider(height: 32),
            ListTile(
              title: Text(claim.ownerName),
              subtitle: Text('${claim.ownerEmail}\n${claim.ownerPhone}'),
              isThreeLine: true,
              leading: const Icon(Icons.person),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('Verification method'),
              subtitle: Text(claim.verificationType),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Admin notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                    ),
                    onPressed: () => _updateStatus(ClaimStatus.rejected),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve & link'),
                    onPressed: () => _updateStatus(ClaimStatus.approved),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
