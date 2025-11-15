import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/clubs_model.dart';
import '../../../widgets/location_selector.dart';

class EditClubPage extends StatefulWidget {
  const EditClubPage({
    super.key,
    required this.club,
  });

  final Club club;

  @override
  State<EditClubPage> createState() => _EditClubPageState();
}

class _EditClubPageState extends State<EditClubPage> {
  final _form = GlobalKey<FormState>();

  late String _name;
  late String _category;
  late String _meetingLocation;
  late String _meetingSchedule;
  late String _contactName;
  late String _contactEmail;
  late String _contactPhone;
  late String _website;
  late String _facebook;
  late bool _featured;
  late bool _active;
  late String _city;

  // location
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  bool _saving = false;

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
    final c = widget.club;
    _name = c.name;
    _category = c.category.isNotEmpty ? c.category : _categories.first;
    _meetingLocation = c.meetingLocation;
    _meetingSchedule = c.meetingSchedule;
    _contactName = c.contactName;
    _contactEmail = c.contactEmail;
    _contactPhone = c.contactPhone ?? '';
    _website = c.website;
    _facebook = c.facebook;
    _featured = c.featured;
    _active = c.active;
    _city = c.city;

    _stateId = c.stateId.isNotEmpty ? c.stateId : null;
    _stateName = c.stateName;
    _metroId = c.metroId.isNotEmpty ? c.metroId : null;
    _metroName = c.metroName;
    _areaId = c.areaId.isNotEmpty ? c.areaId : null;
    _areaName = c.areaName;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    _form.currentState!.save();

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this club.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.club.id)
          .update({
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
        'active': _active,
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',
        'city': _city.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating club: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Club: ${widget.club.name}'),
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
                initialValue: _name,
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

              // Location selector (shared widget)
              LocationSelector(
                initialStateId: _stateId,
                initialMetroId: _metroId,
                initialAreaId: _areaId,
                onChanged: (loc) {
                  _stateId = loc.stateId;
                  _stateName = loc.stateName;
                  _metroId = loc.metroId;
                  _metroName = loc.metroName;
                  _areaId = loc.areaId;
                  _areaName = loc.areaName;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Tallapoosa, Bremen, Buchanan…',
                ),
                onSaved: (v) => _city = v ?? '',
              ),
              const SizedBox(height: 16),

              // Meeting info
              TextFormField(
                initialValue: _meetingLocation,
                decoration: const InputDecoration(
                  labelText: 'Meeting location',
                ),
                onSaved: (v) => _meetingLocation = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _meetingSchedule,
                decoration: const InputDecoration(
                  labelText: 'Meeting schedule',
                  helperText: 'e.g. 1st Tuesday at 6:30 PM',
                ),
                onSaved: (v) => _meetingSchedule = v ?? '',
              ),
              const SizedBox(height: 16),

              // Contact info
              TextFormField(
                initialValue: _contactName,
                decoration: const InputDecoration(labelText: 'Contact name'),
                onSaved: (v) => _contactName = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _contactEmail,
                decoration: const InputDecoration(labelText: 'Contact email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _contactEmail = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _contactPhone,
                decoration: const InputDecoration(labelText: 'Contact phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _contactPhone = v ?? '',
              ),
              const SizedBox(height: 12),

              // Links
              TextFormField(
                initialValue: _website,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.org',
                ),
                onSaved: (v) => _website = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _facebook,
                decoration: const InputDecoration(
                  labelText: 'Facebook page',
                  hintText: 'https://facebook.com/...',
                ),
                onSaved: (v) => _facebook = v ?? '',
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text('Featured'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
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
                label: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
