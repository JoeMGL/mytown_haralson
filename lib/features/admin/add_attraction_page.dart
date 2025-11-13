import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAttractionPage extends StatefulWidget {
  const AddAttractionPage({super.key});
  @override
  State<AddAttractionPage> createState() => _AddAttractionPageState();
}

class _AddAttractionPageState extends State<AddAttractionPage> {
  final _form = GlobalKey<FormState>();

  // Core fields
  String _name = '';
  String _city = 'Tallapoosa';
  String _category = 'Outdoor';
  String _coords = '';
  bool _featured = false;
  bool _saving = false;

  // Fields used by ExploreDetailPage
  String _imageUrl = '';
  String _heroTag = '';
  String _description = '';
  String _hours = '';
  String _tagsText = ''; // comma-separated input, saved as List<String>
  String _mapQuery = '';

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

    setState(() => _saving = true);

    try {
      final geo = _parseLatLng(_coords);

      // convert comma-separated tags to List<String>
      final tags = _tagsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('attractions').add({
        // existing fields
        'name': _name,
        'city': _city,
        'category': _category,
        'coords': geo,
        'featured': _featured,

        // fields used by ExploreDetailPage
        'title': _name, // or store separately if you want
        'imageUrl': _imageUrl,
        'heroTag': _heroTag.isEmpty ? _name : _heroTag,
        'description': _description,
        'hours': _hours.isEmpty ? null : _hours,
        'tags': tags,
        'mapQuery': _mapQuery.isEmpty ? null : _mapQuery,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attraction: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Attraction')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name / Title
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name / Title'),
              onSaved: (v) => _name = v?.trim() ?? '',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Image URL
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Image URL (Unsplash or other)'),
              onSaved: (v) => _imageUrl = v?.trim() ?? '',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Hero Tag
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Hero Tag (optional)',
                helperText:
                    'Used for Hero animation; defaults to Name if empty',
              ),
              onSaved: (v) => _heroTag = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              onSaved: (v) => _description = v?.trim() ?? '',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Hours
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Hours (optional)',
                hintText: 'e.g. Mon–Sat 10am–6pm',
              ),
              onSaved: (v) => _hours = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),

            // Tags
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g. Family-friendly, Outdoors, Free',
              ),
              onSaved: (v) => _tagsText = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),

            // Map query
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Map Query (optional)',
                helperText:
                    'If empty, Google Maps search will use the title instead',
              ),
              onSaved: (v) => _mapQuery = v?.trim() ?? '',
            ),
            const SizedBox(height: 20),

            // Existing fields: City, Category, Coords, Featured
            DropdownButtonFormField<String>(
              value: _city,
              decoration: const InputDecoration(labelText: 'City'),
              items: const ['Tallapoosa', 'Bremen', 'Buchanan', 'Waco']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _city = v ?? _city),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                'Outdoor',
                'History',
                'Shopping',
                'Dining',
                'Lodging'
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),

            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Coords (lat,lng)',
                hintText: 'e.g. 33.744,-85.287',
              ),
              onSaved: (v) => _coords = v?.trim() ?? '',
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Featured'),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Attraction'),
            ),
          ],
        ),
      ),
    );
  }
}
