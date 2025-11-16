import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/eat_and_drink.dart';
import '../../../widgets/location_selector.dart';

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
  late String _category;
  late String _description;
  late String _hours;
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

  static const _categories = [
    'Restaurant',
    'Bar / Pub',
    'Coffee / Cafe',
    'Bakery / Sweets',
    'Brewery / Winery',
    'Food Truck',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.place;

    _name = p.name;
    _city = p.city;
    _category =
        _categories.contains(p.category) ? p.category : _categories.first;
    _description = p.description;
    _hours = p.hours ?? '';
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
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => _name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
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
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
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
                initialValue: _description,
                decoration:
                    const InputDecoration(labelText: 'Description (short)'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _hours,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: 'e.g. Mon–Sat 11am–9pm',
                ),
                onSaved: (v) => _hours = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
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
          content:
              Text('Please select a state and metro for this dining place.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('eatAndDrink')
          .doc(widget.place.id)
          .update({
        'name': _name.trim(),
        'city': _city.trim(),
        'category': _category,
        'description': _description.trim(),
        'hours': _hours.trim().isEmpty ? null : _hours.trim(),
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
          _category.toLowerCase(),
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
