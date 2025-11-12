import 'package:flutter/material.dart';

class AddAnnouncementPage extends StatefulWidget {
  const AddAnnouncementPage({super.key});
  @override
  State<AddAnnouncementPage> createState() => _AddAnnouncementPageState();
}

class _AddAnnouncementPageState extends State<AddAnnouncementPage> {
  final _form = GlobalKey<FormState>();
  String _aud = 'County-wide';
  String _title = '';
  String _message = '';
  DateTime? _when = DateTime.now().add(const Duration(hours: 2));
  bool _push = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Announcement')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField(value: _aud, decoration: const InputDecoration(labelText: 'Audience'),
              items: const ['County-wide','Tallapoosa','Bremen','Buchanan','Waco'].map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v)=>setState(()=>_aud=v??'County-wide'),
            ),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Title'), onSaved: (v)=>_title=v??'', validator: (v)=> (v==null||v.isEmpty)?'Required':null),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Message'), maxLines: 4, onSaved: (v)=>_message=v??'', validator: (v)=> (v==null||v.isEmpty)?'Required':null),
            const SizedBox(height: 12),
            SwitchListTile(value: _push, onChanged: (v)=>setState(()=>_push=v), title: const Text('Push notification')),
            const SizedBox(height: 12),
            FilledButton(onPressed: _submit, child: const Text('Schedule')),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if(_form.currentState!.validate()) {
      _form.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement scheduled (stub). Connect to FCM/Firestore.')));
    }
  }
}
