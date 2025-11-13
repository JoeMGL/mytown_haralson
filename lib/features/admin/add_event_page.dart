import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});
  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _form = GlobalKey<FormState>();

  String _title = '';
  String _city = 'Tallapoosa';
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

  static const _cities = ['Tallapoosa', 'Bremen', 'Buchanan', 'Waco'];
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
    // NO Scaffold here – AdminShell wraps this and provides AppBar + SafeArea
    final ml = MaterialLocalizations.of(context);

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Add Event', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // Title
          TextFormField(
            decoration: const InputDecoration(labelText: 'Title'),
            onSaved: (v) => _title = v?.trim() ?? '',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // City
          DropdownButtonFormField<String>(
            value: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _city = v ?? _city),
          ),
          const SizedBox(height: 12),

          // Category
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),

          // Venue
          TextFormField(
            decoration: const InputDecoration(labelText: 'Venue'),
            onSaved: (v) => _venue = v?.trim() ?? '',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Address
          TextFormField(
            decoration: const InputDecoration(labelText: 'Address'),
            onSaved: (v) => _address = v?.trim() ?? '',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            decoration: const InputDecoration(labelText: 'Short Description'),
            maxLines: 3,
            onSaved: (v) => _description = v?.trim() ?? '',
          ),
          const SizedBox(height: 12),

          // External link (optional)
          TextFormField(
            decoration:
                const InputDecoration(labelText: 'External Link (optional)'),
            keyboardType: TextInputType.url,
            onSaved: (v) => _externalLink = v?.trim() ?? '',
          ),
          const SizedBox(height: 12),

          // All-day
          SwitchListTile(
            value: _allDay,
            onChanged: (v) {
              setState(() {
                _allDay = v;
                if (v) {
                  _start =
                      DateTime(_start.year, _start.month, _start.day, 0, 0);
                  _end =
                      DateTime(_start.year, _start.month, _start.day, 23, 59);
                }
              });
            },
            title: const Text('All-day'),
          ),
          const SizedBox(height: 8),

          // Start / End (tap to pick)
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
                          : '${ml.formatFullDate(_start)} • ${TimeOfDay.fromDateTime(_start).format(context)}',
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
                          : '${ml.formatFullDate(_end)} • ${TimeOfDay.fromDateTime(_end).format(context)}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Free / Price
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
                  decoration: const InputDecoration(labelText: 'Price (USD)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (_free) return null;
                    if (v == null || v.trim().isEmpty)
                      return 'Enter a price or mark Free';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed < 0)
                      return 'Enter a valid price';
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
          const SizedBox(height: 12),

          // Featured
          SwitchListTile(
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            title: const Text('Featured'),
          ),
          const SizedBox(height: 12),

          // Save
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
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    // Guard end >= start
    if (!_end.isAfter(_start)) {
      _end = _start.add(const Duration(hours: 1));
    }

    setState(() => _saving = true);
    try {
      final doc = {
        'title': _title.trim(),
        'city': _city,
        'category': _category,
        'venue': _venue.trim(),
        'address': _address.trim(),
        'description': _description.trim(),

        // 🔁 match EventDetailPage field name
        'website': _externalLink.trim().isEmpty ? null : _externalLink.trim(),

        'featured': _featured,
        'allDay': _allDay,
        'free': _free,
        'price': _free ? 0 : _price,

        // 🔁 match EventsPage: it expects "start" and "end"
        'start': _start, // Firestore will store as Timestamp
        'end': _end,

        'search': [
          _title.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
          _venue.toLowerCase(),
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // image fields can be added later
      };

      await FirebaseFirestore.instance.collection('events').add(doc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved to Firestore ✅')),
        );
        Navigator.of(context).pop(); // go back after save
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
