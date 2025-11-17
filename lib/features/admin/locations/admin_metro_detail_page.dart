import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/models/locations/metro.dart';

class AdminMetroDetailPage extends StatefulWidget {
  const AdminMetroDetailPage({
    super.key,
    required this.metro,
  });

  final Metro metro;

  @override
  State<AdminMetroDetailPage> createState() => _AdminMetroDetailPageState();
}

class _AdminMetroDetailPageState extends State<AdminMetroDetailPage> {
  final _formKey = GlobalKey<FormState>();

  // General fields
  late TextEditingController _nameCtrl;
  late TextEditingController _slugCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _heroCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  bool _isActive = true;
  bool _saving = false;

  // Firestore refs
  late final DocumentReference<Map<String, dynamic>> _metroDocRef;
  late final CollectionReference<Map<String, dynamic>> _bannersRef;

  @override
  void initState() {
    super.initState();

    _metroDocRef = FirebaseFirestore.instance
        .collection('states')
        .doc(widget.metro.stateId)
        .collection('metros')
        .doc(widget.metro.id);

    _bannersRef = _metroDocRef.collection('banners');

    _nameCtrl = TextEditingController(text: widget.metro.name);
    _slugCtrl = TextEditingController(text: widget.metro.slug);
    _taglineCtrl = TextEditingController(text: widget.metro.tagline ?? '');
    _heroCtrl = TextEditingController(text: widget.metro.heroImageUrl ?? '');

    // If you eventually store center as GeoPoint on the doc:
    // We'll load lat/lng from snapshot instead of from the Metro model
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();

    _isActive = widget.metro.isActive;

    _loadCenterFromDoc();
  }

  Future<void> _loadCenterFromDoc() async {
    final snap = await _metroDocRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;

    final center = data['center'];
    if (center is GeoPoint) {
      _latCtrl.text = center.latitude.toStringAsFixed(6);
      _lngCtrl.text = center.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _taglineCtrl.dispose();
    _heroCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGeneral() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      var slug = _slugCtrl.text.trim();
      final tagline = _taglineCtrl.text.trim();
      final hero = _heroCtrl.text.trim();

      if (slug.isEmpty) {
        slug = name.toLowerCase().replaceAll(' ', '-');
      }

      double? lat;
      double? lng;

      if (_latCtrl.text.trim().isNotEmpty && _lngCtrl.text.trim().isNotEmpty) {
        lat = double.tryParse(_latCtrl.text.trim());
        lng = double.tryParse(_lngCtrl.text.trim());
      }

      final updateData = <String, dynamic>{
        'name': name,
        'slug': slug,
        'tagline': tagline.isEmpty ? null : tagline,
        'heroImageUrl': hero.isEmpty ? null : hero,
        'isActive': _isActive,
      };

      if (lat != null && lng != null) {
        updateData['center'] = GeoPoint(lat, lng);
      }

      await _metroDocRef.update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metro settings saved ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save metro: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addOrEditBanner(
      {DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final isEditing = doc != null;
    final data = doc?.data();

    final titleCtrl = TextEditingController(text: data?['title'] ?? '');
    final imageCtrl = TextEditingController(text: data?['imageUrl'] ?? '');
    final linkCtrl = TextEditingController(text: data?['linkUrl'] ?? '');
    final sortOrderCtrl = TextEditingController(
      text: (data?['sortOrder'] ?? 0).toString(),
    );
    bool isActive = data?['isActive'] ?? true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Banner' : 'Add Banner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Summer in Atlanta',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'https://example.com/banner.jpg',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link URL (optional)',
                        hintText: '/events/summer-fest or https://...',
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
                      onChanged: (v) => setLocalState(() => isActive = v),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () async {
                      // delete
                      await doc!.reference.delete();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final image = imageCtrl.text.trim();
                    final link = linkCtrl.text.trim();
                    final sortText = sortOrderCtrl.text.trim();
                    int sortOrder = 0;
                    if (sortText.isNotEmpty) {
                      final parsed = int.tryParse(sortText);
                      if (parsed != null) sortOrder = parsed;
                    }

                    if (title.isEmpty || image.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and Image URL are required.'),
                        ),
                      );
                      return;
                    }

                    final bannerData = <String, dynamic>{
                      'title': title,
                      'imageUrl': image,
                      'linkUrl': link.isEmpty ? null : link,
                      'sortOrder': sortOrder,
                      'isActive': isActive,
                    };

                    try {
                      if (isEditing) {
                        await doc!.reference.update(bannerData);
                      } else {
                        bannerData['createdAt'] = FieldValue.serverTimestamp();
                        await _bannersRef.add(bannerData);
                      }

                      if (!mounted) return;
                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save banner: $e'),
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Metro • ${widget.metro.name}'),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'General'),
                      Tab(text: 'Banners'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGeneralTab(),
                        _buildBannersTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General Settings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Metro Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _slugCtrl,
              decoration: const InputDecoration(
                labelText: 'Slug',
                helperText: 'Auto-generated from name if left empty',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _taglineCtrl,
              decoration: const InputDecoration(
                labelText: 'Tagline (optional)',
                hintText: 'e.g. Explore Atlanta & beyond',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _heroCtrl,
              decoration: const InputDecoration(
                labelText: 'Hero / Banner Image URL (optional)',
              ),
            ),
            const SizedBox(height: 16),
            Text('Map Center (GPS)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '33.7488',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '-84.3877',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveGeneral,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannersTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addOrEditBanner(),
              icon: const Icon(Icons.add),
              label: const Text('Add Banner'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _bannersRef.orderBy('sortOrder').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No banners yet. Add your first one.'),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data();
                  final title = data['title'] ?? '';
                  final imageUrl = data['imageUrl'] ?? '';
                  final linkUrl = data['linkUrl'] ?? '';
                  final sortOrder = data['sortOrder'] ?? 0;
                  final isActive = data['isActive'] ?? true;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(sortOrder.toString()),
                    ),
                    title: Text(title),
                    subtitle: Text(
                      [
                        if (isActive) 'Active' else 'Inactive',
                        if (linkUrl != null && linkUrl.toString().isNotEmpty)
                          linkUrl.toString(),
                      ].join(' • '),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _addOrEditBanner(doc: d),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
