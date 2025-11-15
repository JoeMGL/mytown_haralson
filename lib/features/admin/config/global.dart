import 'package:flutter/foundation.dart'; // 👈 for kDebugMode
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
  // Theme / general
  String _themeMode = 'system'; // system | light | dark
  bool _forceUpdate = false;

  // Location (LIVE default for app users)
  String? _defaultStateId;
  String? _defaultMetroId;
  String? _defaultAreaId;

  // DEV preview location (DEV ONLY)
  String? _devStateId;
  String? _devMetroId;
  String? _devAreaId;

  // Notifications
  bool _pushEnabled = true;

  /// How wide the default audience is:
  /// 'area'  – only the default Area
  /// 'metro' – everyone in the default Metro
  /// 'state' – everyone in the default State
  /// 'all'   – entire app / all states
  String _defaultAudienceScope = 'area';

  bool _weeklyEmailDigest = false;
  bool _emergencyMode = false;

  bool _autoArchiveEvents = true;

  // Firestore doc path: /admin/config/global   (flat + easy)
  DocumentReference<Map<String, dynamic>> get _configRef =>
      FirebaseFirestore.instance
          .collection('admin')
          .doc('config')
          .collection('meta')
          .doc('global');

  // Location collections
  CollectionReference<Map<String, dynamic>> get _statesRef =>
      FirebaseFirestore.instance.collection('states');

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
        final dev = (data['dev'] ?? {}) as Map<String, dynamic>; // 👈 NEW

        _appNameCtrl.text = (app['name'] ?? _appNameCtrl.text) as String;
        _themeMode = (app['themeMode'] ?? _themeMode) as String;
        _forceUpdate = (app['forceUpdate'] ?? _forceUpdate) as bool;

        // LIVE defaultLocation (for real users)
        final loc = (app['defaultLocation'] ?? {}) as Map<String, dynamic>;
        _defaultStateId = loc['stateId'] as String?;
        _defaultMetroId = loc['metroId'] as String?;
        _defaultAreaId = loc['areaId'] as String?;

        // DEV preview location
        _devStateId = dev['stateId'] as String?;
        _devMetroId = dev['metroId'] as String?;
        _devAreaId = dev['areaId'] as String?;

        _pushEnabled = (noti['pushEnabled'] ?? _pushEnabled) as bool;
        _defaultAudienceScope =
            (noti['defaultAudienceScope'] ?? _defaultAudienceScope) as String;
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

          // LIVE default location (for real users)
          Text('Default Location (Live)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildLocationPicker(
            context: context,
            labelPrefix: '',
            stateId: _defaultStateId,
            metroId: _defaultMetroId,
            areaId: _defaultAreaId,
            onStateChanged: (v) {
              setState(() {
                _defaultStateId = v;
                _defaultMetroId = null;
                _defaultAreaId = null;
              });
            },
            onMetroChanged: (v) {
              setState(() {
                _defaultMetroId = v;
                _defaultAreaId = null;
              });
            },
            onAreaChanged: (v) {
              setState(() {
                _defaultAreaId = v;
              });
            },
          ),

          const SizedBox(height: 16),

          // DEV-ONLY section
          if (kDebugMode) ...[
            const Divider(),
            Text('Developer Tools (Dev Only)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'These settings only affect development and can be used to '
              'preview the app as if you were in a different State / Metro / Area.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildLocationPicker(
              context: context,
              labelPrefix: 'Dev ',
              stateId: _devStateId,
              metroId: _devMetroId,
              areaId: _devAreaId,
              onStateChanged: (v) {
                setState(() {
                  _devStateId = v;
                  _devMetroId = null;
                  _devAreaId = null;
                });
              },
              onMetroChanged: (v) {
                setState(() {
                  _devMetroId = v;
                  _devAreaId = null;
                });
              },
              onAreaChanged: (v) {
                setState(() {
                  _devAreaId = v;
                });
              },
            ),
            const SizedBox(height: 8),
          ],

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

          // Default Audience Scope
          DropdownButtonFormField<String>(
            value: _defaultAudienceScope,
            decoration: const InputDecoration(
              labelText: 'Default Push Audience Scope',
              helperText:
                  'Based on the default State / Metro / Area selected above',
            ),
            items: const [
              DropdownMenuItem(
                value: 'area',
                child: Text('Default Area only'),
              ),
              DropdownMenuItem(
                value: 'metro',
                child: Text('Whole Metro (all areas)'),
              ),
              DropdownMenuItem(
                value: 'state',
                child: Text('Whole State (all metros)'),
              ),
              DropdownMenuItem(
                value: 'all',
                child: Text('All users / all locations'),
              ),
            ],
            onChanged: (v) => setState(
                () => _defaultAudienceScope = v ?? _defaultAudienceScope),
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

  /// Reusable location picker: State → Metro → Area
  Widget _buildLocationPicker({
    required BuildContext context,
    required String labelPrefix,
    required String? stateId,
    required String? metroId,
    required String? areaId,
    required ValueChanged<String?> onStateChanged,
    required ValueChanged<String?> onMetroChanged,
    required ValueChanged<String?> onAreaChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // State
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _statesRef.orderBy('name').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Text(
                'No states configured yet. Add one in Admin • Locations.',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }

            return DropdownButtonFormField<String>(
              value: stateId,
              decoration: InputDecoration(labelText: '${labelPrefix}State'),
              items: docs
                  .map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.data()['name'] as String? ?? d.id),
                      ))
                  .toList(),
              onChanged: onStateChanged,
            );
          },
        ),
        const SizedBox(height: 8),

        // Metro (depends on State)
        if (stateId != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _statesRef
                .doc(stateId)
                .collection('metros')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text(
                  'No metros yet under this state.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }

              return DropdownButtonFormField<String>(
                value: metroId,
                decoration: InputDecoration(labelText: '${labelPrefix}Metro'),
                items: docs
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.data()['name'] as String? ?? d.id),
                        ))
                    .toList(),
                onChanged: onMetroChanged,
              );
            },
          ),
        if (stateId != null) const SizedBox(height: 8),

        // Area (depends on Metro)
        if (stateId != null && metroId != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _statesRef
                .doc(stateId)
                .collection('metros')
                .doc(metroId)
                .collection('areas')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Text(
                  'No areas yet under this metro.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }

              return DropdownButtonFormField<String>(
                value: areaId,
                decoration: InputDecoration(labelText: '${labelPrefix}Area'),
                items: docs
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.data()['name'] as String? ?? d.id),
                        ))
                    .toList(),
                onChanged: onAreaChanged,
              );
            },
          ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _configRef.set({
        'app': {
          'name': _appNameCtrl.text.trim(),
          'themeMode': _themeMode,
          'forceUpdate': _forceUpdate,
          'defaultLocation': {
            'stateId': _defaultStateId,
            'metroId': _defaultMetroId,
            'areaId': _defaultAreaId,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'notifications': {
          'pushEnabled': _pushEnabled,
          'defaultAudienceScope': _defaultAudienceScope,
          'weeklyEmailDigest': _weeklyEmailDigest,
          'emergencyMode': _emergencyMode,
          'emergencyMessage': _emergencyMsgCtrl.text.trim(),
        },
        'data': {
          'autoArchiveEvents': _autoArchiveEvents,
        },
        // 👇 DEV-only preview location (safe to ignore in prod)
        'dev': {
          'stateId': _devStateId,
          'metroId': _devMetroId,
          'areaId': _devAreaId,
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
