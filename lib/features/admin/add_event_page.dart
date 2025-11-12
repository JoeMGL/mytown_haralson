import 'package:flutter/material.dart';

/// Admin Add Event Page
///
/// UX goals:
/// - Simple, scannable form with logical sections (Basics, Schedule, Location, Visibility)
/// - Sensible defaults (city preselected, start = now + 2h, end = +3h)
/// - Returns a Map<String, dynamic> with all values on Save (easy to send to Firestore)
/// - Works without extra packages; image upload/select can be wired later
class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Form fields ---
  String _title = '';
  String _category = 'Festival';
  String _audienceCity = 'Tallapoosa';
  String _venue = '';
  String _address = '';
  String _externalLink = '';
  String _description = '';
  bool _featured = false;
  bool _allDay = false;
  bool _free = true;
  double? _price;
  bool _publishNow = true;
  bool _sendPush = false;

  DateTime _start = DateTime.now().add(const Duration(hours: 2));
  DateTime _end = DateTime.now().add(const Duration(hours: 3));

  static const _cities = <String>[
    'County-wide',
    'Tallapoosa',
    'Bremen',
    'Buchanan',
    'Waco',
  ];

  static const _categories = <String>[
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

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return null;
    return DateTime(
      picked.year,
      picked.month,
      picked.day,
      initial.hour,
      initial.minute,
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
  }

  Future<void> _pickStart() async {
    final d = await _pickDate(context, _start);
    if (d == null) return;
    if (_allDay) {
      setState(() {
        _start = DateTime(d.year, d.month, d.day, 0, 0);
        _end = _start.add(const Duration(hours: 23, minutes: 59));
      });
      return;
    }
    final t = await _pickTime(context, TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final d = await _pickDate(context, _end);
    if (d == null) return;
    if (_allDay) {
      setState(() {
        _end = DateTime(d.year, d.month, d.day, 23, 59);
      });
      return;
    }
    final t = await _pickTime(context, TimeOfDay.fromDateTime(_end));
    if (t == null) return;
    final candidate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      _end = candidate.isAfter(_start)
          ? candidate
          : _start.add(const Duration(hours: 1));
    });
  }

  void _toggleAllDay(bool v) {
    setState(() {
      _allDay = v;
      if (v) {
        _start = DateTime(_start.year, _start.month, _start.day, 0, 0);
        _end = DateTime(_start.year, _start.month, _start.day, 23, 59);
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final event = <String, dynamic>{
      'title': _title.trim(),
      'category': _category,
      'city': _audienceCity,
      'venue': _venue.trim(),
      'address': _address.trim(),
      'description': _description.trim(),
      'externalLink':
          _externalLink.trim().isEmpty ? null : _externalLink.trim(),
      'featured': _featured,
      'allDay': _allDay,
      'free': _free,
      'price': _free ? 0 : _price,
      'sendPush': _sendPush,
      'publishNow': _publishNow,
      'startsAt': _start.toUtc(),
      'endsAt': _end.toUtc(),
      'createdAt': DateTime.now().toUtc(),
      'status': _publishNow ? 'published' : 'draft',
      // placeholder image fields to wire up later
      'imageUrl': null,
      'imageStoragePath': null,
    };

    // Pop with result so caller can persist to Firestore
    Navigator.of(context).pop(event);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 720;
            final content = _FormSections(
              titleBuilder: _buildBasics(theme),
              scheduleBuilder: _buildSchedule(theme),
              locationBuilder: _buildLocation(theme),
              visibilityBuilder: _buildVisibility(theme),
              wide: wide,
            );
            return SingleChildScrollView(child: content);
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save Event'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// --- Sections ---
  Widget _buildBasics(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Basics', style: theme.textTheme.titleLarge),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
            labelText: 'Event Title *',
            hintText: 'e.g., Tallapoosa Summer Night Market'),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Title is required' : null,
        onSaved: (v) => _title = v?.trim() ?? '',
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _category,
        items: _categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(growable: false),
        onChanged: (v) => setState(() => _category = v ?? _category),
        decoration: const InputDecoration(labelText: 'Category'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _audienceCity,
        items: _cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(growable: false),
        onChanged: (v) => setState(() => _audienceCity = v ?? _audienceCity),
        decoration: const InputDecoration(labelText: 'City / Audience'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
            labelText: 'Short Description',
            hintText: 'One or two sentences for cards & shares'),
        maxLines: 3,
        onSaved: (v) => _description = v?.trim() ?? '',
      ),
    ]);
  }

  Widget _buildSchedule(ThemeData theme) {
    final dateFmt = MaterialLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Schedule', style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      SwitchListTile(
        value: _allDay,
        onChanged: _toggleAllDay,
        title: const Text('All-day event'),
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: InkWell(
            onTap: _pickStart,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Starts *'),
              child: Text(_allDay
                  ? dateFmt.formatFullDate(_start)
                  : '${dateFmt.formatFullDate(_start)} • ${TimeOfDay.fromDateTime(_start).format(context)}'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: _pickEnd,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Ends *'),
              child: Text(_allDay
                  ? dateFmt.formatFullDate(_end)
                  : '${dateFmt.formatFullDate(_end)} • ${TimeOfDay.fromDateTime(_end).format(context)}'),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildLocation(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Location', style: theme.textTheme.titleLarge),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
            labelText: 'Venue', hintText: 'e.g., The Union on Odessa'),
        onSaved: (v) => _venue = v?.trim() ?? '',
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
            labelText: 'Address', hintText: 'Street, City, ZIP'),
        onSaved: (v) => _address = v?.trim() ?? '',
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 12),
      TextFormField(
        decoration: const InputDecoration(
            labelText: 'External Link',
            hintText: 'Ticketing or event page (optional)'),
        keyboardType: TextInputType.url,
        onSaved: (v) => _externalLink = v?.trim() ?? '',
      ),
      const SizedBox(height: 12),
      Row(children: [
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (_free) return null;
              if (v == null || v.trim().isEmpty)
                return 'Enter a price or mark Free';
              final parsed = double.tryParse(v);
              if (parsed == null || parsed < 0) return 'Enter a valid price';
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
      ]),
    ]);
  }

  Widget _buildVisibility(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Visibility & Promotion', style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      SwitchListTile(
        value: _featured,
        onChanged: (v) => setState(() => _featured = v),
        title: const Text('Mark as Featured'),
        subtitle:
            const Text('Appears in featured carousels on Explore / Events'),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        value: _publishNow,
        onChanged: (v) => setState(() => _publishNow = v),
        title: const Text('Publish immediately'),
        subtitle: const Text('If off, the event is saved as Draft'),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        value: _sendPush,
        onChanged: (v) => setState(() => _sendPush = v),
        title: const Text('Send push notification'),
        subtitle: const Text('Requires Notification service configured'),
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () {
          // Wire to image picker / uploader later
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image picker not wired yet')),
          );
        },
        icon: const Icon(Icons.image_outlined),
        label: const Text('Add Banner Image'),
      ),
    ]);
  }
}

/// Layout helper that arranges sections in 1 or 2 columns depending on width.
class _FormSections extends StatelessWidget {
  const _FormSections({
    required this.titleBuilder,
    required this.scheduleBuilder,
    required this.locationBuilder,
    required this.visibilityBuilder,
    required this.wide,
  });

  final Widget titleBuilder;
  final Widget scheduleBuilder;
  final Widget locationBuilder;
  final Widget visibilityBuilder;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final gap = const SizedBox(height: 20);
    if (!wide) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBuilder,
            gap,
            scheduleBuilder,
            gap,
            locationBuilder,
            gap,
            visibilityBuilder,
          ],
        ),
      );
    }

    // Two-column layout on wide screens
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBuilder,
                gap,
                scheduleBuilder,
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                locationBuilder,
                gap,
                visibilityBuilder,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
