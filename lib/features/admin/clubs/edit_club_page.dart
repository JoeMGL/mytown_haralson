import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/clubs_model.dart';
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/image_editor_page.dart';

/// Must match the `section` value in your `categories` docs for clubs/groups.
const String kClubsSectionSlug = 'clubs';

class EditClubPage extends StatefulWidget {
  const EditClubPage({
    super.key,
    required this.club,
  });

  final Club club;

  @override
  State<EditClubPage> createState() => _EditClubPageState();
}

class _EditClubPageState extends State<EditClubPage> {
  final _form = GlobalKey<FormState>();

  // Controllers so fields round-trip correctly
  late TextEditingController _nameController;
  late TextEditingController
      _descriptionController; // NEW: description controller

  late String _category;
  late String _meetingLocation;
  late String _meetingSchedule;
  late String _contactName;
  late String _contactEmail;
  late String _contactPhone;
  late String _website;
  late String _facebook;
  late bool _featured;
  late bool _active;

  // Images
  late List<String> _imageUrls;
  late String _bannerImageUrl;

  // Location
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  // Postal address
  late String _street;
  late String _city;
  late String _postalState;
  late String _zip;

  bool _saving = false;

  // Dynamic categories from Firestore
  List<Category> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();

    final c = widget.club;

    _nameController = TextEditingController(text: c.name);
    _descriptionController = TextEditingController(text: c.description); // NEW

    _category = c.category; // we'll validate against fetched categories
    _meetingLocation = c.meetingLocation;
    _meetingSchedule = c.meetingSchedule;
    _contactName = c.contactName;
    _contactEmail = c.contactEmail;
    _contactPhone = c.contactPhone;
    _website = c.website;
    _facebook = c.facebook;
    _featured = c.featured;
    _active = c.active;

    // Images
    _imageUrls = List<String>.from(c.imageUrls);
    _bannerImageUrl = c.bannerImageUrl;

    // Location (logical)
    _stateId = c.stateId.isNotEmpty ? c.stateId : null;
    _stateName = c.stateName;
    _metroId = c.metroId.isNotEmpty ? c.metroId : null;
    _metroName = c.metroName;
    _areaId = c.areaId.isNotEmpty ? c.areaId : null;
    _areaName = c.areaName;

    // Postal address
    _street = c.street;
    _city = c.city;
    _postalState = c.state;
    _zip = c.zip;

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─────────────────────────────
  // Load categories for Clubs section
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

          // If existing category is empty or not in the list, default to first.
          if (_category.isEmpty || !names.contains(_category)) {
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
  // Image editor navigation
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    _form.currentState!.save();

    // Always read latest name & description from controllers
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this club.')),
      );
      return;
    }

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this club.'),
        ),
      );
      return;
    }

    if (_categories.isNotEmpty && _category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a category for this club.'),
      ));
      return;
    }

    setState(() => _saving = true);

    // Combined full address
    final fullAddress = [
      _street.trim(),
      _city.trim(),
      _postalState.trim(),
      _zip.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    try {
      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.club.id)
          .update({
        'name': name,
        'category': _category,

        // ✅ Guaranteed description update
        'description': description,

        // Images
        'imageUrls': _imageUrls,
        'imageUrl': _imageUrls.isNotEmpty ? _imageUrls.first : '',
        'bannerImageUrl': _bannerImageUrl.trim(),

        'meetingLocation': _meetingLocation.trim(),
        'meetingSchedule': _meetingSchedule.trim(),
        'contactName': _contactName.trim(),
        'contactEmail': _contactEmail.trim(),
        'contactPhone': _contactPhone.trim(),
        'website': _website.trim(),
        'facebook': _facebook.trim(),
        'featured': _featured,
        'active': _active,

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

        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating club: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Club: ${widget.club.name}'),
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

              // Gallery
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
                initialValue: _bannerImageUrl,
                decoration: const InputDecoration(
                  labelText: 'Banner image URL',
                  hintText: 'https://example.com/banner.jpg',
                  helperText: 'Used as the hero / cover image for this club',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _bannerImageUrl = v ?? '',
              ),
              const SizedBox(height: 16),

              // Description (uses controller)
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

              // Category (dynamic)
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

              // Postal address fields
              TextFormField(
                initialValue: _street,
                decoration: const InputDecoration(
                  labelText: 'Street',
                  hintText: '123 Main Street',
                ),
                onSaved: (v) => _street = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _city,
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
                      initialValue: _postalState,
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
                      initialValue: _zip,
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

              // Meeting info
              TextFormField(
                initialValue: _meetingLocation,
                decoration: const InputDecoration(
                  labelText: 'Meeting location',
                ),
                onSaved: (v) => _meetingLocation = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _meetingSchedule,
                decoration: const InputDecoration(
                  labelText: 'Meeting schedule',
                  helperText: 'e.g. 1st Tuesday at 6:30 PM',
                ),
                onSaved: (v) => _meetingSchedule = v ?? '',
              ),
              const SizedBox(height: 16),

              // Contact info
              TextFormField(
                initialValue: _contactName,
                decoration: const InputDecoration(labelText: 'Contact name'),
                onSaved: (v) => _contactName = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _contactEmail,
                decoration: const InputDecoration(labelText: 'Contact email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _contactEmail = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _contactPhone,
                decoration: const InputDecoration(labelText: 'Contact phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _contactPhone = v ?? '',
              ),
              const SizedBox(height: 12),

              // Links
              TextFormField(
                initialValue: _website,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.org',
                ),
                onSaved: (v) => _website = v ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _facebook,
                decoration: const InputDecoration(
                  labelText: 'Facebook page',
                  hintText: 'https://facebook.com/...',
                ),
                onSaved: (v) => _facebook = v ?? '',
              ),
              const SizedBox(height: 12),

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
