import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEatAndDrinkPage extends StatefulWidget {
  const AddEatAndDrinkPage({super.key});

  @override
  State<AddEatAndDrinkPage> createState() => _AddEatAndDrinkPageState();
}

class _AddEatAndDrinkPageState extends State<AddEatAndDrinkPage> {
  final _form = GlobalKey<FormState>();

  String _name = '';
  String _city = 'Tallapoosa';
  String _category = 'Restaurant';
  String _description = '';
  String _imageUrl = '';
  String _hours = '';
  String _coords = '';
  String _tagsRaw = '';
  String _phone = '';
  String _website = '';
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() {
      _saving = true;
    });

    final coords = _parseLatLng(_coords);
    final tags = _tagsRaw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    try {
      await FirebaseFirestore.instance.collection('eat_and_drink').add({
        'name': _name,
        'city': _city,
        'category': _category,
        'description': _description,
        'imageUrl': _imageUrl,
        'hours': _hours.isEmpty ? null : _hours,
        'coords': coords,
        'tags': tags,
        'phone': _phone.isEmpty ? null : _phone,
        'website': _website.isEmpty ? null : _website,
        'mapQuery': _name,
        'featured': _featured,
        'createdAt': FieldValue.serverTimestamp(), // 👈 ADD THIS
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Eat & Drink')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => _name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _city,
                decoration: const InputDecoration(labelText: 'City'),
                items: const [
                  'Tallapoosa',
                  'Bremen',
                  'Buchanan',
                  'Waco',
                  'County-wide',
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v ?? 'Tallapoosa'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  'Restaurant',
                  'Coffee',
                  'Bar & Grill',
                  'Bakery',
                  'Sweets & Ice Cream',
                  'Fast Food',
                  'Food Truck',
                  'Brewery / Winery',
                  'Other',
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Restaurant'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  helperText: 'Public image URL for the listing',
                ),
                onSaved: (v) => _imageUrl = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                onSaved: (v) => _description = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  helperText: 'Example: Mon–Thu 11–9, Fri–Sat 11–10',
                ),
                onSaved: (v) => _hours = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  helperText: 'Digits only, or include dashes',
                ),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website',
                  helperText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _website = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Coordinates',
                  helperText: 'lat,lng (optional, for maps)',
                ),
                onSaved: (v) => _coords = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Comma-separated, e.g. Mexican, Family, Patio',
                ),
                onSaved: (v) => _tagsRaw = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _featured,
                title: const Text('Featured'),
                subtitle: const Text('Show in featured carousels / highlights'),
                activeColor: cs.primary,
                onChanged: (v) => setState(() => _featured = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
