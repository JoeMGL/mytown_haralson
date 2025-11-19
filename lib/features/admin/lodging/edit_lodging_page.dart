import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/lodging.dart';
import '../../../models/place.dart' show DayHours;
import '../../../models/category.dart';
import '../../../widgets/location_selector.dart';
import '../../../widgets/weekly_hours_field.dart';

/// Must match the `section` value used for lodging categories.
const String kStaysSectionSlug = 'stays';

class EditLodgingPage extends StatefulWidget {
  const EditLodgingPage({
    super.key,
    required this.stay,
  });

  final Stay stay;

  @override
  State<EditLodgingPage> createState() => _EditLodgingPageState();
}

class _EditLodgingPageState extends State<EditLodgingPage> {
  final _form = GlobalKey<FormState>();

  late String _name;

  // Address parts
  late String _street;
  late String _city;
  late String _state;
  late String _zip;

  late String _description;
  late String _phone;
  late String _website;
  late String _mapQuery;

  late bool _featured;
  late bool _active;

  bool _saving = false;

  // Location selector (for filters)
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  // Categories (dynamic from Firestore)
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;
  String? _categoriesError;

  // Structured hours
  Map<String, DayHours> _hoursByDay = {};

  @override
  void initState() {
    super.initState();
    final s = widget.stay;

    _name = s.name;

    _street = s.street;
    _city = s.city;
    _state = s.state.isNotEmpty ? s.state : 'GA';
    _zip = s.zip;

    _description = s.description;
    _phone = s.phone ?? '';
    _website = s.website ?? '';
    _mapQuery = s.mapQuery ?? '';

    _featured = s.featured;
    _active = s.active;

    _stateId = s.stateId.isNotEmpty ? s.stateId : null;
    _stateName = s.stateName;
    _metroId = s.metroId.isNotEmpty ? s.metroId : null;
    _metroName = s.metroName;
    _areaId = s.areaId.isNotEmpty ? s.areaId : null;
    _areaName = s.areaName;

    _hoursByDay = s.hoursByDay ?? {};

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kStaysSectionSlug)
          .orderBy('sortOrder')
          .get();

      final cats = snap.docs.map<Category>((d) => Category.fromDoc(d)).toList();

      // Try to match existing stay.category to a Category.name
      Category? selected;
      try {
        selected = cats.firstWhere((c) => c.name == widget.stay.category);
      } catch (_) {
        if (cats.isNotEmpty) {
          selected = cats.first;
        }
      }

      setState(() {
        _categories = cats;
        _selectedCategoryId = selected?.id;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categoriesError = 'Error loading categories: $e';
        _loadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Lodging: ${widget.stay.name}'),
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

              // Category dropdown (dynamic)
              if (_loadingCategories) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              ] else if (_categoriesError != null) ...[
                Text(
                  _categoriesError!,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 8),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedCategoryId = v);
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please choose a category'
                      : null,
                ),
              ],
              const SizedBox(height: 16),

              // 📍 Full street address fields
              TextFormField(
                initialValue: _street,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: '123 Main Street',
                ),
                textCapitalization: TextCapitalization.words,
                onSaved: (v) => _street = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Street is required'
                    : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _city,
                      decoration: const InputDecoration(labelText: 'City'),
                      textCapitalization: TextCapitalization.words,
                      onSaved: (v) => _city = v?.trim() ?? '',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'City required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _state,
                      decoration: const InputDecoration(labelText: 'State'),
                      textCapitalization: TextCapitalization.characters,
                      onSaved: (v) => _state = v?.trim() ?? '',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'State' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _zip,
                      decoration: const InputDecoration(labelText: 'ZIP'),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _zip = v?.trim() ?? '',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'ZIP' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // LocationSelector (for filters: state/metro/area)
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

              // Weekly hours widget
              WeeklyHoursField(
                initialValue: _hoursByDay,
                onChanged: (value) {
                  setState(() {
                    _hoursByDay = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

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

              // Maps query
              TextFormField(
                initialValue: _mapQuery,
                decoration: const InputDecoration(
                  labelText: 'Maps query (optional)',
                  hintText: 'Name + city, or address',
                ),
                onSaved: (v) => _mapQuery = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

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
          content: Text('Please select a state and metro for this lodging.'),
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category for this lodging.'),
        ),
      );
      return;
    }

    final category = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );

    setState(() => _saving = true);

    try {
      final fullAddress =
          _street.isEmpty ? '' : '$_street, $_city, $_state $_zip'.trim();

      await FirebaseFirestore.instance
          .collection('stays')
          .doc(widget.stay.id)
          .update({
        'name': _name.trim(),
        'city': _city.trim(),
        'category': category.name,
        'address': fullAddress,
        'street': _street.trim(),
        'state': _state.trim(),
        'zip': _zip.trim(),
        'description': _description.trim(),

        // structured hours
        'hoursByDay': _hoursByDay.isEmpty
            ? null
            : _hoursByDay.map(
                (key, value) => MapEntry(key, value.toMap()),
              ),

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
        'search': [
          _name.toLowerCase(),
          _city.toLowerCase(),
          category.name.toLowerCase(),
          if (_street.isNotEmpty) _street.toLowerCase(),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lodging updated ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating lodging: $e')),
      );
    }
  }
}
