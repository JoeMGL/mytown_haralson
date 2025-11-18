import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/clubs_model.dart';
import '../../../models/category.dart';
import '/core/location/location_provider.dart'; // same as HomePage

/// Must match the `section` value used for clubs in your categories docs.
const String kClubsSectionSlug = 'clubs';

class ClubsPage extends ConsumerStatefulWidget {
  const ClubsPage({super.key});

  @override
  ConsumerState<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends ConsumerState<ClubsPage> {
  // Filters
  String _areaFilter = 'All Areas';
  String _category = 'All';

  // Dynamic categories
  List<Category> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;

  // Dynamic areas (from states/{stateId}/metros/{metroId}/areas)
  List<String> _areaNames = [];
  bool _loadingAreas = true;
  String? _areasError;
  String? _loadedAreasForMetroId; // to avoid reloading unnecessarily

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ─────────────────────────────
  // 🔹 Load categories for Clubs section
  // ─────────────────────────────
  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kClubsSectionSlug)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      final cats = snap.docs.map((d) => Category.fromDoc(d)).toList();

      setState(() {
        _categories = cats;
        _loadingCategories = false;
        _categoriesError = null;

        final names = _categories.map((c) => c.name).toList();
        if (_category != 'All' && !names.contains(_category)) {
          _category = 'All';
        }
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
        _categoriesError = 'Error loading categories: $e';
      });
    }
  }

  // ─────────────────────────────
  // 🔹 Load areas for current state / metro
  // ─────────────────────────────
  Future<void> _loadAreasForLocation(String? stateId, String? metroId) async {
    if (stateId == null || metroId == null) {
      setState(() {
        _areaNames = [];
        _loadingAreas = false;
        _areasError = null;
        _areaFilter = 'All Areas';
        _loadedAreasForMetroId = null;
      });
      return;
    }

    // Avoid reloading if we already loaded for this metro
    if (_loadedAreasForMetroId == metroId && !_loadingAreas) return;

    setState(() {
      _loadingAreas = true;
      _areasError = null;
      _loadedAreasForMetroId = metroId;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('metros')
          .doc(metroId)
          .collection('areas')
          .orderBy('name')
          .get();

      final names = snap.docs
          .map((d) => (d.data()['name'] as String?)?.trim())
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();

      setState(() {
        _areaNames = names;
        _loadingAreas = false;
        _areasError = null;

        if (_areaFilter != 'All Areas' && !_areaNames.contains(_areaFilter)) {
          _areaFilter = 'All Areas';
        }
      });
    } catch (e) {
      setState(() {
        _loadingAreas = false;
        _areasError = 'Error loading areas: $e';
        _areaNames = [];
        _areaFilter = 'All Areas';
      });
    }
  }

  String _buildAddress(Club club) {
    final line1 = club.street.trim();
    final city = club.city.trim();
    final state = club.state.trim();
    final zip = club.zip.trim();

    final line2Parts = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (zip.isNotEmpty) zip,
    ];
    final line2 = line2Parts.join(', ');

    if (line1.isEmpty && line2.isEmpty) {
      // fallback to legacy combined address if present
      return club.address;
    }
    if (line1.isNotEmpty && line2.isNotEmpty) {
      return '$line1, $line2';
    }
    return line1.isNotEmpty ? line1 : line2;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Clubs & Groups'),
        ),
        body: Center(child: Text('Error loading location: $e')),
      ),
      data: (loc) {
        final stateId = loc.stateId;
        final metroId = loc.metroId;

        // 🔄 Make sure areas are loaded for current metro
        _loadAreasForLocation(stateId, metroId);

        // Base query: only active clubs
        Query<Map<String, dynamic>> clubsQuery = FirebaseFirestore.instance
            .collection('clubs')
            .where('active', isEqualTo: true);

        // If a metro is configured (including dev override), only show that metro
        if (stateId != null && metroId != null) {
          clubsQuery = clubsQuery.where('metroId', isEqualTo: metroId);
        }

        // Area filter (using areaName stored on the club)
        if (_areaFilter != 'All Areas') {
          clubsQuery = clubsQuery.where('areaName', isEqualTo: _areaFilter);
        }

        // Category filter (match the *name* we store in Firestore)
        if (_category != 'All') {
          clubsQuery = clubsQuery.where('category', isEqualTo: _category);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Clubs & Groups'),
          ),
          body: Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Area filter using chips
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _loadingAreas
                          ? const SizedBox(
                              height: 36,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : _areasError != null
                              ? Text(
                                  _areasError!,
                                  style: TextStyle(color: cs.error),
                                )
                              : SizedBox(
                                  height: 40,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: const Text("All Areas"),
                                          selected: _areaFilter == "All Areas",
                                          onSelected: (_) {
                                            setState(() =>
                                                _areaFilter = "All Areas");
                                          },
                                        ),
                                      ),
                                      ..._areaNames.map(
                                        (name) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            label: Text(name),
                                            selected: _areaFilter == name,
                                            onSelected: (_) {
                                              setState(
                                                  () => _areaFilter = name);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),

                    // 🔹 Category dropdown (dynamic)
                    if (_loadingCategories) ...[
                      const Row(
                        children: [
                          Text('Category'),
                          SizedBox(width: 12),
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ),
                    ] else if (_categoriesError != null) ...[
                      Text(
                        _categoriesError!,
                        style: TextStyle(color: cs.error),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All'),
                          ),
                          ..._categories.map(
                            (c) => DropdownMenuItem<String>(
                              value: c.name,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // List of clubs
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: clubsQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading clubs: ${snapshot.error}'),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No clubs or groups match your filters.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final club = Club.fromFirestore(docs[index]);
                        final address = _buildAddress(club);
                        final hasImages = club.imageUrls.isNotEmpty;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: _ClubThumbnail(club: club),
                            title: Text(
                              club.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (address.isNotEmpty) address,
                                    if (club.category.isNotEmpty) club.category,
                                  ].join(' • '),
                                ),
                                if (club.meetingSchedule.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      club.meetingSchedule,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                if (hasImages)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${club.imageUrls.length} photo(s)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              GoRouter.of(context).pushNamed(
                                'clubDetail',
                                extra: club,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          backgroundColor: cs.surface,
        );
      },
    );
  }
}

class _ClubThumbnail extends StatelessWidget {
  const _ClubThumbnail({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final banner = club.bannerImageUrl;

    if (banner.isEmpty) {
      return CircleAvatar(
        backgroundColor: cs.surfaceVariant,
        child: const Icon(Icons.group),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          banner,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: cs.surfaceVariant,
              child: const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }
}
