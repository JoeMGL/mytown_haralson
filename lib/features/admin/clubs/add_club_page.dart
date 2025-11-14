// lib/features/admin/clubs/add_club_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddClubPage extends StatefulWidget {
  const AddClubPage({super.key});

  @override
  State<AddClubPage> createState() => _AddClubPageState();
}

class _AddClubPageState extends State<AddClubPage> {
  final _form = GlobalKey<FormState>();

  String _name = '';
  String _city = 'Tallapoosa';
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

  static const _cities = ['Tallapoosa', 'Bremen', 'Buchanan', 'Waco'];

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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('clubs').add({
        'name': _name.trim(),
        'city': _city,
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => _name = v ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // City dropdown
              DropdownButtonFormField<String>(
                value: _city,
                decoration: const InputDecoration(labelText: 'City'),
                items: _cities
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _city = v ?? _city),
              ),
              const SizedBox(height: 12),

              // Category dropdown
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
              const SizedBox(height: 12),

              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Meeting location'),
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
              const SizedBox(height: 12),

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
