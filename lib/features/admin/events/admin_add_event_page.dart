// lib/features/admin/events/admin_add_event_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/image_editor_page.dart';

/// Must match the `section` value in your `categories` docs for events.
const String kEventsSectionSlug = 'events';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _form = GlobalKey<FormState>();

  // Controllers for fields that must round-trip perfectly
  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;

  // Core fields
  String _category = ''; // category slug from Firestore
  String _venue = '';
  String _address = ''; // street
  String _city = 'Tallapoosa';
  String _state = 'GA';
  String _zip = '';

  String _externalLink = '';
  String _description = '';

  bool _featured = false;
  bool _allDay = false;
  bool _free = true;
  double? _price;

  DateTime _start = DateTime.now().add(const Duration(hours: 2));
  DateTime _end = DateTime.now().add(const Duration(hours: 3));

  bool _saving = false;

  // Location fields (state / metro / area)
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
    _titleController = TextEditingController();
    _imageUrlController = TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kEventsSectionSlug)
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
    final ml = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
        automaticallyImplyLeading: false,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // TITLE
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // CATEGORY (dynamic, slug)
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

              // ADDRESS FIELDS
              TextFormField(
                decoration: const InputDecoration(labelText: 'Street address'),
                onSaved: (v) => _address = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _state,
                decoration: const InputDecoration(labelText: 'State'),
                onSaved: (v) => _state = v?.trim() ?? '',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _zip,
                decoration: const InputDecoration(labelText: 'ZIP Code'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _zip = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // LOCATION SELECTOR (state/metro/area)
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

              // VENUE
              TextFormField(
                decoration: const InputDecoration(labelText: 'Venue'),
                onSaved: (v) => _venue = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // IMAGES (gallery + banner + main url)
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

              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Main image URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),

              // DESCRIPTION
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Short description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // WEBSITE
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'External link (optional)',
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _externalLink = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // TIME
              SwitchListTile(
                value: _allDay,
                onChanged: (v) {
                  setState(() {
                    _allDay = v;
                    if (v) {
                      _start = DateTime(
                        _start.year,
                        _start.month,
                        _start.day,
                        0,
                        0,
                      );
                      _end = DateTime(
                        _start.year,
                        _start.month,
                        _start.day,
                        23,
                        59,
                      );
                    }
                  });
                },
                title: const Text('All-day'),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStart,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Starts'),
                        child: Text(
                          _allDay
                              ? ml.formatFullDate(_start)
                              : '${ml.formatFullDate(_start)} • '
                                  '${TimeOfDay.fromDateTime(_start).format(context)}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEnd,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ends'),
                        child: Text(
                          _allDay
                              ? ml.formatFullDate(_end)
                              : '${ml.formatFullDate(_end)} • '
                                  '${TimeOfDay.fromDateTime(_end).format(context)}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PRICE
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      value: _free,
                      onChanged: (v) => setState(() {
                        _free = v;
                        if (v) _price = 0;
                      }),
                      title: const Text('Free'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      enabled: !_free,
                      decoration:
                          const InputDecoration(labelText: 'Price (USD)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (_free) return null;
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a price or mark Free';
                        }
                        final parsed = double.tryParse(v);
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                      onSaved: (v) {
                        if (_free) {
                          _price = 0;
                        } else {
                          _price = double.tryParse(v ?? '0') ?? 0;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // FLAGS
              SwitchListTile(
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
                title: const Text('Featured'),
              ),
              const SizedBox(height: 24),

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
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this event.'),
        ),
      );
      return;
    }

    // Ensure end is after start
    if (!_end.isAfter(_start)) {
      _end = _start.add(const Duration(hours: 1));
    }

    setState(() => _saving = true);

    try {
      final title = _titleController.text.trim();
      final imageUrl = _imageUrlController.text.trim();
      final website =
          _externalLink.trim().isEmpty ? null : _externalLink.trim();

      final event = Event(
        id: '',
        title: title,
        address: _address.trim(),
        city: _city.trim(),
        state: _state.trim(),
        zip: _zip.trim(),
        category: _category, // slug
        venue: _venue.trim(),
        description: _description.trim(),
        website: website,
        featured: _featured,
        allDay: _allDay,
        free: _free,
        price: _free ? 0 : (_price ?? 0),
        start: _start,
        end: _end,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        tags: const [],
        search: [
          title.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          _venue.toLowerCase(),
        ],
        stateId: _stateId ?? '',
        stateName: _stateName ?? '',
        metroId: _metroId ?? '',
        metroName: _metroName ?? '',
        areaId: _areaId ?? '',
        areaName: _areaName ?? '',
      );

      await FirebaseFirestore.instance.collection('events').add({
        ...event.toMap(),
        // extra image metadata (optional)
        'galleryImageUrls': _imageUrls,
        'bannerImageUrl': _bannerImageUrl.isEmpty ? null : _bannerImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved to Firestore ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    if (_allDay) {
      setState(() {
        _start = DateTime(d.year, d.month, d.day, 0, 0);
        _end = DateTime(d.year, d.month, d.day, 23, 59);
      });
      return;
    }

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (t == null) return;

    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    if (_allDay) {
      setState(() {
        _end = DateTime(d.year, d.month, d.day, 23, 59);
      });
      return;
    }

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (t == null) return;

    final candidate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      _end = candidate.isAfter(_start)
          ? candidate
          : _start.add(const Duration(hours: 1));
    });
  }
}
