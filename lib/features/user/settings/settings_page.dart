// lib/features/settings/settings_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Location prefs (backed by Firestore) ---
  String? _stateId;
  String? _metroId;
  String? _areaId;

  bool _loadingLocation = true;
  bool _savingLocation = false;

  // Other location-related prefs (local for now)
  String _defaultSection = 'home';
  bool _useDeviceLocation = true;

  // Notifications
  bool _notifGeneral = true;
  bool _notifEvents = true;
  bool _notifEatDrink = false;
  bool _notifClubs = false;
  bool _notifSavedPlaces = true;

  // Appearance
  String _theme = 'system'; // 'system' | 'light' | 'dark'
  bool _largeText = false;
  bool _highContrast = false;

  // Privacy
  bool _analyticsOptIn = true;

  // Firestore references (match AdminSettingsPage)
  CollectionReference<Map<String, dynamic>> get _statesRef =>
      FirebaseFirestore.instance.collection('states');

  DocumentReference<Map<String, dynamic>> get _configRef =>
      FirebaseFirestore.instance
          .collection('admin')
          .doc('config')
          .collection('meta')
          .doc('global');

  @override
  void initState() {
    super.initState();
    _loadLocationFromConfig();
  }

  Future<void> _loadLocationFromConfig() async {
    try {
      final snap = await _configRef.get();
      final data = snap.data();
      if (data != null) {
        final app = (data['app'] ?? {}) as Map<String, dynamic>;
        final loc = (app['defaultLocation'] ?? {}) as Map<String, dynamic>;

        _stateId = loc['stateId'] as String?;
        _metroId = loc['metroId'] as String?;
        _areaId = loc['areaId'] as String?;
      }
    } catch (e) {
      // Non-fatal: leave as null
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // AppShell wraps this, so this Scaffold is only providing the body.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👤 Account
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Joe Glass'),
                  subtitle: Text('Signed in user (placeholder)'),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('View my favorites'),
                  onTap: () {
                    context.go('/favorites');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 📍 Location
          Text('Location Preferences',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loadingLocation) const LinearProgressIndicator(),
                  if (!_loadingLocation) _buildLocationPicker(context),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.explore_outlined),
                    title: const Text('Default section on launch'),
                    contentPadding: EdgeInsets.zero,
                    trailing: DropdownButton<String>(
                      value: _defaultSection,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'home',
                          child: Text('Home'),
                        ),
                        DropdownMenuItem(
                          value: 'explore',
                          child: Text('Explore'),
                        ),
                        DropdownMenuItem(
                          value: 'eat',
                          child: Text('Eat & Drink'),
                        ),
                        DropdownMenuItem(
                          value: 'events',
                          child: Text('Events'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _defaultSection = val);
                      },
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.my_location_outlined),
                    title: const Text('Use device location when available'),
                    value: _useDeviceLocation,
                    onChanged: (val) {
                      setState(() => _useDeviceLocation = val);
                    },
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: (_stateId == null ||
                              _metroId == null ||
                              _savingLocation)
                          ? null
                          : _saveLocation,
                      icon: _savingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label:
                          Text(_savingLocation ? 'Saving...' : 'Save location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 🔔 Notifications
          Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('General announcements'),
                  value: _notifGeneral,
                  onChanged: (v) => setState(() => _notifGeneral = v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.event_outlined),
                  title: const Text('Events near me'),
                  value: _notifEvents,
                  onChanged: (v) => setState(() => _notifEvents = v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.restaurant_outlined),
                  title: const Text('Eat & Drink specials'),
                  value: _notifEatDrink,
                  onChanged: (v) => setState(() => _notifEatDrink = v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.groups_2_outlined),
                  title: const Text('Clubs & Groups updates'),
                  value: _notifClubs,
                  onChanged: (v) => setState(() => _notifClubs = v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.favorite_outline),
                  title: const Text('My saved places'),
                  value: _notifSavedPlaces,
                  onChanged: (v) => setState(() => _notifSavedPlaces = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🎨 Appearance
          Text('Appearance & Accessibility',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(_themeLabel(_theme)),
                  onTap: () async {
                    final choice = await showModalBottomSheet<String>(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('System default'),
                            onTap: () => Navigator.pop(ctx, 'system'),
                          ),
                          ListTile(
                            title: const Text('Light'),
                            onTap: () => Navigator.pop(ctx, 'light'),
                          ),
                          ListTile(
                            title: const Text('Dark'),
                            onTap: () => Navigator.pop(ctx, 'dark'),
                          ),
                        ],
                      ),
                    );
                    if (choice != null) {
                      setState(() => _theme = choice);
                    }
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.format_size_outlined),
                  title: const Text('Larger text'),
                  value: _largeText,
                  onChanged: (v) => setState(() => _largeText = v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.contrast_outlined),
                  title: const Text('High contrast mode'),
                  value: _highContrast,
                  onChanged: (v) => setState(() => _highContrast = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🔏 Privacy & About
          Text('Privacy & About',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.bar_chart_outlined),
                  title: const Text('Allow anonymous usage analytics'),
                  value: _analyticsOptIn,
                  onChanged: (v) => setState(() => _analyticsOptIn = v),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear local cache'),
                  onTap: () {
                    // TODO: implement cache clearing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Local cache cleared (placeholder).'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_outlined),
                  title: const Text('Reset settings to default'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset settings'),
                        content: const Text(
                            'Are you sure you want to reset all settings?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _resetSettings();
                    }
                  },
                ),
                const Divider(height: 0),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic State → Metro → Area picker using the same structure
  /// as AdminSettingsPage.
  Widget _buildLocationPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STATE
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
              value: _stateId,
              decoration: const InputDecoration(labelText: 'State'),
              items: docs
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(d.data()['name'] as String? ?? d.id),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _stateId = value;
                  _metroId = null;
                  _areaId = null;
                });
              },
            );
          },
        ),
        const SizedBox(height: 8),

        // METRO
        if (_stateId != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _statesRef
                .doc(_stateId)
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
                value: _metroId,
                decoration: const InputDecoration(labelText: 'Metro'),
                items: docs
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.data()['name'] as String? ?? d.id),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _metroId = value;
                    _areaId = null;
                  });
                },
              );
            },
          ),
        if (_stateId != null) const SizedBox(height: 8),

        // AREA
        if (_stateId != null && _metroId != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _statesRef
                .doc(_stateId)
                .collection('metros')
                .doc(_metroId)
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
                value: _areaId,
                decoration: const InputDecoration(labelText: 'Area'),
                items: docs
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.data()['name'] as String? ?? d.id),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _areaId = value;
                  });
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _saveLocation() async {
    if (_stateId == null || _metroId == null) return;

    setState(() => _savingLocation = true);
    try {
      await _configRef.set(
        {
          'app': {
            'defaultLocation': {
              'stateId': _stateId,
              'metroId': _metroId,
              'areaId': _areaId,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default location updated ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingLocation = false);
      }
    }
  }

  String _themeLabel(String v) {
    switch (v) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  void _resetSettings() {
    setState(() {
      // Location: reset to "unset" – next app load will pick up whatever
      // is in Firestore again.
      _stateId = null;
      _metroId = null;
      _areaId = null;
      _defaultSection = 'home';
      _useDeviceLocation = true;

      _notifGeneral = true;
      _notifEvents = true;
      _notifEatDrink = false;
      _notifClubs = false;
      _notifSavedPlaces = true;

      _theme = 'system';
      _largeText = false;
      _highContrast = false;

      _analyticsOptIn = true;
    });
  }
}
