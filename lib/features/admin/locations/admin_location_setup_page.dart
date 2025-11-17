import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🧭 Adjust these relative paths if needed based on where this file lives
import '/models/locations/state.dart';
import '/models/locations/metro.dart';
import '/models/locations/area.dart';

// 👇 NEW – import your metro details page
import '/features/admin/locations/admin_metro_detail_page.dart';

class AdminLocationSetupPage extends StatefulWidget {
  const AdminLocationSetupPage({super.key});

  @override
  State<AdminLocationSetupPage> createState() => _AdminLocationSetupPageState();
}

class _AdminLocationSetupPageState extends State<AdminLocationSetupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Firestore reference
  final CollectionReference<Map<String, dynamic>> statesRef =
      FirebaseFirestore.instance.collection('states');

  // Controllers
  final TextEditingController _metroNameCtrl = TextEditingController();
  final TextEditingController _metroTaglineCtrl = TextEditingController();
  final TextEditingController _metroHeroImageCtrl = TextEditingController();

  final TextEditingController _stateNameCtrl = TextEditingController();
  final TextEditingController _areaNameCtrl = TextEditingController();

  // Area type
  String _areaType = 'city';

  // Dropdown selections
  String? _selectedStateIdForMetro;
  String? _selectedStateIdForArea;
  String? _selectedMetroIdForArea;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);

    // Update button enabled state as user types
    _metroNameCtrl.addListener(() => setState(() {}));
    _stateNameCtrl.addListener(() => setState(() {}));
    _areaNameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _metroNameCtrl.dispose();
    _metroTaglineCtrl.dispose();
    _metroHeroImageCtrl.dispose();
    _stateNameCtrl.dispose();
    _areaNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Locations'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'States'),
            Tab(text: 'Metros'),
            Tab(text: 'Areas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildStatesTab(),
          _buildMetrosTab(),
          _buildAreasTab(),
        ],
      ),
    );
  }

  // -------------------------
  // TAB 1: STATES (uses StateModel)
  // -------------------------
  Widget _buildStatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _stateNameCtrl,
            decoration: const InputDecoration(
              labelText: 'State Name',
              hintText: 'e.g. Georgia, Alabama',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _stateNameCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final name = _stateNameCtrl.text.trim();
                      if (name.isEmpty) return;

                      try {
                        final slug = name.toLowerCase().replaceAll(' ', '-');

                        // Temporarily id = '' since Firestore assigns it
                        final state = StateModel(
                          id: '',
                          name: name,
                          slug: slug,
                          abbreviation: null,
                          heroImageUrl: null,
                          isActive: true,
                          sortOrder: 0,
                          timezone: null,
                        );

                        final data = state.toMap();
                        data['createdAt'] = FieldValue.serverTimestamp();

                        await statesRef.add(data);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('State "$name" added ✅')),
                        );

                        _stateNameCtrl.clear();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save state: $e')),
                        );
                      }
                    },
              child: const Text('Save State'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Existing States',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: statesRef
                  //.orderBy('sortOrder')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No states yet. Add your first above.');
                }

                final docs = snapshot.data!.docs;
                final states = docs.map((d) => StateModel.fromDoc(d)).toList();

                return ListView.separated(
                  itemCount: states.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = states[i];
                    final subtitleParts = <String>[];
                    if (s.abbreviation != null && s.abbreviation!.isNotEmpty) {
                      subtitleParts.add(s.abbreviation!);
                    }
                    subtitleParts.add(s.id);

                    return ListTile(
                      title: Text(s.name),
                      subtitle: Text(subtitleParts.join(' • ')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // TAB 2: METROS (MULTIPLE PER STATE) – uses Metro model
  // -------------------------
  Widget _buildMetrosTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State selector
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: statesRef.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'No states found. Add a state on the "States" tab first.',
                );
              }

              final docs = snapshot.data!.docs;
              final states = docs.map((d) => StateModel.fromDoc(d)).toList();

              return DropdownButtonFormField<String>(
                value: _selectedStateIdForMetro,
                decoration: const InputDecoration(labelText: 'Select State'),
                items: states
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedStateIdForMetro = v;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 12),

          // Metro name
          TextField(
            controller: _metroNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Metro Name',
              hintText: 'e.g. Atlanta Metro, Haralson County',
            ),
          ),
          const SizedBox(height: 8),

          // Optional tagline
          TextField(
            controller: _metroTaglineCtrl,
            decoration: const InputDecoration(
              labelText: 'Tagline (optional)',
              hintText: 'e.g. Explore Atlanta & beyond',
            ),
          ),
          const SizedBox(height: 8),

          // Optional hero / banner image URL
          TextField(
            controller: _metroHeroImageCtrl,
            decoration: const InputDecoration(
              labelText: 'Hero / Banner Image URL (optional)',
              hintText: 'https://example.com/banner.jpg',
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedStateIdForMetro == null ||
                      _metroNameCtrl.text.trim().isEmpty)
                  ? null
                  : () async {
                      final metroName = _metroNameCtrl.text.trim();
                      final tagline = _metroTaglineCtrl.text.trim();
                      final heroImage = _metroHeroImageCtrl.text.trim();
                      final stateId = _selectedStateIdForMetro;
                      if (metroName.isEmpty || stateId == null) return;

                      try {
                        final slug =
                            metroName.toLowerCase().replaceAll(' ', '-');

                        final metro = Metro(
                          id: '',
                          stateId: stateId,
                          name: metroName,
                          slug: slug,
                          tagline: tagline.isEmpty ? null : tagline,
                          heroImageUrl: heroImage.isEmpty ? null : heroImage,
                          isActive: true,
                          sortOrder: 0,
                        );

                        final data = metro.toMap();
                        data['createdAt'] = FieldValue.serverTimestamp();

                        await statesRef
                            .doc(stateId)
                            .collection('metros')
                            .add(data);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Metro "$metroName" added ✅')),
                        );

                        _metroNameCtrl.clear();
                        _metroTaglineCtrl.clear();
                        _metroHeroImageCtrl.clear();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save metro: $e')),
                        );
                      }
                    },
              child: const Text('Save Metro'),
            ),
          ),

          const SizedBox(height: 16),
          Text('Metros in Selected State',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Expanded(
            child: _selectedStateIdForMetro == null
                ? const Text('Select a state to view its metros.')
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: statesRef
                        .doc(_selectedStateIdForMetro)
                        .collection('metros')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                            'No metros yet for this state. Add one above.');
                      }

                      final docs = snapshot.data!.docs;
                      final metros = docs
                          .map((d) => Metro.fromDoc(
                                doc: d,
                                stateId: _selectedStateIdForMetro!,
                              ))
                          .toList();

                      return ListView.separated(
                        itemCount: metros.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final m = metros[i];

                          final subtitleParts = <String>[
                            m.slug,
                            if (m.tagline != null &&
                                m.tagline!.trim().isNotEmpty)
                              m.tagline!.trim(),
                            'id: ${m.id}',
                            'active: ${m.isActive ? 'yes' : 'no'}',
                            'sort: ${m.sortOrder}',
                          ];

                          return ListTile(
                            title: Text(m.name),
                            subtitle: Text(subtitleParts.join(' • ')),
                            // 👇 NEW: tap row → open Metro detail page
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminMetroDetailPage(
                                    metro: m,
                                  ),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Quick edit metro',
                              onPressed: () => _showEditMetroDialog(m),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditMetroDialog(Metro metro) async {
    final nameCtrl = TextEditingController(text: metro.name);
    final slugCtrl = TextEditingController(text: metro.slug);
    final taglineCtrl = TextEditingController(text: metro.tagline ?? '');
    final heroCtrl = TextEditingController(text: metro.heroImageUrl ?? '');
    final sortOrderCtrl =
        TextEditingController(text: metro.sortOrder.toString());

    bool isActive = metro.isActive;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Metro • ${metro.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Metro Name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: slugCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    helperText: 'Auto-generated from name if left empty',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: taglineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tagline (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heroCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hero / Banner Image URL (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    helperText: 'Lower numbers appear first',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) {
                    (context as Element).markNeedsBuild();
                    isActive = v;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                var slug = slugCtrl.text.trim();
                final tagline = taglineCtrl.text.trim();
                final hero = heroCtrl.text.trim();
                final sortOrderText = sortOrderCtrl.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                  return;
                }

                if (slug.isEmpty) {
                  slug = name.toLowerCase().replaceAll(' ', '-');
                }

                int sortOrder = metro.sortOrder;
                if (sortOrderText.isNotEmpty) {
                  final parsed = int.tryParse(sortOrderText);
                  if (parsed != null) sortOrder = parsed;
                }

                try {
                  await statesRef
                      .doc(metro.stateId)
                      .collection('metros')
                      .doc(metro.id)
                      .update({
                    'name': name,
                    'slug': slug,
                    'tagline': tagline.isEmpty ? null : tagline,
                    'heroImageUrl': hero.isEmpty ? null : hero,
                    'isActive': isActive,
                    'sortOrder': sortOrder,
                  });

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Metro "$name" updated ✅')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to update metro: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // -------------------------
  // TAB 3: AREAS (MULTIPLE PER METRO) – uses Area model
  // -------------------------
  Widget _buildAreasTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // State selector
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: statesRef.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'No states found. Add a state first on the "States" tab.',
                );
              }

              final docs = snapshot.data!.docs;
              final states = docs.map((d) => StateModel.fromDoc(d)).toList();

              return DropdownButtonFormField<String>(
                value: _selectedStateIdForArea,
                decoration: const InputDecoration(labelText: 'Select State'),
                items: states
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedStateIdForArea = v;
                    _selectedMetroIdForArea = null;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 12),

          // Metro selector (depends on state)
          if (_selectedStateIdForArea != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: statesRef
                  .doc(_selectedStateIdForArea)
                  .collection('metros')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    'No metros found for this state. Add one on the "Metros" tab.',
                  );
                }

                final docs = snapshot.data!.docs;
                final metros = docs
                    .map((d) => Metro.fromDoc(
                          doc: d,
                          stateId: _selectedStateIdForArea!,
                        ))
                    .toList();

                return DropdownButtonFormField<String>(
                  value: _selectedMetroIdForArea,
                  decoration: const InputDecoration(labelText: 'Select Metro'),
                  items: metros
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedMetroIdForArea = v;
                    });
                  },
                );
              },
            ),
          if (_selectedStateIdForArea != null) const SizedBox(height: 12),

          TextField(
            controller: _areaNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Area Name',
              hintText: 'e.g. Austell, Woodstock, Downtown, Tallapoosa',
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _areaType,
            decoration: const InputDecoration(labelText: 'Area Type'),
            items: const [
              DropdownMenuItem(value: 'city', child: Text('City')),
              DropdownMenuItem(value: 'town', child: Text('Town')),
              DropdownMenuItem(value: 'suburb', child: Text('Suburb')),
              DropdownMenuItem(
                value: 'neighborhood',
                child: Text('Neighborhood'),
              ),
            ],
            onChanged: (v) => setState(() => _areaType = v ?? _areaType),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedStateIdForArea == null ||
                      _selectedMetroIdForArea == null ||
                      _areaNameCtrl.text.trim().isEmpty)
                  ? null
                  : () async {
                      final stateId = _selectedStateIdForArea;
                      final metroId = _selectedMetroIdForArea;
                      final areaName = _areaNameCtrl.text.trim();
                      if (stateId == null ||
                          metroId == null ||
                          areaName.isEmpty) return;

                      try {
                        final slug =
                            areaName.toLowerCase().replaceAll(' ', '-');

                        final area = Area(
                          id: '',
                          stateId: stateId,
                          metroId: metroId,
                          name: areaName,
                          slug: slug,
                          type: _areaType,
                          tagline: null,
                          heroImageUrl: null,
                          isActive: true,
                          sortOrder: 0,
                        );

                        final data = area.toMap();
                        data['createdAt'] = FieldValue.serverTimestamp();

                        await statesRef
                            .doc(stateId)
                            .collection('metros')
                            .doc(metroId)
                            .collection('areas')
                            .add(data);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Area "$areaName" added ✅')),
                        );

                        _areaNameCtrl.clear();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save area: $e')),
                        );
                      }
                    },
              child: const Text('Save Area'),
            ),
          ),

          const SizedBox(height: 16),
          Text('Areas in Selected Metro',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Expanded(
            child: (_selectedStateIdForArea == null ||
                    _selectedMetroIdForArea == null)
                ? const Text(
                    'Select a state and metro to view its areas.',
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: statesRef
                        .doc(_selectedStateIdForArea)
                        .collection('metros')
                        .doc(_selectedMetroIdForArea)
                        .collection('areas')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                            'No areas yet for this metro. Add one above.');
                      }

                      final docs = snapshot.data!.docs;
                      final areas = docs
                          .map(
                            (d) => Area.fromDoc(
                              doc: d,
                              stateId: _selectedStateIdForArea!,
                              metroId: _selectedMetroIdForArea!,
                            ),
                          )
                          .toList();

                      return ListView.separated(
                        itemCount: areas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final a = areas[i];
                          return ListTile(
                            title: Text(a.name),
                            subtitle: Text('${a.type} • ${a.id}'),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
