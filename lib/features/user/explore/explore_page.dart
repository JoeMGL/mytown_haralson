import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/place.dart';
import '../../../models/category.dart';
import '../../../models/section.dart';
import '/core/location/location_provider.dart';

// 🔑 This is the slug stored in sections.slug for the Explore/Attractions section
const String kExploreSectionSlug = 'Explore';

// Simple area model just for the filter UI
class MetroArea {
  final String id;
  final String name;

  const MetroArea({
    required this.id,
    required this.name,
  });
}

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  // Section metadata from /sections
  Section? _section;
  bool _loadingSection = true;
  String? _sectionError;

  // Dynamic categories
  List<Category> _categories = [];
  String? _selectedCategorySlug; // null = "All"
  bool _loadingCategories = true;
  String? _categoriesError;

  // Areas within current metro
  List<MetroArea> _areas = [];
  String? _selectedAreaId; // null = "All Areas"
  bool _loadingAreas = false;
  String? _areasError;
  String? _areasStateId; // last state we loaded areas for
  String? _areasMetroId; // last metro we loaded areas for

  @override
  void initState() {
    super.initState();
    _loadSection();
    _loadCategories();
  }

  Future<void> _loadSection() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('sections')
          .where('slug', isEqualTo: kExploreSectionSlug)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snap.docs.isNotEmpty) {
        setState(() {
          _section = Section.fromDoc(snap.docs.first);
          _loadingSection = false;
          _sectionError = null;
        });
      } else {
        setState(() {
          _section = null;
          _loadingSection = false;
          _sectionError = 'No section found with slug "$kExploreSectionSlug".';
        });
      }
    } catch (e, st) {
      debugPrint('Error loading section: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingSection = false;
        _sectionError = e.toString();
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kExploreSectionSlug)
          .orderBy('sortOrder')
          .get();

      final cats = snap.docs.map((d) => Category.fromDoc(d)).toList();

      if (!mounted) return;

      setState(() {
        _categories = cats;
        _categoriesError = null;
        _loadingCategories = false;
      });
    } catch (e, st) {
      debugPrint('Error loading explore categories: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = e.toString();
        _categories = [];
      });
    }
  }

  // Load areas for the current state + metro
  Future<void> _loadAreasForMetro(String stateId, String metroId) async {
    // Avoid reloading for the same metro over and over
    if (_areasStateId == stateId &&
        _areasMetroId == metroId &&
        _areas.isNotEmpty) {
      return;
    }

    setState(() {
      _loadingAreas = true;
      _areasError = null;
      _areasStateId = stateId;
      _areasMetroId = metroId;
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

      if (!mounted) return;

      final list = snap.docs.map((doc) {
        final data = doc.data();
        final name = (data['name'] ?? doc.id) as String;
        return MetroArea(id: doc.id, name: name);
      }).toList();

      setState(() {
        _areas = list;
        _loadingAreas = false;

        // If current selected area isn't in the list anymore, clear it
        if (_selectedAreaId != null &&
            !_areas.any((a) => a.id == _selectedAreaId)) {
          _selectedAreaId = null;
        }
      });
    } catch (e, st) {
      debugPrint('Error loading areas: $e\n$st');
      if (!mounted) return;
      setState(() {
        _areas = [];
        _loadingAreas = false;
        _areasError = e.toString();
      });
    }
  }

  // Resolve area name for a place (uses Place.areaName directly)
  String _resolveAreaNameForPlace(Place p) {
    return p.areaName; // may be empty string
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locationAsync = ref.watch(locationProvider);

    final title = () {
      if (_loadingSection) return 'Explore';
      if (_section != null && _section!.name.isNotEmpty) {
        return _section!.name; // e.g. "Explore Haralson" or "Attractions"
      }
      return 'Explore';
    }();

    return locationAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading location: $e')),
      ),
      data: (loc) {
        final stateId = loc.stateId;
        final metroId = loc.metroId;

        if (stateId == null || metroId == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Select a state and metro in Settings to see attractions.',
              ),
            ),
          );
        }

        // Trigger area load when metro changes
        if (_areasStateId != stateId || _areasMetroId != metroId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadAreasForMetro(stateId, metroId);
          });
        }

        // Base query by state + metro
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('attractions')
            .where('stateId', isEqualTo: stateId)
            .where('metroId', isEqualTo: metroId)
            .orderBy('name'); // no areaId filter here → avoids composite index

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Column(
            children: [
              if (_sectionError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _sectionError!,
                    style: TextStyle(color: cs.error),
                  ),
                ),

              // Area chips (above category chips)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: _buildAreaChips(context),
              ),

              // Category chips (dynamic)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _buildCategoryChips(context),
              ),
              const Divider(height: 1),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading attractions: ${snapshot.error}',
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No attractions yet in this metro.'),
                      );
                    }

                    var places = docs
                        .map((d) => Place.fromFirestore(d))
                        .where((p) => p.active)
                        .toList();

                    // Filter by selected area on the client
                    if (_selectedAreaId != null &&
                        _selectedAreaId!.isNotEmpty) {
                      places = places
                          .where((p) => p.areaId == _selectedAreaId)
                          .toList();
                    }

                    // Filter by selected category (supports slug OR name, case-insensitive)
                    if (_selectedCategorySlug != null &&
                        _selectedCategorySlug!.isNotEmpty) {
                      final selectedSlug = _selectedCategorySlug!;
                      final selectedSlugLower = selectedSlug.toLowerCase();

                      // Try to find the full Category so we also know its display name
                      final selectedCategory = _categories.firstWhere(
                        (c) => c.slug == selectedSlug,
                        orElse: () => _categories.firstWhere(
                          (c) => c.name.toLowerCase() == selectedSlugLower,
                          orElse: () => Category(
                            id: '',
                            section: kExploreSectionSlug,
                            slug: selectedSlug,
                            name: selectedSlug,
                            sortOrder: 0,
                            isActive: true,
                          ),
                        ),
                      );

                      final selectedNameLower =
                          selectedCategory.name.toLowerCase();

                      places = places.where((p) {
                        // Gather all category values from the place
                        final values = <String>[
                          if (p.category.isNotEmpty) p.category,
                          ...p.categories,
                        ].map((v) => v.toLowerCase()).toList();

                        // Match if any of them equals the slug OR the name
                        return values.contains(selectedSlugLower) ||
                            values.contains(selectedNameLower);
                      }).toList();
                    }

                    // Sort by area name, then by place name
                    places.sort((a, b) {
                      final areaA = _resolveAreaNameForPlace(a).toLowerCase();
                      final areaB = _resolveAreaNameForPlace(b).toLowerCase();
                      final cmpArea = areaA.compareTo(areaB);
                      if (cmpArea != 0) return cmpArea;

                      final nameA =
                          (a.name.isNotEmpty ? a.name : a.title).toLowerCase();
                      final nameB =
                          (b.name.isNotEmpty ? b.name : b.title).toLowerCase();
                      return nameA.compareTo(nameB);
                    });

                    if (places.isEmpty) {
                      return const Center(
                        child: Text('No places match this filter.'),
                      );
                    }

                    // Helper to get category label from slug
                    String _resolveCategoryLabel(Place p) {
                      final slug = p.category;
                      final cat = _categories.firstWhere(
                        (c) => c.slug == slug,
                        orElse: () => Category(
                          id: '',
                          section: kExploreSectionSlug,
                          slug: slug,
                          name: slug, // fallback
                          sortOrder: 0,
                          isActive: true,
                        ),
                      );
                      return cat.name;
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: places.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        final heroTag = place.heroTag.isNotEmpty
                            ? place.heroTag
                            : 'place_${place.id}';

                        final categoryLabel = _categories.isEmpty
                            ? place.category
                            : _resolveCategoryLabel(place);

                        final areaName = _resolveAreaNameForPlace(place);

                        final subtitleParts = <String>[
                          if (areaName.isNotEmpty) areaName,
                          if (categoryLabel.isNotEmpty) categoryLabel,
                          if (place.city.isNotEmpty) place.city,
                        ];

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              context.pushNamed(
                                'exploreDetail',
                                extra: place,
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Hero(
                                    tag: heroTag,
                                    child: place.imageUrl.isNotEmpty
                                        ? Image.network(
                                            place.imageUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: cs.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.landscape,
                                              size: 40,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                place.title.isNotEmpty
                                                    ? place.title
                                                    : place.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            if (place.featured)
                                              Icon(
                                                Icons.star,
                                                size: 18,
                                                color: cs.primary,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (subtitleParts.isNotEmpty)
                                          Text(
                                            subtitleParts.join(' • '),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (place.description.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              place.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }

  // Area chip row
  Widget _buildAreaChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loadingAreas) {
      return Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading areas...'),
        ],
      );
    }

    if (_areasError != null) {
      return Text(
        'Error loading areas: $_areasError',
        style: TextStyle(color: cs.error),
      );
    }

    if (_areas.isEmpty) {
      // No areas configured for this metro
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All Areas'),
          selected: _selectedAreaId == null,
          onSelected: (_) {
            setState(() => _selectedAreaId = null);
          },
        ),
        ..._areas.map((area) {
          final selected = _selectedAreaId == area.id;
          return ChoiceChip(
            label: Text(area.name),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedAreaId = area.id);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loadingCategories) {
      return Row(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading categories...'),
        ],
      );
    }

    if (_categoriesError != null) {
      return Text(
        'Error loading categories: $_categoriesError',
        style: TextStyle(color: cs.error),
      );
    }

    if (_categories.isEmpty) {
      return const Text(
        'No categories configured yet.',
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        // "All" chip
        ChoiceChip(
          label: const Text('All'),
          selected: _selectedCategorySlug == null,
          onSelected: (_) {
            setState(() => _selectedCategorySlug = null);
          },
        ),
        // One chip per category from Firestore
        ..._categories.map((cat) {
          final selected = _selectedCategorySlug == cat.slug;
          return ChoiceChip(
            label: Text(cat.name),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCategorySlug = cat.slug);
            },
          );
        }),
      ],
    );
  }
}
