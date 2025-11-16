import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddShopsPage extends StatefulWidget {
  const AddShopsPage({super.key});
  @override
  State<AddShopsPage> createState() => _AddShopsPageState();
}

class _AddShopsPageState extends State<AddShopsPage> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  String _city = 'Tallapoosa';
  String _category = 'Boutique';
  String _coords = '';
  bool _featured = false;
  bool _saving = false;

  GeoPoint? _parseLatLng(String input) {
    final t = input.trim();
    if (t.isEmpty) return null;
    final parts = t.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return GeoPoint(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    // NO Scaffold here – AdminShell wraps this and provides AppBar + SafeArea
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Add Shop',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Name'),
            onSaved: (v) => _name = v ?? '',
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: const ['Tallapoosa', 'Bremen', 'Buchanan', 'Waco']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _city = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              'Boutique',
              'Antiques',
              'Gifts & Specialty',
              'Groceries',
              'Services',
              'Other',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration:
                const InputDecoration(labelText: 'Coordinates (lat,lng)'),
            onSaved: (v) => _coords = v ?? '',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // optional
              final ok = _parseLatLng(v) != null;
              return ok ? null : 'Use "lat,lng" (e.g. 33.744,-85.289)';
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            title: const Text('Featured'),
          ),
          const SizedBox(height: 12),
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

    final geo = _parseLatLng(_coords);

    setState(() => _saving = true);
    try {
      final doc = {
        'name': _name.trim(),
        'city': _city,
        'category': _category,
        'featured': _featured,
        if (geo != null) 'location': geo,
        'coords_raw': _coords.trim(),
        'search': [
          _name.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('shops').add(doc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop saved to Firestore ✅')),
        );
        Navigator.of(context).pop(); // go back after save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
