// lib/features/admin/events/admin_add_event_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../../../widgets/location_selector.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});
  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _form = GlobalKey<FormState>();

  String _title = '';
  String _city = '';
  String _category = 'Festival';
  String _venue = '';
  String _address = '';
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
  Widget build(BuildContext context) {
    final ml = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
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
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (v) => _title = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // City (free text instead of dropdown)
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),

              // --- LOCATION SELECTOR (STATE / METRO / AREA) ---
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

              TextFormField(
                decoration: const InputDecoration(labelText: 'Venue'),
                onSaved: (v) => _venue = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Address'),
                onSaved: (v) => _address = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Short Description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              TextFormField(
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

    // Require state + metro like Clubs
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
      final event = Event(
        id: '', // Firestore will assign
        title: _title.trim(),
        city: _city,
        category: _category,
        venue: _venue.trim(),
        address: _address.trim(),
        description: _description.trim(),
        website: _externalLink.trim().isEmpty ? null : _externalLink.trim(),
        featured: _featured,
        allDay: _allDay,
        free: _free,
        price: _free ? 0 : (_price ?? 0),
        start: _start,
        end: _end,
        imageUrl: null,
        tags: const [],
        search: [
          _title.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          _venue.toLowerCase(),
        ],
      );

      await FirebaseFirestore.instance.collection('events').add({
        ...event.toMap(),
        // Location
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved to Firestore ✅')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
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
      if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 1));
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
