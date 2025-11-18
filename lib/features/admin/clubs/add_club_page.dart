// lib/features/admin/clubs/add_club_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../widgets/location_selector.dart';
import '../../../models/category.dart';
import '../../../widgets/image_editor_page.dart';

/// Must match the `section` value in your `sections` / `categories` docs
/// for the Clubs / Groups section.
const String kClubsSectionSlug = 'clubs';

class AddClubPage extends StatefulWidget {
  const AddClubPage({super.key});

  @override
  State<AddClubPage> createState() => _AddClubPageState();
}

class _AddClubPageState extends State<AddClubPage> {
  final _form = GlobalKey<FormState>();

  // Controllers for fields that must round-trip perfectly
  late TextEditingController _nameController;
  late TextEditingController _bannerController;
  late TextEditingController _descriptionController;

  // Club fields
  String _category = ''; // will be set after categories load

  // Images
  List<String> _imageUrls = []; // gallery: multiple URLs

  String _meetingLocation = '';
  String _meetingSchedule = '';
  String _contactName = '';
  String _contactEmail = '';
  String _contactPhone = '';
  String _website = '';
  String _facebook = '';
  bool _featured = false;
  bool _saving = false;

  // Location fields (state / metro / area / city)
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  // Postal address parts
  String _street = '';
  String _city = '';
  String _postalState = '';
  String _zip = '';

  // Loaded location docs (not currently shown in UI, but can be reused if needed)
  List<QueryDocumentSnapshot> _states = [];
  List<QueryDocumentSnapshot> _metros = [];
  List<QueryDocumentSnapshot> _areas = [];

  // Dynamic categories for Clubs section
  List<Category> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bannerController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadStates();
    _loadCategories(); // load club categories from Firestore
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bannerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─────────────────────────────
  // Location loading
  // ─────────────────────────────
  Future<void> _loadStates() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .orderBy('name')
          .get();

      setState(() {
        _states = snap.docs;

        // Optionally auto-select first state and load its metros
        if (_states.isNotEmpty && _stateId == null) {
          final first = _states.first;
          _stateId = first.id;
          final data = first.data() as Map<String, dynamic>;
          _stateName = data['name'] ?? '';
          _loadMetros();
        }
      });
    } catch (e) {
      debugPrint('Error loading states: $e');
    }
  }

  Future<void> _loadMetros() async {
    if (_stateId == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_stateId)
          .collection('metros')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      setState(() {
        _metros = snap.docs;
        _metroId = null;
        _metroName = null;

        // reset areas when metros change
        _areas = [];
        _areaId = null;
        _areaName = null;
      });
    } catch (e) {
      debugPrint('Error loading metros: $e');
    }
  }

  Future<void> _loadAreas() async {
    if (_stateId == null || _metroId == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_stateId)
          .collection('metros')
          .doc(_metroId)
          .collection('areas')
          .orderBy('name')
          .get();

      setState(() {
        _areas = snap.docs;
        _areaId = null;
        _areaName = null;
      });
    } catch (e) {
      debugPrint('Error loading areas: $e');
    }
  }

  // ─────────────────────────────
  // Load categories from Firestore
  // ─────────────────────────────
  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kClubsSectionSlug)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      final cats = snap.docs.map((d) => Category.fromDoc(d)).toList();

      setState(() {
        _categories = cats;
        _loadingCategories = false;
        _categoriesError = null;

        if (_categories.isNotEmpty) {
          final names = _categories.map((c) => c.name).toList();
          // If current _category is not valid, default to first
          if (!names.contains(_category)) {
            _category = names.first;
          }
        }
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
        _categoriesError = 'Error loading categories: $e';
      });
    }
  }

  // ─────────────────────────────
  // Navigation to ImageUrlsEditorPage
  // ─────────────────────────────
  Future<void> _editImages() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ImageUrlsEditorPage(
          initialUrls: _imageUrls,
          title: 'Club Images',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _imageUrls = result;
      });
    }
  }

  // ─────────────────────────────
  // Save
  // ─────────────────────────────
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this club.'),
        ),
      );
      return;
    }

    if (_categories.isNotEmpty && _category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category for this club.'),
        ),
      );
      return;
    }

    _form.currentState!.save(); // still needed for the non-controller fields

    // Always get the latest values from controllers
    final name = _nameController.text.trim();
    final banner = _bannerController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this club.')),
      );
      return;
    }

    // Combined full address
    final fullAddress = [
      _street.trim(),
      _city.trim(),
      _postalState.trim(),
      _zip.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('clubs').add({
        'name': name,
        // Store the selected category name (from Firebase)
        'category': _category,

        // Description
        'description': description,

        // Images: gallery + banner
        'imageUrls': _imageUrls,
        'imageUrl': _imageUrls.isNotEmpty ? _imageUrls.first : '',
        'bannerImageUrl': banner,

        'meetingLocation': _meetingLocation.trim(),
        'meetingSchedule': _meetingSchedule.trim(),
        'contactName': _contactName.trim(),
        'contactEmail': _contactEmail.trim(),
        'contactPhone': _contactPhone.trim(),
        'website': _website.trim(),
        'facebook': _facebook.trim(),
        'featured': _featured,
        'active': true,

        // Location
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',

        // Postal address parts + combined
        'street': _street.trim(),
        'city': _city.trim(),
        'state': _postalState.trim(),
        'zip': _zip.trim(),
        'address': fullAddress,

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

  // ─────────────────────────────
  // UI
  // ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // IMAGES SECTION
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gallery images'),
                subtitle: Text(
                  _imageUrls.isEmpty
                      ? 'No images added yet'
                      : '${_imageUrls.length} image(s) added',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                trailing: OutlinedButton.icon(
                  onPressed: _editImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Manage'),
                ),
              ),
              const SizedBox(height: 4),
              if (_imageUrls.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _imageUrls
                      .take(3)
                      .map(
                        (url) => Chip(
                          label: Text(
                            url,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (_imageUrls.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${_imageUrls.length - 3} more',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Banner image
              TextFormField(
                controller: _bannerController,
                decoration: const InputDecoration(
                  labelText: 'Banner image URL',
                  hintText: 'https://example.com/banner.jpg',
                  helperText: 'Used as the hero / cover image for this club',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // DESCRIPTION
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell visitors what this club is about...',
                ),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 16),

              // Category (dynamic from Firestore)
              if (_loadingCategories) ...[
                const Row(
                  children: [
                    Text('Category'),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else if (_categoriesError != null) ...[
                Text(
                  _categoriesError!,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 16),
              ] else if (_categories.isEmpty) ...[
                Text(
                  'No categories configured for clubs (section "$kClubsSectionSlug").\n'
                  'Go to Admin → Categories and add some.',
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 16),
              ] else ...[
                DropdownButtonFormField<String>(
                  value:
                      _category.isNotEmpty ? _category : _categories.first.name,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.name,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Location selector (using your existing widget)
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

              // Postal address fields
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Street',
                  hintText: '123 Main Street',
                ),
                onSaved: (v) => _street = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Tallapoosa',
                ),
                onSaved: (v) => _city = v ?? '',
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'GA',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSaved: (v) => _postalState = (v ?? '').toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'ZIP',
                        hintText: '30176',
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _zip = v ?? '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // MEETING INFO
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Meeting location',
                ),
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
              const SizedBox(height: 16),

              // CONTACT INFO
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

              // LINKS
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

              // FEATURED
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
