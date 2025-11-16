import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/shop.dart';
import '../../../widgets/location_selector.dart';

class AddShopPage extends StatefulWidget {
  const AddShopPage({super.key});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final _form = GlobalKey<FormState>();

  String _name = '';
  String _category = 'Retail / Boutique';
  String _city = 'Tallapoosa';
  String _address = '';
  String _description = '';
  String _phone = '';
  String _website = '';
  String _facebook = '';
  String _hours = '';

  bool _featured = false;
  bool _saving = false;

  // Location fields
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  static const _categories = [
    'Retail / Boutique',
    'Antiques & Vintage',
    'Home & Gifts',
    'Salon / Spa',
    'Professional Services',
    'Food & Drink',
    'Entertainment',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Shop / Business'),
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
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => _name = v?.trim() ?? '',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),

              // City (free text)
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
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
              const SizedBox(height: 12),

              // Address
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: '123 Main Street',
                ),
                onSaved: (v) => _address = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Hours
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: 'e.g. Mon–Sat 10am–6pm',
                ),
                onSaved: (v) => _hours = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // CONTACT
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
                  labelText: 'Facebook page',
                  hintText: 'https://facebook.com/...',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _facebook = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // FEATURED
              SwitchListTile(
                title: const Text('Feature this shop'),
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

    // Require state + metro like clubs/events
    if (_stateId == null || _metroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state and metro for this shop.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final shop = Shop(
        id: '',
        name: _name.trim(),
        category: _category,
        city: _city.trim(),
        address: _address.trim(),
        description: _description.trim(),
        phone: _phone.trim().isEmpty ? null : _phone.trim(),
        website: _website.trim().isEmpty ? null : _website.trim(),
        facebook: _facebook.trim().isEmpty ? null : _facebook.trim(),
        hours: _hours.trim().isEmpty ? null : _hours.trim(),
        imageUrl: null,
        featured: _featured,
        active: true,
        tags: const [],
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

      await FirebaseFirestore.instance.collection('shops').add({
        ...shop.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop / Business added ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving shop: $e')),
      );
    }
  }
}
