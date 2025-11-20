import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/image_editor_page.dart';

/// Must match the `section` value in your `categories` docs for events.
const String kEventsSectionSlug = 'events';

class EditEventPage extends StatefulWidget {
  const EditEventPage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _form = GlobalKey<FormState>();

  // Controllers for fields that must round-trip perfectly
  late TextEditingController _titleController;
  late TextEditingController _imageUrlController;

  // Core fields
  late String _category; // slug
  late String _address;
  late String _city;
  late String _state;
  late String _zip;
  late String _venue;
  late String _description;
  late String _externalLink;

  late bool _featured;
  late bool _allDay;
  late bool _free;
  double? _price;

  late DateTime _start;
  late DateTime _end;

  bool _saving = false;

  // Location fields (mirroring Clubs / Event model)
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
  String _bannerImageUrl = '';

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _titleController = TextEditingController(text: e.title);
    _imageUrlController = TextEditingController(text: e.imageUrl ?? '');

    _category = e.category;
    _address = e.address;
    _city = e.city;
    _state = e.state;
    _zip = e.zip;
    _venue = e.venue;
    _description = e.description;
    _externalLink = e.website ?? '';

    _featured = e.featured;
    _allDay = e.allDay;
    _free = e.free;
    _price = e.free ? 0 : e.price;

    _start = e.start;
    _end = e.end;

    // Location (now available directly on Event model)
    _stateId = e.stateId.isNotEmpty ? e.stateId : null;
    _stateName = e.stateName.isNotEmpty ? e.stateName : null;
    _metroId = e.metroId.isNotEmpty ? e.metroId : null;
    _metroName = e.metroName.isNotEmpty ? e.metroName : null;
    _areaId = e.areaId.isNotEmpty ? e.areaId : null;
    _areaName = e.areaName.isNotEmpty ? e.areaName : null;

    _loadCategories();
    _loadImageExtras();
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

        // Ensure current category is valid; if not, default to first
        if (_categories.isNotEmpty) {
          final slugs = _categories.map((c) => c.slug).toSet();
          if (!slugs.contains(_category)) {
            _category = _categories.first.slug;
          }
        }
      });
    } catch (e) {
      setState(() {
        _categoriesError = 'Error loading categories: $e';
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadImageExtras() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .get();

      final data = doc.data();
      if (data == null) return;

      setState(() {
        _imageUrls =
            (data['galleryImageUrls'] as List?)?.cast<String>() ?? <String>[];
        _bannerImageUrl = (data['bannerImageUrl'] ?? '') as String;
      });
    } catch (e) {
      debugPrint('Error loading image extras for event: $e');
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
            result.isNotEmpty ? result.first : ''; // clear if empty
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ml = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Event: ${widget.event.title}'),
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

              // CATEGORY (dynamic)
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

              // ADDRESS
              TextFormField(
                initialValue: _address,
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

              // LOCATION SELECTOR
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
                initialValue: _venue,
                decoration: const InputDecoration(labelText: 'Venue'),
                onSaved: (v) => _venue = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // IMAGES
              ListTile(
                title: const Text('Gallery images'),
                subtitle: Text(
                  _imageUrls.isEmpty
                      ? 'Tap to edit images'
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
                initialValue: _description,
                decoration:
                    const InputDecoration(labelText: 'Short description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // WEBSITE
              TextFormField(
                initialValue: _externalLink,
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
                      initialValue: _free
                          ? ''
                          : (_price != null ? _price.toString() : ''),
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
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Saving...' : 'Save changes'),
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

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
        'title': title,
        'address': _address.trim(),
        'city': _city.trim(),
        'state': _state.trim(),
        'zip': _zip.trim(),
        'category': _category,
        'venue': _venue.trim(),
        'description': _description.trim(),
        'website': website,
        'featured': _featured,
        'allDay': _allDay,
        'free': _free,
        'price': _free ? 0 : (_price ?? 0),
        'start': Timestamp.fromDate(_start),
        'end': Timestamp.fromDate(_end),
        'imageUrl': imageUrl.isEmpty ? null : imageUrl,

        // location
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',

        // tags unchanged
        'tags': widget.event.tags,

        // search fields
        'search': [
          title.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          _venue.toLowerCase(),
        ],

        // images extras
        'galleryImageUrls': _imageUrls,
        'bannerImageUrl': _bannerImageUrl.isEmpty ? null : _bannerImageUrl,

        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
      setState(() => _saving = false);
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
