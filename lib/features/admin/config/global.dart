import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});
  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _form = GlobalKey<FormState>();
  final _appNameCtrl = TextEditingController(text: 'Visit Haralson County');
  final _emergencyMsgCtrl =
      TextEditingController(text: 'Emergency alert mode enabled.');

  bool _saving = false;
  bool _loading = true;

  // --- Settings state ---
  String _defaultCity = 'County-wide';
  String _themeMode = 'system'; // system | light | dark
  bool _forceUpdate = false;

  bool _pushEnabled = true;
  String _defaultAudience = 'County-wide';
  bool _weeklyEmailDigest = false;
  bool _emergencyMode = false;

  bool _autoArchiveEvents = true;

  static const _cities = [
    'County-wide',
    'Tallapoosa',
    'Bremen',
    'Buchanan',
    'Waco'
  ];

  // Firestore doc path: /admin/config/global   (flat + easy)
  DocumentReference<Map<String, dynamic>> get _configRef =>
      FirebaseFirestore.instance
          .collection('admin')
          .doc('config')
          .collection('meta')
          .doc('global');

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final snap = await _configRef.get();
      final data = snap.data();
      if (data != null) {
        final app = (data['app'] ?? {}) as Map<String, dynamic>;
        final noti = (data['notifications'] ?? {}) as Map<String, dynamic>;
        final dta = (data['data'] ?? {}) as Map<String, dynamic>;

        _appNameCtrl.text = (app['name'] ?? _appNameCtrl.text) as String;
        _defaultCity = (app['defaultCity'] ?? _defaultCity) as String;
        _themeMode = (app['themeMode'] ?? _themeMode) as String;
        _forceUpdate = (app['forceUpdate'] ?? _forceUpdate) as bool;

        _pushEnabled = (noti['pushEnabled'] ?? _pushEnabled) as bool;
        _defaultAudience =
            (noti['defaultAudience'] ?? _defaultAudience) as String;
        _weeklyEmailDigest =
            (noti['weeklyEmailDigest'] ?? _weeklyEmailDigest) as bool;
        _emergencyMode = (noti['emergencyMode'] ?? _emergencyMode) as bool;
        _emergencyMsgCtrl.text =
            (noti['emergencyMessage'] ?? _emergencyMsgCtrl.text) as String;

        _autoArchiveEvents =
            (dta['autoArchiveEvents'] ?? _autoArchiveEvents) as bool;
      }
    } catch (_) {
      // non-fatal; keep defaults
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _emergencyMsgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NO Scaffold – AdminShell wraps this and provides AppBar + SafeArea
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // --- App Configuration ---
          Text('App Configuration',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _appNameCtrl,
            decoration: const InputDecoration(labelText: 'App Display Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _defaultCity,
            decoration: const InputDecoration(labelText: 'Default City'),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _defaultCity = v ?? _defaultCity),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _themeMode,
            decoration: const InputDecoration(labelText: 'Theme Mode'),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System')),
              DropdownMenuItem(value: 'light', child: Text('Light')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
            ],
            onChanged: (v) => setState(() => _themeMode = v ?? _themeMode),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _forceUpdate,
            onChanged: (v) => setState(() => _forceUpdate = v),
            title: const Text('Force Update'),
            subtitle:
                const Text('Require users to update to the latest app version'),
          ),

          const SizedBox(height: 20),

          // --- Notifications & Communication ---
          Text('Notifications & Communication',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
            title: const Text('Enable Push Notifications'),
          ),
          DropdownButtonFormField<String>(
            value: _defaultAudience,
            decoration:
                const InputDecoration(labelText: 'Default Push Audience'),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _defaultAudience = v ?? _defaultAudience),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _weeklyEmailDigest,
            onChanged: (v) => setState(() => _weeklyEmailDigest = v),
            title: const Text('Weekly Email Digest'),
          ),
          SwitchListTile(
            value: _emergencyMode,
            onChanged: (v) => setState(() => _emergencyMode = v),
            title: const Text('Emergency Alert Mode'),
          ),
          TextFormField(
            controller: _emergencyMsgCtrl,
            decoration: const InputDecoration(
              labelText: 'Emergency Message',
              helperText: 'Shown when Emergency Mode is enabled',
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 20),

          // --- Data Management ---
          Text('Data Management',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _autoArchiveEvents,
            onChanged: (v) => setState(() => _autoArchiveEvents = v),
            title: const Text('Auto-Archive Past Events'),
            subtitle: const Text('Archive events after their end date'),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _configRef.set({
        'app': {
          'name': _appNameCtrl.text.trim(),
          'defaultCity': _defaultCity,
          'themeMode': _themeMode,
          'forceUpdate': _forceUpdate,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'notifications': {
          'pushEnabled': _pushEnabled,
          'defaultAudience': _defaultAudience,
          'weeklyEmailDigest': _weeklyEmailDigest,
          'emergencyMode': _emergencyMode,
          'emergencyMessage': _emergencyMsgCtrl.text.trim(),
        },
        'data': {
          'autoArchiveEvents': _autoArchiveEvents,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved to Firestore ✅')),
        );
        Navigator.of(context).pop(); // Back to admin screen after save
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
