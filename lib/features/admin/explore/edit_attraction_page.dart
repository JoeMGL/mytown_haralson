import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/weekly_hours_field.dart';

class EditAttractionPage extends StatefulWidget {
  const EditAttractionPage({
    super.key,
    required this.place,
  });

  final Place place;

  @override
  State<EditAttractionPage> createState() => _EditAttractionPageState();
}

class _EditAttractionPageState extends State<EditAttractionPage> {
  final _form = GlobalKey<FormState>();

  // Core fields
  late String _name;
  late String _category;
  late String _coords;
  late bool _featured;
  late bool _active;

  // Address
  late String _street;
  late String _city;
  late String _state;
  late String _zip;

  // Detail fields
  late String _imageUrl;
  late String _heroTag;
  late String _description;
  late String _hours; // legacy free-text
  late String _tagsText;
  late String _mapQuery;

  // Structured hours
  Map<String, DayHours> _hoursByDay = {};

  // Location
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  bool _saving = false;

  static const _categories = [
    'Outdoor',
    'History',
    'Shopping',
    'Dining',
    'Lodging',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.place;

    _name = p.title;

    // Address
    _street = p.street;
    _city = p.city;
    _state = p.state;
    _zip = p.zip;

    _category =
        _categories.contains(p.category) ? p.category : _categories.first;

    _imageUrl = p.imageUrl;
    _heroTag = p.heroTag;
    _description = p.description;
    _hours = p.hours ?? '';
    _tagsText = p.tags.join(', ');
    _mapQuery = p.mapQuery ?? '';

    _coords =
        p.coords != null ? '${p.coords!.latitude},${p.coords!.longitude}' : '';

    _featured = p.featured;
    _active = p.active;

    _stateId = p.stateId.isNotEmpty ? p.stateId : null;
    _stateName = p.stateName;
    _metroId = p.metroId.isNotEmpty ? p.metroId : null;
    _metroName = p.metroName;
    _areaId = p.areaId.isNotEmpty ? p.areaId : null;
    _areaName = p.areaName;

    // Structured hours – copy existing; WeeklyHoursField will normalize days
    _hoursByDay = Map<String, DayHours>.from(p.hoursByDay);
  }

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

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this attraction.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final geo = _parseLatLng(_coords);

      final tags = _tagsText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final title = _name.trim();
      final street = _street.trim();
      final city = _city.trim();
      final state = _state.trim();
      final zip = _zip.trim();

      await FirebaseFirestore.instance
          .collection('attractions')
          .doc(widget.place.id)
          .update({
        'name': title,
        'title': title,

        // Address
        'street': street,
        'city': city,
        'state': state,
        'zip': zip,

        'category': _category,
        'imageUrl': _imageUrl.trim(),
        'heroTag': _heroTag.trim().isEmpty ? title : _heroTag.trim(),
        'description': _description.trim(),
        'hours': _hours.trim().isEmpty ? null : _hours.trim(),
        'hoursByDay':
            _hoursByDay.map((key, value) => MapEntry(key, value.toMap())),
        'tags': tags,
        'mapQuery': _mapQuery.trim().isEmpty ? null : _mapQuery.trim(),
        'coords': geo,
        'featured': _featured,
        'active': _active,
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',
        'search': [
          title.toLowerCase(),
          city.toLowerCase(),
          _category.toLowerCase(),
          if (street.isNotEmpty) street.toLowerCase(),
          if (state.isNotEmpty) state.toLowerCase(),
          if (zip.isNotEmpty) zip.toLowerCase(),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attraction updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating attraction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Attraction: ${widget.place.title}'),
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
                decoration: const InputDecoration(labelText: 'Name / Title'),
                onSaved: (v) => _name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Image URL
              TextFormField(
                initialValue: _imageUrl,
                decoration: const InputDecoration(
                    labelText: 'Image URL (Unsplash or other)'),
                onSaved: (v) => _imageUrl = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Hero tag
              TextFormField(
                initialValue: _heroTag,
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
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                onSaved: (v) => _description = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Structured hours
              WeeklyHoursField(
                label: 'Hours by Day',
                initialValue: _hoursByDay,
                onChanged: (value) {
                  setState(() {
                    _hoursByDay = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Tags
              TextFormField(
                initialValue: _tagsText,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  hintText: 'e.g. Family-friendly, Outdoors, Free',
                ),
                onSaved: (v) => _tagsText = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Map query
              TextFormField(
                initialValue: _mapQuery,
                decoration: const InputDecoration(
                  labelText: 'Map Query (optional)',
                  helperText:
                      'If empty, Google Maps search will use the title instead',
                ),
                onSaved: (v) => _mapQuery = v?.trim() ?? '',
              ),
              const SizedBox(height: 20),

              // Address section
              Text(
                'Address',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              // Street
              TextFormField(
                initialValue: _street,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. 123 Main St',
                ),
                onSaved: (v) => _street = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // City
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. Tallapoosa',
                ),
                onSaved: (v) => _city = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // State + Zip
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _state,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'e.g. GA',
                      ),
                      onSaved: (v) => _state = v?.trim() ?? '',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: _zip,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                        hintText: 'e.g. 30176',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _zip = v?.trim() ?? '',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),

              // LOCATION (state/metro/area)
              LocationSelector(
                initialStateId: _stateId,
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

              // Coords
              TextFormField(
                initialValue: _coords,
                decoration: const InputDecoration(
                  labelText: 'Coords (lat,lng)',
                  hintText: 'e.g. 33.744,-85.287',
                ),
                onSaved: (v) => _coords = v?.trim() ?? '',
              ),
              const SizedBox(height: 8),

              // Flags
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
