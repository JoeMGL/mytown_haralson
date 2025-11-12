import 'package:flutter/material.dart';

class AddAttractionPage extends StatefulWidget {
  const AddAttractionPage({super.key});
  @override
  State<AddAttractionPage> createState() => _AddAttractionPageState();
}

class _AddAttractionPageState extends State<AddAttractionPage> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  String _city = 'Tallapoosa';
  String _category = 'Outdoor';
  String _coords = '';
  bool _featured = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Attraction')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Name'), onSaved: (v)=>_name=v??'' , validator: (v)=> (v==null||v.isEmpty)?'Required':null),
            const SizedBox(height: 12),
            DropdownButtonFormField(value: _city, decoration: const InputDecoration(labelText: 'City'),
              items: const ['Tallapoosa','Bremen','Buchanan','Waco'].map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v){ setState(()=>_city=v!); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(value: _category, decoration: const InputDecoration(labelText: 'Category'),
              items: const ['Outdoor','Museum','Landmark','Family'].map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v){ setState(()=>_category=v!); },
            ),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Coordinates (lat,lng)'), onSaved: (v)=>_coords=v??''),
            const SizedBox(height: 12),
            SwitchListTile(value: _featured, onChanged: (v)=>setState(()=>_featured=v), title: const Text('Featured')),
            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if(_form.currentState!.validate()) {
      _form.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attraction saved (stub). Connect to Firestore.')));
    }
  }
}
