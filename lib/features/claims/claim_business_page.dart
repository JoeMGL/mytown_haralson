import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/claim.dart';

/// Lightweight view-model for a place, built directly from Firestore.
/// This avoids depending on whatever your main Place model looks like.
class _PlaceSnapshotView {
  final String id;
  final String name;
  final String street;
  final String city;
  final String state;
  final String zip;
  final bool claimed;

  _PlaceSnapshotView({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.claimed,
  });

  String get fullAddress {
    final line1 = street;
    final line2Parts = <String>[];
    if (city.isNotEmpty) line2Parts.add(city);
    if (state.isNotEmpty) line2Parts.add(state);
    if (zip.isNotEmpty) line2Parts.add(zip);
    final line2 = line2Parts.join(' ');
    if (line1.isEmpty && line2.isEmpty) return '';
    if (line1.isEmpty) return line2;
    if (line2.isEmpty) return line1;
    return '$line1\n$line2';
  }
}

class ClaimBusinessPage extends StatefulWidget {
  const ClaimBusinessPage({
    super.key,
    required this.docPath,
  });

  /// Full Firestore doc path, e.g.:
  /// - eatAndDrink/{id}
  /// - places/{id}
  /// - lodging/{id}
  final String docPath;

  @override
  State<ClaimBusinessPage> createState() => _ClaimBusinessPageState();
}

class _ClaimBusinessPageState extends State<ClaimBusinessPage> {
  int _step = 0;
  bool _loadingPlace = true;
  _PlaceSnapshotView? _place;
  String? _loadError;

  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  String _verificationType = 'email'; // email | document | phone | manual

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    try {
      final doc = await FirebaseFirestore.instance
          .doc(widget
              .docPath) // ✅ use full path instead of hard-coded collection
          .get();

      if (!doc.exists) {
        setState(() {
          _loadError = 'Place not found.';
          _loadingPlace = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Try both name/title and street/address to be flexible
      final name = (data['name'] as String?) ??
          (data['title'] as String?) ??
          'Unnamed place';
      final street =
          (data['street'] as String?) ?? (data['address'] as String?) ?? '';
      final city = data['city'] as String? ?? '';
      final state = data['state'] as String? ?? '';
      final zip = data['zip'] as String? ?? '';
      final claimed = data['claimed'] as bool? ?? false;

      setState(() {
        _place = _PlaceSnapshotView(
          id: doc.id,
          name: name,
          street: street,
          city: city,
          state: state,
          zip: zip,
          claimed: claimed,
        );
        _loadingPlace = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load place: $e';
        _loadingPlace = false;
      });
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _place?.claimed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This business has already been marked as claimed.'),
        ),
      );
      // still allow them to continue if they think it's an error
      setState(() {
        _step++;
      });
      return;
    }

    if (_step == 2) {
      _submitClaim();
      return;
    }

    setState(() {
      _step++;
    });
  }

  void _prevStep() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _step--;
      });
    }
  }

  Future<void> _submitClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to submit a claim.'),
        ),
      );
      return;
    }

    if (_ownerNameCtrl.text.trim().isEmpty ||
        _ownerEmailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and email.')),
      );
      return;
    }

    final place = _place;
    if (place == null) return;

    setState(() {
      _submitting = true;
    });

    try {
      final claimRef =
          FirebaseFirestore.instance.collection('claims').doc(); // auto ID

      final claim = Claim(
        id: claimRef.id,
        placeId: place.id,
        userId: user.uid,
        placeTitle: place.name,
        placeAddress: place.fullAddress,
        ownerName: _ownerNameCtrl.text.trim(),
        ownerEmail: _ownerEmailCtrl.text.trim(),
        ownerPhone: _ownerPhoneCtrl.text.trim(),
        verificationType: _verificationType,
        documentUrls: const [], // hook Storage uploads here later
        status: ClaimStatus.pending,
        submittedAt: DateTime.now(),
        adminNotes: null,
        reviewedAt: null,
      );

      await claimRef.set(claim.toMap());

      setState(() {
        _submitting = false;
      });

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Claim submitted'),
            content: const Text(
              'Thank you! We\'ll review your claim and notify you once it\'s approved.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loadingPlace) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim this business')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claim this business')),
        body: Center(child: Text(_loadError!)),
      );
    }

    final place = _place!;
    final steps = <Widget>[
      _buildConfirmPlaceStep(place, cs),
      _buildVerifyStep(cs),
      _buildOwnerInfoStep(cs),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim this business'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / steps.length,
            backgroundColor: cs.surfaceVariant,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: steps[_step],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _nextStep,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == steps.length - 1
                          ? 'Submit claim'
                          : 'Continue'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPlaceStep(_PlaceSnapshotView place, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1 of 3', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(
          'Confirm your business',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: Text(place.name),
            subtitle: Text(
              place.fullAddress.isEmpty
                  ? 'No address on file'
                  : place.fullAddress,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (place.claimed)
          Text(
            'This business is already marked as claimed. If you believe this is incorrect, you can still submit a claim and we will review it.',
            style: TextStyle(color: cs.error),
          )
        else
          const Text(
            'Please confirm that this is your business. If the details are incorrect, '
            'you\'ll be able to update them after your claim is approved.',
          ),
      ],
    );
  }

  Widget _buildVerifyStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2 of 3', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Text(
          'Choose a verification method',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text(
          'We use this to confirm that you\'re authorized to manage this business.',
        ),
        const SizedBox(height: 16),
        RadioListTile<String>(
          value: 'email',
          groupValue: _verificationType,
          onChanged: (value) => setState(() => _verificationType = value!),
          title: const Text('Business email'),
          subtitle: const Text(
            'We\'ll send a confirmation to a business email address (e.g. you@yourshop.com).',
          ),
        ),
        RadioListTile<String>(
          value: 'document',
          groupValue: _verificationType,
          onChanged: (value) => setState(() => _verificationType = value!),
          title: const Text('Upload a document'),
          subtitle: const Text(
            'You\'ll upload a business license, utility bill, lease, or similar document.',
          ),
        ),
        RadioListTile<String>(
          value: 'phone',
          groupValue: _verificationType,
          onChanged: (value) => setState(() => _verificationType = value!),
          title: const Text('Phone number'),
          subtitle: const Text(
            'We\'ll verify using the business phone number listed on this page.',
          ),
        ),
        RadioListTile<String>(
          value: 'manual',
          groupValue: _verificationType,
          onChanged: (value) => setState(() => _verificationType = value!),
          title: const Text('Manual review'),
          subtitle: const Text(
            'We\'ll review your claim manually if the other methods don\'t work.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'In this first version we\'re just storing your choice and doing manual review on the admin side.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.outline),
        ),
      ],
    );
  }

  Widget _buildOwnerInfoStep(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3 of 3', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            'Your contact information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ownerNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ll only use this information to contact you about your claim and managing your business listing.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
