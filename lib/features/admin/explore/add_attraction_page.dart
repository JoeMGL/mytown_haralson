import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../widgets/location_selector.dart';
import '../../../widgets/weekly_hours_field.dart';
import '../../../models/place.dart';
import '../../../models/category.dart';

// 🔑 Must match the value stored in categories.section for the Explore/Attractions section
// e.g. if your docs have { section: "Explore" } then keep this as "Explore"
// If they have { section: "explore" } then change this to 'explore'.
const String kExploreSectionSlug = 'Explore';

class AddAttractionPage extends StatefulWidget {
  const AddAttractionPage({super.key});

  @override
  State<AddAttractionPage> createState() => _AddAttractionPageState();
}

class _AddAttractionPageState extends State<AddAttractionPage> {
  final _form = GlobalKey<FormState>();

  // Controllers for fields that must round-trip perfectly
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;

  // Core fields
  String _coords = '';
  bool _featured = false;
  bool _saving = false;

  // Address fields
  String _street = '';
  String _city = '';
  String _state = '';
  String _zip = '';

  // Detail fields
  String _heroTag = '';
  String _description = '';
  String _tagsText = '';
  String _mapQuery = '';

  // Structured hours by day
  Map<String, DayHours> _hoursByDay = {};

  // Categories
  List<Category> _categories = [];
  Set<String> _selectedCategorySlugs = {};
  bool _loadingCategories = true;
  String? _categoriesError;

  // Location
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _imageUrlController = TextEditingController();
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

        // Default select first category if none chosen yet
        if (_categories.isNotEmpty && _selectedCategorySlugs.isEmpty) {
          _selectedCategorySlugs = {_categories.first.slug};
        }
      });

      // Optional: debug to verify you're pulling the right docs
      // ignore: avoid_print
      print(
        'Loaded ${cats.length} categories for section $kExploreSectionSlug',
      );
      for (final c in cats) {
        // ignore: avoid_print
        print('Category: ${c.name} | slug: ${c.slug} | section: ${c.section}');
      }
    } catch (e, st) {
      debugPrint('Error loading categories in AddAttractionPage: $e\n$st');
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

  Widget _buildCategoryMultiSelect(BuildContext context) {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categoriesError != null) {
      return Text(
        'Error loading categories: $_categoriesError',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    if (_categories.isEmpty) {
      return Text(
        'No categories configured for section "$kExploreSectionSlug".\n'
        'Add some in Admin → Categories with section "$kExploreSectionSlug".',
        style: Theme.of(context).textTheme.bodyMedium,
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

      final categorySlugs = _selectedCategorySlugs.toList()..sort();
      final primaryCategory = categorySlugs.first;

      await FirebaseFirestore.instance.collection('attractions').add({
        // Core identity
        'name': title,
        'title': title,

        // Address
        'street': street,
        'city': city,
        'state': state,
        'zip': zip,

        // Categories (store slugs)
        'category': primaryCategory,
        'categories': categorySlugs,

        // Media / description
        'imageUrl': imageUrl,
        'heroTag': _heroTag.trim().isEmpty ? title : _heroTag.trim(),
        'description': _description.trim(),

        // Hours
        'hours': null, // optional legacy field, keep null for now
        'hoursByDay':
            _hoursByDay.map((key, value) => MapEntry(key, value.toMap())),

        // Tags / map
        'tags': tags,
        'mapQuery': _mapQuery.trim().isEmpty ? null : _mapQuery.trim(),

        // Location / geo
        'coords': geo,
        'featured': _featured,
        'active': true,

        'stateId': _stateId ?? '',
        'stateName': _stateName ?? '',
        'metroId': _metroId ?? '',
        'metroName': _metroName ?? '',
        'areaId': _areaId ?? '',
        'areaName': _areaName ?? '',

        // Search helpers
        'search': [
          title.toLowerCase(),
          city.toLowerCase(),
          primaryCategory.toLowerCase(),
          ...categorySlugs.map((c) => c.toLowerCase()),
          if (street.isNotEmpty) street.toLowerCase(),
          if (state.isNotEmpty) state.toLowerCase(),
          if (zip.isNotEmpty) zip.toLowerCase(),
        ],

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
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

            // Structured weekly hours
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

            // Address section
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Street
            TextFormField(
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
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'e.g. Tallapoosa',
              ),
              onSaved: (v) => _city = v?.trim() ?? '',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // State + Zip side by side
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
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

            // Category multi-select
            _buildCategoryMultiSelect(context),
            const SizedBox(height: 12),

            // Location selector (state/metro/area)
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
              decoration: const InputDecoration(
                labelText: 'Coords (lat,lng)',
                hintText: 'e.g. 33.744,-85.287',
              ),
              onSaved: (v) => _coords = v?.trim() ?? '',
            ),
            const SizedBox(height: 8),

            // Featured flag
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
