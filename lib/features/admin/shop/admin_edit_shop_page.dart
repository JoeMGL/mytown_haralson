import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/shop.dart';
import '../../../widgets/location_selector.dart';

class EditShopPage extends StatefulWidget {
  const EditShopPage({
    super.key,
    required this.shop,
  });

  final Shop shop;

  @override
  State<EditShopPage> createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
  final _form = GlobalKey<FormState>();

  late String _name;
  late String _category;
  late String _city;
  late String _address;
  late String _description;
  late String _phone;
  late String _website;
  late String _facebook;
  late String _hours;

  late bool _featured;
  late bool _active;
  bool _saving = false;

  // Location
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
  void initState() {
    super.initState();
    final s = widget.shop;

    _name = s.name;
    _category = s.category.isNotEmpty ? s.category : _categories.first;
    _city = s.city;
    _address = s.address;
    _description = s.description;
    _phone = s.phone ?? '';
    _website = s.website ?? '';
    _facebook = s.facebook ?? '';
    _hours = s.hours ?? '';

    _featured = s.featured;
    _active = s.active;

    _stateId = s.stateId.isNotEmpty ? s.stateId : null;
    _stateName = s.stateName;
    _metroId = s.metroId.isNotEmpty ? s.metroId : null;
    _metroName = s.metroName;
    _areaId = s.areaId.isNotEmpty ? s.areaId : null;
    _areaName = s.areaName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Shop: ${widget.shop.name}'),
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

              // Category
              DropdownButtonFormField<String>(
                value: _categories.contains(_category)
                    ? _category
                    : _categories.first,
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

              // City
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => _city = v?.trim() ?? '',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Location selector
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
                initialValue: _address,
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
                initialValue: _hours,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: 'e.g. Mon–Sat 10am–6pm',
                ),
                onSaved: (v) => _hours = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // CONTACT
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
                initialValue: _facebook,
                decoration: const InputDecoration(
                  labelText: 'Facebook page',
                  hintText: 'https://facebook.com/...',
                ),
                keyboardType: TextInputType.url,
                onSaved: (v) => _facebook = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),

              // Flags
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
          content: Text('Please select a state and metro for this shop.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .update({
        'name': _name.trim(),
        'category': _category,
        'city': _city.trim(),
        'address': _address.trim(),
        'description': _description.trim(),
        'phone': _phone.trim().isEmpty ? null : _phone.trim(),
        'website': _website.trim().isEmpty ? null : _website.trim(),
        'facebook': _facebook.trim().isEmpty ? null : _facebook.trim(),
        'hours': _hours.trim().isEmpty ? null : _hours.trim(),
        'featured': _featured,
        'active': _active,

        // Location
        'stateId': _stateId,
        'stateName': _stateName ?? '',
        'metroId': _metroId,
        'metroName': _metroName ?? '',
        'areaId': _areaId,
        'areaName': _areaName ?? '',

        // search/tags (simple pattern)
        'search': [
          _name.toLowerCase(),
          _city.toLowerCase(),
          _category.toLowerCase(),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop updated ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating shop: $e')),
      );
    }
  }
}
