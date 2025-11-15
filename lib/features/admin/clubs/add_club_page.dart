// lib/features/admin/clubs/add_club_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../widgets/location_selector.dart';

class AddClubPage extends StatefulWidget {
  const AddClubPage({super.key});

  @override
  State<AddClubPage> createState() => _AddClubPageState();
}

class _AddClubPageState extends State<AddClubPage> {
  final _form = GlobalKey<FormState>();

  // Club fields
  String _name = '';
  String _category = 'Civic / Service';
  String _meetingLocation = '';
  String _meetingSchedule = '';
  String _contactName = '';
  String _contactEmail = '';
  String _contactPhone = '';
  String _website = '';
  String _facebook = '';
  bool _featured = false;
  bool _saving = false;

  // Location fields (state / metro / area / city)
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;
  String _address = '';

  // Loaded docs
  List<QueryDocumentSnapshot> _states = [];
  List<QueryDocumentSnapshot> _metros = [];
  List<QueryDocumentSnapshot> _areas = [];

  static const _categories = [
    'Civic / Service',
    'Youth Sports',
    'Adult Sports',
    'Church / Faith-based',
    'Nonprofit',
    'School / Booster',
    'Hobby / Special Interest',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .orderBy('name')
          .get();

      setState(() {
        _states = snap.docs;

        // Optionally auto-select first state and load its metros
        if (_states.isNotEmpty && _stateId == null) {
          final first = _states.first;
          _stateId = first.id;
          final data = first.data() as Map<String, dynamic>;
          _stateName = data['name'] ?? '';
          _loadMetros();
        }
      });
    } catch (e) {
      debugPrint('Error loading states: $e');
    }
  }

  Future<void> _loadMetros() async {
    if (_stateId == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_stateId)
          .collection('metros')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      setState(() {
        _metros = snap.docs;
        _metroId = null;
        _metroName = null;

        // reset areas when metros change
        _areas = [];
        _areaId = null;
        _areaName = null;
      });
    } catch (e) {
      debugPrint('Error loading metros: $e');
    }
  }

  Future<void> _loadAreas() async {
    if (_stateId == null || _metroId == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_stateId)
          .collection('metros')
          .doc(_metroId)
          .collection('areas')
          .orderBy('name')
          .get();

      setState(() {
        _areas = snap.docs;
        _areaId = null;
        _areaName = null;
      });
    } catch (e) {
      debugPrint('Error loading areas: $e');
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this club.'),
        ),
      );
      return;
    }

    _form.currentState!.save();

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('clubs').add({
        'name': _name.trim(),
        'category': _category,
        'meetingLocation': _meetingLocation.trim(),
        'meetingSchedule': _meetingSchedule.trim(),
        'contactName': _contactName.trim(),
        'contactEmail': _contactEmail.trim(),
        'contactPhone': _contactPhone.trim(),
        'website': _website.trim(),
        'facebook': _facebook.trim(),
        'featured': _featured,
        'active': true,

        // Location
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',
        'address': _address.trim(),

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club / Group added')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving club: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Club / Group'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Name
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => _name = v ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),

              LocationSelector(
                initialStateId: _stateId, // if you have them
                initialMetroId: _metroId,
                initialAreaId: _areaId,
                onChanged: (loc) {
                  setState(() {
                    _stateId = loc.stateId;
                    _stateName = loc.stateName;
                    _metroId = loc.metroId;
                    _metroName = loc.metroName;
                    _areaId = loc.areaId;
                    _areaName = loc.areaName;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: '123 Main Street',
                ),
                onSaved: (v) => _address = v ?? '',
              ),
              const SizedBox(height: 16),

              // MEETING INFO
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Meeting location',
                ),
                onSaved: (v) => _meetingLocation = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Meeting schedule',
                  helperText: 'e.g. 1st Tuesday at 6:30 PM',
                ),
                onSaved: (v) => _meetingSchedule = v ?? '',
              ),
              const SizedBox(height: 16),

              // CONTACT INFO
              TextFormField(
                decoration: const InputDecoration(labelText: 'Contact name'),
                onSaved: (v) => _contactName = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Contact email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _contactEmail = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Contact phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _contactPhone = v ?? '',
              ),
              const SizedBox(height: 12),

              // LINKS
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.org',
                ),
                onSaved: (v) => _website = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Facebook page',
                  hintText: 'https://facebook.com/...',
                ),
                onSaved: (v) => _facebook = v ?? '',
              ),
              const SizedBox(height: 12),

              // FEATURED
              SwitchListTile(
                title: const Text('Feature this club / group'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
