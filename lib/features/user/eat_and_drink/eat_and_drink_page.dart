import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/eat_and_drink.dart';
import '/core/location/location_provider.dart';

class EatAndDrinkPage extends ConsumerStatefulWidget {
  const EatAndDrinkPage({super.key});

  @override
  ConsumerState<EatAndDrinkPage> createState() => _EatAndDrinkPageState();
}

// Simple helper for area options
class _AreaOption {
  final String id; // '' or 'all' for All
  final String name;

  const _AreaOption({required this.id, required this.name});
}

// Helper for category options (slug + label)
class _CategoryOption {
  final String slug; // 'all' for All
  final String label;

  const _CategoryOption({required this.slug, required this.label});
}

class _EatAndDrinkPageState extends ConsumerState<EatAndDrinkPage> {
  // Area filter (by ID)
  String _selectedAreaId = 'all';
  List<_AreaOption> _areas = const [
    _AreaOption(id: 'all', name: 'All Areas'),
  ];
  bool _loadingAreas = true;

  // Category filter (by SLUG)
  String _selectedCategorySlug = 'all';
  List<_CategoryOption> _categories = const [
    _CategoryOption(slug: 'all', label: 'All'),
  ];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: 'eatAndDrink')
          .orderBy('sortOrder')
          .get();

      final options = <_CategoryOption>[
        const _CategoryOption(slug: 'all', label: 'All'),
        ...snap.docs.map((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString();
          final slug = (data['slug'] ?? '').toString();
          return _CategoryOption(slug: slug, label: name);
        }),
      ];

      setState(() {
        _categories = options;
        _loadingCategories = false;

        // Reset selection if stored slug is no longer present
        final slugs = options.map((c) => c.slug).toSet();
        if (!slugs.contains(_selectedCategorySlug)) {
          _selectedCategorySlug = 'all';
        }
      });
    } catch (e) {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadAreas(String stateId, String metroId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('metros')
          .doc(metroId)
          .collection('areas')
          .orderBy('name')
          .get();

      final options = <_AreaOption>[
        const _AreaOption(id: 'all', name: 'All Areas'),
        ...snap.docs.map((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString();
          return _AreaOption(id: d.id, name: name);
        }),
      ];

      setState(() {
        _areas = options;
        _loadingAreas = false;

        final ids = options.map((a) => a.id).toSet();
        if (!ids.contains(_selectedAreaId)) {
          _selectedAreaId = 'all';
        }
      });
    } catch (e) {
      setState(() => _loadingAreas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);

    return location.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (loc) {
        if (loc.stateId == null || loc.metroId == null) {
          return const Scaffold(
            body: Center(child: Text('Please select a location')),
          );
        }

        if (_loadingAreas) {
          _loadAreas(loc.stateId!, loc.metroId!);
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('Eat & Drink'),
              ),

              // FILTERS
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- AREA FILTER FIRST ----
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        'Areas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _loadingAreas
                          ? const LinearProgressIndicator()
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _areas.map((area) {
                                final selected = _selectedAreaId == area.id;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(area.name),
                                  onSelected: (_) {
                                    setState(() => _selectedAreaId = area.id);
                                  },
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // ---- CATEGORY FILTER SECOND ----
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _loadingCategories
                          ? const LinearProgressIndicator()
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((cat) {
                                final selected =
                                    _selectedCategorySlug == cat.slug;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(cat.label),
                                  onSelected: (_) {
                                    setState(
                                        () => _selectedCategorySlug = cat.slug);
                                  },
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // LIST
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('eatAndDrink')
                    .where('active', isEqualTo: true)
                    .where('stateId', isEqualTo: loc.stateId)
                    .where('metroId', isEqualTo: loc.metroId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  // For sorting by category label, build a slug->label map
                  final categoryLabelMap = {
                    for (final c in _categories) c.slug: c.label
                  };

                  // Convert to model + filter
                  final items =
                      docs.map((d) => EatAndDrink.fromDoc(d)).where((place) {
                    // AREA FILTER (by ID)
                    final areaMatches = _selectedAreaId == 'all' ||
                        (place.areaId.isNotEmpty &&
                            place.areaId == _selectedAreaId);

                    // CATEGORY FILTER (by SLUG – place.category stores slug)
                    final catMatches = _selectedCategorySlug == 'all' ||
                        place.category == _selectedCategorySlug;

                    return areaMatches && catMatches;
                  }).toList();

                  // Sort by category label, then areaName, then name
                  items.sort((a, b) {
                    final aCatLabel = categoryLabelMap[a.category] ??
                        a.category; // fallback to slug
                    final bCatLabel =
                        categoryLabelMap[b.category] ?? b.category;
                    final byCat = aCatLabel
                        .toLowerCase()
                        .compareTo(bCatLabel.toLowerCase());
                    if (byCat != 0) return byCat;

                    final aArea = a.areaName.toLowerCase();
                    final bArea = b.areaName.toLowerCase();
                    final byArea = aArea.compareTo(bArea);
                    if (byArea != 0) return byArea;

                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });

                  if (items.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text('No places found'),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final place = items[index];

                      final headerImg = place.bannerImageUrl.isNotEmpty
                          ? place.bannerImageUrl
                          : place.imageUrl;

                      return GestureDetector(
                        onTap: () {
                          context.pushNamed(
                            'eatDetail',
                            extra: place,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // IMAGE
                                headerImg.isNotEmpty
                                    ? Image.network(
                                        headerImg,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 160,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                        child: const Icon(
                                          Icons.restaurant,
                                          size: 48,
                                        ),
                                      ),

                                // TEXT
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        place.city,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      if (place.hours != null &&
                                          place.hours!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.schedule,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(place.hours!),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
