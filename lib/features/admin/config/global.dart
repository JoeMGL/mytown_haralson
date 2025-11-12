import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore path: /admin/config/global
final _configDoc = FirebaseFirestore.instance
    .collection('admin')
    .doc('config')
    .collection('meta')
    .doc('global');
// (Using /admin/config/global is fine too; pick one path and keep it consistent.)

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // --- Local state mirrors Firestore fields ---
  String appName = 'Visit Haralson County';
  String defaultCity = 'County-wide';
  String themeMode = 'system'; // system | light | dark
  bool forceUpdate = false;

  bool pushEnabled = true;
  String defaultPushAudience = 'County-wide';
  bool weeklyEmailDigest = false;
  bool emergencyMode = false;
  String emergencyMessage = 'Emergency alert mode enabled.';

  bool autoArchiveEvents = true;

  List<String> cities = const [
    'County-wide',
    'Tallapoosa',
    'Bremen',
    'Buchanan',
    'Waco'
  ];

  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      await _configDoc.set({
        'app': {
          'name': appName,
          'defaultCity': defaultCity,
          'themeMode': themeMode,
          'forceUpdate': forceUpdate,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'notifications': {
          'pushEnabled': pushEnabled,
          'defaultAudience': defaultPushAudience,
          'weeklyEmailDigest': weeklyEmailDigest,
          'emergencyMode': emergencyMode,
          'emergencyMessage': emergencyMessage,
        },
        'data': {
          'autoArchiveEvents': autoArchiveEvents,
        },
        'ui': {
          // keys here can drive homepage/order/featured in future iterations
          'featuredEnabled': true,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadFrom(Map<String, dynamic> data) {
    final app = (data['app'] ?? {}) as Map<String, dynamic>;
    final noti = (data['notifications'] ?? {}) as Map<String, dynamic>;
    final dta = (data['data'] ?? {}) as Map<String, dynamic>;

    appName = (app['name'] ?? appName) as String;
    defaultCity = (app['defaultCity'] ?? defaultCity) as String;
    themeMode = (app['themeMode'] ?? themeMode) as String;
    forceUpdate = (app['forceUpdate'] ?? forceUpdate) as bool;

    pushEnabled = (noti['pushEnabled'] ?? pushEnabled) as bool;
    defaultPushAudience =
        (noti['defaultAudience'] ?? defaultPushAudience) as String;
    weeklyEmailDigest =
        (noti['weeklyEmailDigest'] ?? weeklyEmailDigest) as bool;
    emergencyMode = (noti['emergencyMode'] ?? emergencyMode) as bool;
    emergencyMessage = (noti['emergencyMessage'] ?? emergencyMessage) as String;

    autoArchiveEvents = (dta['autoArchiveEvents'] ?? autoArchiveEvents) as bool;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _configDoc.snapshots(),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.data() != null) {
            _loadFrom(snap.data!.data()!);
          }
          return AbsorbPointer(
            absorbing: _loading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ============ App Configuration ============
                  _Section(
                    title: 'App Configuration',
                    children: [
                      TextFormField(
                        initialValue: appName,
                        decoration: const InputDecoration(
                          labelText: 'App Display Name',
                          helperText: 'Shown in headers/footers where used',
                        ),
                        onSaved: (v) => appName =
                            v?.trim().isNotEmpty == true ? v!.trim() : appName,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: defaultCity,
                        items: cities
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => defaultCity = v ?? defaultCity),
                        decoration:
                            const InputDecoration(labelText: 'Default City'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: themeMode,
                        items: const [
                          DropdownMenuItem(
                              value: 'system', child: Text('System')),
                          DropdownMenuItem(
                              value: 'light', child: Text('Light')),
                          DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        ],
                        onChanged: (v) =>
                            setState(() => themeMode = v ?? themeMode),
                        decoration:
                            const InputDecoration(labelText: 'Theme Mode'),
                      ),
                      SwitchListTile(
                        value: forceUpdate,
                        onChanged: (v) => setState(() => forceUpdate = v),
                        title: const Text('Force Update'),
                        subtitle: const Text(
                            'Require users to update to the latest app version'),
                      ),
                    ],
                  ),

                  // ============ Notifications ============
                  _Section(
                    title: 'Notifications & Communication',
                    children: [
                      SwitchListTile(
                        value: pushEnabled,
                        onChanged: (v) => setState(() => pushEnabled = v),
                        title: const Text('Enable Push Notifications'),
                      ),
                      DropdownButtonFormField<String>(
                        value: defaultPushAudience,
                        items: cities
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() =>
                            defaultPushAudience = v ?? defaultPushAudience),
                        decoration: const InputDecoration(
                            labelText: 'Default Push Audience'),
                      ),
                      SwitchListTile(
                        value: weeklyEmailDigest,
                        onChanged: (v) => setState(() => weeklyEmailDigest = v),
                        title: const Text('Weekly Email Digest'),
                        subtitle: const Text(
                            'Send weekly round-up of new events/attractions'),
                      ),
                      SwitchListTile(
                        value: emergencyMode,
                        onChanged: (v) => setState(() => emergencyMode = v),
                        title: const Text('Emergency Alert Mode'),
                        subtitle:
                            const Text('Show banner and allow urgent alerts'),
                      ),
                      TextFormField(
                        initialValue: emergencyMessage,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Message',
                          helperText: 'Displayed when Emergency Mode is on',
                        ),
                        maxLines: 2,
                        onSaved: (v) => emergencyMessage =
                            v?.trim().isNotEmpty == true
                                ? v!.trim()
                                : emergencyMessage,
                      ),
                    ],
                  ),

                  // ============ Data Management ============
                  _Section(
                    title: 'Data Management',
                    children: [
                      SwitchListTile(
                        value: autoArchiveEvents,
                        onChanged: (v) => setState(() => autoArchiveEvents = v),
                        title: const Text('Auto-Archive Past Events'),
                        subtitle: const Text(
                            'Automatically archive events after their end date'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ChipButton(
                            icon: Icons.download_outlined,
                            label: 'Export JSON',
                            onTap: () {
                              // TODO: Implement export logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Export not implemented yet')),
                              );
                            },
                          ),
                          _ChipButton(
                            icon: Icons.upload_outlined,
                            label: 'Import JSON',
                            onTap: () {
                              // TODO: Implement import logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Import not implemented yet')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ============ Access Control (stub) ============
                  _Section(
                    title: 'Access Control',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people_outline),
                        title: const Text('Manage Admins & City Roles'),
                        subtitle: const Text(
                            'Add/remove admins, assign Tallapoosa/Bremen-only permissions'),
                        onTap: () {
                          // Navigate to your admin/roles page if you have one
                          // context.push('/admin/settings/roles');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Roles page not implemented yet')),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 96),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _save,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save_outlined),
        label: Text(_loading ? 'Saving…' : 'Save Changes'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
