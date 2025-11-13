import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddLodgingPage extends StatefulWidget {
  const AddLodgingPage({super.key});

  @override
  State<AddLodgingPage> createState() => _AddLodgingPageState();
}

class _AddLodgingPageState extends State<AddLodgingPage> {
  final _form = GlobalKey<FormState>();

  String _name = '';
  String _city = 'Tallapoosa';
  String _lodgingType = 'Hotel / Motel';
  String _address = '';
  String _phone = '';
  String _website = '';

  bool _hasBreakfast = false;
  bool _hasPool = false;
  bool _petFriendly = false;
  bool _featured = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    // NO Scaffold here – AdminShell wraps this and provides AppBar + SafeArea
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Add Lodging',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Name
          TextFormField(
            decoration: const InputDecoration(labelText: 'Name'),
            onSaved: (v) => _name = v?.trim() ?? '',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          // City
          DropdownButtonFormField<String>(
            value: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: const [
              'Tallapoosa',
              'Bremen',
              'Buchanan',
              'Waco',
              'Haralson County (Other)',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _city = v ?? _city),
          ),
          const SizedBox(height: 12),

          // Lodging Type
          DropdownButtonFormField<String>(
            value: _lodgingType,
            decoration: const InputDecoration(labelText: 'Lodging Type'),
            items: const [
              'Hotel / Motel',
              'Cabin',
              'Campground / RV Park',
              'Bed & Breakfast',
              'Vacation Rental',
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _lodgingType = v ?? _lodgingType),
          ),
          const SizedBox(height: 12),

          // Address
          TextFormField(
            decoration: const InputDecoration(labelText: 'Address'),
            onSaved: (v) => _address = v?.trim() ?? '',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          // Phone
          TextFormField(
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
            onSaved: (v) => _phone = v?.trim() ?? '',
          ),
          const SizedBox(height: 12),

          // Website
          TextFormField(
            decoration: const InputDecoration(labelText: 'Website'),
            keyboardType: TextInputType.url,
            onSaved: (v) => _website = v?.trim() ?? '',
          ),
          const SizedBox(height: 16),

          // Feature flags
          SwitchListTile(
            value: _hasBreakfast,
            onChanged: (v) => setState(() => _hasBreakfast = v),
            title: const Text('Includes Breakfast'),
          ),
          SwitchListTile(
            value: _hasPool,
            onChanged: (v) => setState(() => _hasPool = v),
            title: const Text('Has Pool'),
          ),
          SwitchListTile(
            value: _petFriendly,
            onChanged: (v) => setState(() => _petFriendly = v),
            title: const Text('Pet Friendly'),
          ),
          SwitchListTile(
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            title: const Text('Featured'),
          ),
          const SizedBox(height: 12),

          // Save button
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() => _saving = true);
    try {
      final doc = {
        'name': _name.trim(),
        'city': _city,
        'type': _lodgingType,
        'address': _address.trim(),
        'phone': _phone.trim(),
        'website': _website.trim(),
        'hasBreakfast': _hasBreakfast,
        'hasPool': _hasPool,
        'petFriendly': _petFriendly,
        'featured': _featured,
        'search': [
          _name.toLowerCase(),
          _city.toLowerCase(),
          _lodgingType.toLowerCase(),
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('lodging').add(doc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lodging saved to Firestore ✅')),
        );
        Navigator.of(context).pop(); // go back after save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
