import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/eat_and_drink.dart';
import '../../../widgets/location_selector.dart';

class AddEatAndDrinkPage extends StatefulWidget {
  const AddEatAndDrinkPage({super.key});

  @override
  State<AddEatAndDrinkPage> createState() => _AddEatAndDrinkPageState();
}

class _AddEatAndDrinkPageState extends State<AddEatAndDrinkPage> {
  final _form = GlobalKey<FormState>();

  String _name = '';
  String _city = 'Tallapoosa';
  String _category = 'Restaurant';
  String _description = '';
  String _hours = '';
  String _phone = '';
  String _website = '';
  String _mapQuery = '';

  bool _featured = false;
  bool _saving = false;

  // Location
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Eat & Drink'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => _name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                decoration:
                    const InputDecoration(labelText: 'Description (short)'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: 'e.g. Mon–Sat 11am–9pm',
                ),
                onSaved: (v) => _hours = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _phone = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _website = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
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
      final place = EatAndDrink(
        id: '',
        name: _name.trim(),
        city: _city.trim(),
        category: _category,
        description: _description.trim(),
        imageUrl: '', // can be set later via separate flow
        heroTag: '',
        hours: _hours.trim().isEmpty ? null : _hours.trim(),
        tags: const [],
        coords: null,
        phone: _phone.trim().isEmpty ? null : _phone.trim(),
        website: _website.trim().isEmpty ? null : _website.trim(),
        mapQuery: _mapQuery.trim().isEmpty ? null : _mapQuery.trim(),
        featured: _featured,
        active: true,
        search: [
          _name.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
        ],
        stateId: _stateId ?? '',
        stateName: _stateName ?? '',
        metroId: _metroId ?? '',
        metroName: _metroName ?? '',
        areaId: _areaId ?? '',
        areaName: _areaName ?? '',
      );

      await FirebaseFirestore.instance.collection('eatAndDrink').add({
        ...place.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dining place added ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving dining: $e')),
      );
    }
  }
}
