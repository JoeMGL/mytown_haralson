import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersAndRolesPage extends StatefulWidget {
  const UsersAndRolesPage({super.key});

  @override
  State<UsersAndRolesPage> createState() => _UsersAndRolesPageState();
}

class _UsersAndRolesPageState extends State<UsersAndRolesPage> {
  final _form = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _role = 'Viewer';
  String _scope = 'County-wide';
  bool _active = true;
  bool _saving = false;

  Future<void> _save() async {
    final form = _form.currentState;
    if (form == null) return;
    if (!form.validate()) return;
    form.save();

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('adminUsers').add({
        'name': _name.trim(),
        'email': _email.trim(),
        'role': _role,
        'scope': _scope,
        'active': _active,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User saved')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users & Roles'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
              onSaved: (v) => _name = (v ?? '').trim(),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _email = (v ?? '').trim(),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Required';
                if (!t.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const ['Admin', 'Editor', 'Viewer']
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _role = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _scope,
              decoration: const InputDecoration(labelText: 'Access Scope'),
              items: const [
                'County-wide',
                'Tallapoosa',
                'Bremen',
                'Buchanan',
                'Waco',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _scope = v);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
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
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving…' : 'Save User'),
            ),
          ],
        ),
      ),
    );
  }
}
