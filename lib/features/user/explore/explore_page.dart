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

              // Category chips (dynamic)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildCategoryChips(context),
              ),
              const Divider(height: 1),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('attractions')
                      .where('stateId', isEqualTo: stateId)
                      .where('metroId', isEqualTo: metroId)
                      .orderBy('name')
                      .snapshots(),
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
                                        Text(
                                          [
                                            if (categoryLabel.isNotEmpty)
                                              categoryLabel,
                                            if (place.city.isNotEmpty)
                                              place.city,
                                          ].join(' • '),
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
