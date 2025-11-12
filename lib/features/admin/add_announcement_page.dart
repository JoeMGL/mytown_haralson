import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _saving = false;

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when ?? now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when ?? now),
    );
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Announcement')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _aud,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                'County-wide',
                'Tallapoosa',
                'Bremen',
                'Buchanan',
                'Waco'
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _aud = v ?? 'County-wide'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title'),
              onSaved: (v) => _title = v ?? '',
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 4,
              onSaved: (v) => _message = v ?? '',
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('When'),
              subtitle: Text(
                _when == null ? 'Not set' : _when!.toLocal().toString(),
              ),
              trailing: TextButton.icon(
                onPressed: _pickWhen,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Pick'),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _push,
              onChanged: (v) => setState(() => _push = v),
              title: const Text('Push notification'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.schedule),
              label: Text(_saving ? 'Scheduling…' : 'Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    if (_when == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a date/time')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'audience': _aud, // "County-wide" | "Tallapoosa" | ...
        'title': _title.trim(),
        'message': _message.trim(),
        'when': Timestamp.fromDate(_when!), // schedule time
        'push': _push, // whether to push
        'status': 'scheduled', // scheduled | sent | canceled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement saved ✅')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
