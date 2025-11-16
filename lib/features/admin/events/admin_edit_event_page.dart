// lib/features/admin/events/admin_edit_event_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../../../widgets/location_selector.dart';

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

  late String _title;
  late String _city;
  late String _category;
  late String _venue;
  late String _address;
  late String _externalLink;
  late String _description;

  late bool _featured;
  late bool _allDay;
  late bool _free;
  double? _price;

  late DateTime _start;
  late DateTime _end;

  bool _saving = false;

  // Location fields
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;
  bool _loadingInitialLocation = true;

  static const _categories = [
    'Festival',
    'Music',
    'Food & Drink',
    'Family',
    'Sports',
    'Market',
    'Arts',
    'Government',
    'Community',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _title = e.title;
    _city = e.city;
    _category = e.category.isNotEmpty ? e.category : _categories.first;
    _venue = e.venue;
    _address = e.address;
    _externalLink = e.website ?? '';
    _description = e.description;

    _featured = e.featured;
    _allDay = e.allDay;
    _free = e.free;
    _price = e.free ? 0 : e.price;

    _start = e.start;
    _end = e.end;

    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .get();

      final data = doc.data() as Map<String, dynamic>?;

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _stateId = data['stateId'] as String?;
          _stateName = data['stateName'] as String?;
          _metroId = data['metroId'] as String?;
          _metroName = data['metroName'] as String?;
          _areaId = data['areaId'] as String?;
          _areaName = data['areaName'] as String?;
          _loadingInitialLocation = false;
        });
      } else {
        setState(() {
          _loadingInitialLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading event location: $e');
      if (!mounted) return;
      setState(() {
        _loadingInitialLocation = false;
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
              // --- BASIC INFO ---
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (v) => _title = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // City as free text
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _categories.contains(_category)
                    ? _category
                    : _categories.first,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),

              // --- LOCATION SELECTOR ---
              if (_loadingInitialLocation)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else ...[
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
              ],

              TextFormField(
                initialValue: _venue,
                decoration: const InputDecoration(labelText: 'Venue'),
                onSaved: (v) => _venue = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                onSaved: (v) => _address = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _description,
                decoration:
                    const InputDecoration(labelText: 'Short Description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _externalLink,
                decoration: const InputDecoration(
                  labelText: 'External Link (optional)',
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _externalLink = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // --- TIME ---
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

              // --- PRICE ---
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

              // --- FLAGS ---
              SwitchListTile(
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
                title: const Text('Featured'),
              ),
              const SizedBox(height: 24),

              // --- SAVE BUTTON ---
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
      final website =
          _externalLink.trim().isEmpty ? null : _externalLink.trim();

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
        'title': _title.trim(),
        'city': _city,
        'category': _category,
        'venue': _venue.trim(),
        'address': _address.trim(),
        'description': _description.trim(),
        'website': website,
        'featured': _featured,
        'allDay': _allDay,
        'free': _free,
        'price': _free ? 0 : (_price ?? 0),
        'start': Timestamp.fromDate(_start),
        'end': Timestamp.fromDate(_end),

        // Location
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',

        'tags': widget.event.tags,
        'search': [
          _title.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          _venue.toLowerCase(),
        ],
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
