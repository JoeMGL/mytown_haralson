import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/weekly_hours_field.dart';

// 🔑 Must match categories.section for the Explore/Attractions section
// e.g. if docs have { section: "Explore" } keep this as 'Explore'
const String kExploreSectionSlug = 'Explore';

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

  // Controllers for fields that were not saving correctly
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;

  // Core flags
  late String _coords;
  late bool _featured;
  late bool _active;

  // Categories (multi-select)
  List<Category> _categories = [];
  Set<String> _selectedCategorySlugs = {};
  bool _loadingCategories = true;
  String? _categoriesError;

  // Address
  late String _street;
  late String _city;
  late String _state;
  late String _zip;

  // Detail fields
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

  @override
  void initState() {
    super.initState();
    final p = widget.place;

    // Controllers for fields that must round-trip perfectly
    _nameController = TextEditingController(text: p.title);
    _imageUrlController = TextEditingController(text: p.imageUrl);

    // Address
    _street = p.street;
    _city = p.city;
    _state = p.state;
    _zip = p.zip;

    // Categories: use existing multi-cats if present, otherwise fallback to primary
    if (p.categories.isNotEmpty) {
      _selectedCategorySlugs = p.categories.toSet();
    } else if (p.category.isNotEmpty) {
      _selectedCategorySlugs = {p.category};
    } else {
      _selectedCategorySlugs = {};
    }

    // Detail fields
    _heroTag = p.heroTag;
    _description = p.description;
    _hours = p.hours ?? '';
    _tagsText = p.tags.join(', ');
    _mapQuery = p.mapQuery ?? '';

    // Coords
    _coords =
        p.coords != null ? '${p.coords!.latitude},${p.coords!.longitude}' : '';

    // Flags
    _featured = p.featured;
    _active = p.active;

    // Location
    _stateId = p.stateId.isNotEmpty ? p.stateId : null;
    _stateName = p.stateName;
    _metroId = p.metroId.isNotEmpty ? p.metroId : null;
    _metroName = p.metroName;
    _areaId = p.areaId.isNotEmpty ? p.areaId : null;
    _areaName = p.areaName;

    // Structured hours – copy existing; WeeklyHoursField will normalize days
    _hoursByDay = Map<String, DayHours>.from(p.hoursByDay);

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kExploreSectionSlug)
          .orderBy('sortOrder')
          .get();

      final cats = snap.docs.map((d) => Category.fromDoc(d)).toList();

      if (!mounted) return;

      setState(() {
        _categories = cats;
        _categoriesError = null;
        _loadingCategories = false;

        // If nothing is selected but we have categories, pick the first one
        if (_categories.isNotEmpty && _selectedCategorySlugs.isEmpty) {
          _selectedCategorySlugs = {_categories.first.slug};
        }
      });

      // Optional debug
      // ignore: avoid_print
      print(
          'EditAttractionPage loaded ${cats.length} categories for section $kExploreSectionSlug');
      for (final c in cats) {
        // ignore: avoid_print
        print('Category: ${c.name} | slug: ${c.slug} | section: ${c.section}');
      }
    } catch (e, st) {
      debugPrint('Error loading categories in EditAttractionPage: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = e.toString();
        _categories = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Widget _buildCategoryField(BuildContext context) {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoriesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error loading categories:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 4),
          Text(
            _categoriesError!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    if (_categories.isEmpty) {
      return Text(
        'No categories configured for section "$kExploreSectionSlug".\n'
        'Add some in the Admin → Categories page with section "$kExploreSectionSlug".',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Categories'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _categories.map((cat) {
            final selected = _selectedCategorySlugs.contains(cat.slug);
            return FilterChip(
              label: Text(cat.name),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedCategorySlugs.add(cat.slug);
                  } else {
                    _selectedCategorySlugs.remove(cat.slug);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
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
    _form.currentState!.save(); // still needed for fields using onSaved

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this attraction.'),
        ),
      );
      return;
    }

    if (_selectedCategorySlugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category.'),
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

      // Read from controllers so we always get the latest edits
      final title = _nameController.text.trim();
      final imageUrl = _imageUrlController.text.trim();

      final street = _street.trim();
      final city = _city.trim();
      final state = _state.trim();
      final zip = _zip.trim();

      // Make category list deterministic
      final categorySlugs = _selectedCategorySlugs.toList()..sort();
      final primaryCategory = categorySlugs.first;

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

        // Category stored as primary + all
        'category': primaryCategory,
        'categories': categorySlugs,

        'imageUrl': imageUrl,
        'heroTag': _heroTag.trim().isEmpty ? title : _heroTag.trim(),
        'description': _description.trim(),

        // Legacy hours + structured hours
        'hours': _hours.trim().isEmpty ? null : _hours.trim(),
        'hoursByDay':
            _hoursByDay.map((key, value) => MapEntry(key, value.toMap())),

        'tags': tags,
        'mapQuery': _mapQuery.trim().isNotEmpty ? _mapQuery.trim() : null,
        'coords': geo,
        'featured': _featured,
        'active': _active,

        // Location
        'stateId': _stateId ?? '',
        'stateName': _stateName ?? '',
        'metroId': _metroId ?? '',
        'metroName': _metroName ?? '',
        'areaId': _areaId ?? '',
        'areaName': _areaName ?? '',

        // Search keywords
        'search': [
          title.toLowerCase(),
          city.toLowerCase(),
          primaryCategory.toLowerCase(),
          ...categorySlugs.map((c) => c.toLowerCase()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating attraction: $e')),
      );
      setState(() => _saving = false);
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name / Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                    labelText: 'Image URL (Unsplash or other)'),
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

              // Legacy hours (optional, string)
              TextFormField(
                initialValue: _hours,
                decoration: const InputDecoration(
                  labelText: 'Hours (text, optional)',
                  hintText: 'e.g. Mon–Sat 10–6',
                ),
                onSaved: (v) => _hours = v?.trim() ?? '',
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

              // Categories (multi-select)
              _buildCategoryField(context),
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
