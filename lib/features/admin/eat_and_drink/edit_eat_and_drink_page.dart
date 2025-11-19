import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/eat_and_drink.dart';
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/image_editor_page.dart';
import '../../../widgets/weekly_hours_field.dart'; // 👈 NEW

const String kEatSectionSlug = 'eatAndDrink';

class EditEatAndDrinkPage extends StatefulWidget {
  const EditEatAndDrinkPage({
    super.key,
    required this.place,
  });

  final EatAndDrink place;

  @override
  State<EditEatAndDrinkPage> createState() => _EditEatAndDrinkPageState();
}

class _EditEatAndDrinkPageState extends State<EditEatAndDrinkPage> {
  final _form = GlobalKey<FormState>();

  late String _name;
  late String _city;
  late String _category; // slug or legacy name (we normalize on load)
  late String _description;
  late String _phone;
  late String _website;
  late String _mapQuery;

  late bool _featured;
  late bool _active;

  bool _saving = false;

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
  late TextEditingController _imageUrlController;
  List<String> _imageUrls = [];
  String _bannerImageUrl = '';

  // 🔹 NEW: structured hours
  HoursByDay _hoursByDay = {}; // Map<String, DayHours>

  @override
  void initState() {
    super.initState();
    final p = widget.place;

    _name = p.name;
    _city = p.city;
    _category = p.category; // might be name or slug, we’ll fix after load
    _description = p.description;
    _phone = p.phone ?? '';
    _website = p.website ?? '';
    _mapQuery = p.mapQuery ?? '';

    _featured = p.featured;
    _active = p.active;

    _stateId = p.stateId.isNotEmpty ? p.stateId : null;
    _stateName = p.stateName;
    _metroId = p.metroId.isNotEmpty ? p.metroId : null;
    _metroName = p.metroName;
    _areaId = p.areaId.isNotEmpty ? p.areaId : null;
    _areaName = p.areaName;

    _imageUrlController = TextEditingController(text: p.imageUrl);

    // Hydrate images from model
    _imageUrls = List<String>.from(p.galleryImageUrls);
    _bannerImageUrl = p.bannerImageUrl;

    // Hydrate structured hours (fallback to empty map)
    _hoursByDay = p.hoursByDay ?? {};

    _loadCategories();
  }

  @override
  void dispose() {
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

      // Normalize legacy category values:
      // - If stored value matches a category name, use that slug
      // - Else if it matches a slug, keep it
      // - Else fall back to first slug
      String normalized = _category;
      if (cats.isNotEmpty) {
        final byName = {for (final c in cats) c.name: c.slug};
        final slugSet = {for (final c in cats) c.slug};

        if (byName.containsKey(_category)) {
          normalized = byName[_category]!;
        } else if (!slugSet.contains(_category)) {
          normalized = cats.first.slug;
        }
      } else {
        normalized = '';
      }

      setState(() {
        _categories = cats;
        _category = normalized;
        _loadingCategories = false;
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
          initialUrls: _bannerImageUrl.isEmpty
              ? const <String>[]
              : <String>[_bannerImageUrl],
          title: 'Banner image',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _bannerImageUrl = result.isNotEmpty ? result.first : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.place.name}'),
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
                onSaved: (v) => _name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category
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

              // Location
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
                initialValue: _description,
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
                initialValue: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Website
              TextFormField(
                initialValue: _website,
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
                initialValue: _mapQuery,
                decoration: const InputDecoration(
                  labelText: 'Maps query (optional)',
                  hintText: 'Name + city, or address',
                ),
                onSaved: (v) => _mapQuery = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Toggles
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
      final imageUrl = _imageUrlController.text.trim();

      await FirebaseFirestore.instance
          .collection('eatAndDrink')
          .doc(widget.place.id)
          .update({
        'name': _name.trim(),
        'city': _city.trim(),
        'category': _category, // normalized to slug
        'description': _description.trim(),
        // ❗ We no longer touch the legacy 'hours' string here; it stays as-is.
        'phone': _phone.trim().isEmpty ? null : _phone.trim(),
        'website': _website.trim().isEmpty ? null : _website.trim(),
        'mapQuery': _mapQuery.trim().isEmpty ? null : _mapQuery.trim(),
        'featured': _featured,
        'active': _active,
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',
        'imageUrl': imageUrl,
        'galleryImageUrls': _imageUrls,
        'bannerImageUrl': _bannerImageUrl.isEmpty ? null : _bannerImageUrl,
        // 🔹 Save structured hours
        'hoursByDay': _hoursByDay.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
        'search': [
          _name.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          if (_stateName != null) _stateName!.toLowerCase(),
          if (_metroName != null) _metroName!.toLowerCase(),
          if (_areaName != null && _areaName!.isNotEmpty)
            _areaName!.toLowerCase(),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dining updated ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating dining: $e')),
      );
    }
  }
}
