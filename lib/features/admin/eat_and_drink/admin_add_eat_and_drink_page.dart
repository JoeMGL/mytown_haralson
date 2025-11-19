import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/eat_and_drink.dart';
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/image_editor_page.dart';
import '../../../widgets/weekly_hours_field.dart'; // 👈 NEW: hours widget

/// Must match the `section` value in your `categories` docs
/// for the Eat & Drink section.
const String kEatSectionSlug = 'eatAndDrink';

class AddEatAndDrinkPage extends StatefulWidget {
  const AddEatAndDrinkPage({super.key});

  @override
  State<AddEatAndDrinkPage> createState() => _AddEatAndDrinkPageState();
}

class _AddEatAndDrinkPageState extends State<AddEatAndDrinkPage> {
  final _form = GlobalKey<FormState>();

  // Controllers for fields that must round-trip perfectly
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;

  // Core fields
  String _city = 'Tallapoosa';
  String _category = ''; // category slug from Firestore
  String _description = '';
  String _phone = '';
  String _website = '';
  String _mapQuery = '';

  bool _featured = false;
  bool _saving = false;

  // 🔹 NEW: structured hours
  HoursByDay _hoursByDay = {}; // Map<String, DayHours>

  // Location
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  // Dynamic categories
  List<Category> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;

  // Images
  List<String> _imageUrls = []; // gallery
  String _bannerImageUrl = ''; // hero / banner

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
          .where('section', isEqualTo: kEatSectionSlug)
          .orderBy('sortOrder')
          .get();

      final cats = snap.docs.map((d) => Category.fromDoc(d)).toList();

      setState(() {
        _categories = cats;
        _loadingCategories = false;

        if (_categories.isNotEmpty) {
          _category = _categories.first.slug;
        }
      });
    } catch (e) {
      setState(() {
        _categoriesError = 'Error loading categories: $e';
        _loadingCategories = false;
      });
    }
  }

  Future<void> _editGalleryImages() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ImageUrlsEditorPage(
          initialUrls: _imageUrls,
          title: 'Gallery images',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _imageUrls = result;
        if (_imageUrls.isNotEmpty && _imageUrlController.text.isEmpty) {
          _imageUrlController.text = _imageUrls.first;
        }
      });
    }
  }

  Future<void> _editBannerImage() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ImageUrlsEditorPage(
          initialUrls:
              _bannerImageUrl.isEmpty ? <String>[] : <String>[_bannerImageUrl],
          title: 'Banner image',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _bannerImageUrl =
            result.isNotEmpty ? result.first : ''; // clear if empty list
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Eat & Drink'),
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
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category (dynamic from Firestore)
              if (_loadingCategories)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_categoriesError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _categoriesError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _category.isEmpty ? null : _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.slug,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _category = v);
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please select a category'
                      : null,
                ),
              const SizedBox(height: 12),

              // City
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Location selector
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
              const SizedBox(height: 16),

              // Gallery images
              ListTile(
                title: const Text('Gallery images'),
                subtitle: Text(
                  _imageUrls.isEmpty
                      ? 'Tap to add images'
                      : '${_imageUrls.length} image(s) selected',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editGalleryImages,
              ),
              const SizedBox(height: 8),

              // Banner image
              ListTile(
                title: const Text('Banner / hero image'),
                subtitle: Text(
                  _bannerImageUrl.isEmpty
                      ? 'Tap to choose banner image'
                      : 'Banner image selected',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _editBannerImage,
              ),
              const SizedBox(height: 12),

              // Main image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Main image URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Description (short)'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // 🔹 NEW: Weekly hours picker
              WeeklyHoursField(
                initialValue: _hoursByDay,
                onChanged: (value) {
                  setState(() {
                    _hoursByDay = value;
                  });
                },
                label: 'Hours',
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
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _website = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Map query
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Maps query (optional)',
                  hintText: 'Name + city, or address',
                ),
                onSaved: (v) => _mapQuery = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Featured toggle
              SwitchListTile(
                title: const Text('Featured'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
              const SizedBox(height: 24),

              // Save button
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select a state and metro for this dining place.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final imageUrl = _imageUrlController.text.trim();

      final place = EatAndDrink(
        id: '',
        name: name,
        city: _city.trim(),
        category: _category,
        description: _description.trim(),
        imageUrl: imageUrl,
        heroTag: '',
        // 🔹 Legacy hours string – now unused, keep null for compatibility
        hours: null,
        tags: const [],
        coords: null,
        phone: _phone.trim().isEmpty ? null : _phone.trim(),
        website: _website.trim().isEmpty ? null : _website.trim(),
        mapQuery: _mapQuery.trim().isEmpty ? null : _mapQuery.trim(),
        featured: _featured,
        active: true,
        search: [
          name.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          if (_stateName != null) _stateName!.toLowerCase(),
          if (_metroName != null) _metroName!.toLowerCase(),
          if (_areaName != null && _areaName!.isNotEmpty)
            _areaName!.toLowerCase(),
        ],
        stateId: _stateId ?? '',
        stateName: _stateName ?? '',
        metroId: _metroId ?? '',
        metroName: _metroName ?? '',
        areaId: _areaId ?? '',
        areaName: _areaName ?? '',

        // ✅ NEW required fields
        galleryImageUrls: _imageUrls,
        bannerImageUrl: _bannerImageUrl,
      );

      await FirebaseFirestore.instance.collection('eatAndDrink').add({
        ...place.toMap(),
        'galleryImageUrls': _imageUrls,
        'bannerImageUrl': _bannerImageUrl.isEmpty ? null : _bannerImageUrl,
        // 🔹 Save structured hours to Firestore
        'hoursByDay': _hoursByDay.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dining place added ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving dining: $e')),
      );
    }
  }
}
