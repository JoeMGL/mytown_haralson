import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lodging.dart';
import '../../../models/category.dart';
import '/core/location/location_provider.dart';

// ⭐ NEW
import '../../../widgets/favorite_button.dart';
import '../../../core/analytics/analytics_service.dart';

class StayPage extends ConsumerStatefulWidget {
  const StayPage({super.key});

  @override
  ConsumerState<StayPage> createState() => _StayPageState();
}

// Simple helper for area options
class _AreaOption {
  final String id; // '' or 'all' for All
  final String name;

  const _AreaOption({required this.id, required this.name});
}

// Helper for category options (label only; Stay.category stores the label)
class _CategoryOption {
  final String label; // 'All' or Category.name

  const _CategoryOption({required this.label});
}

class _StayPageState extends ConsumerState<StayPage> {
  // Area filter (by ID)
  String _selectedAreaId = 'all';
  List<_AreaOption> _areas = const [
    _AreaOption(id: 'all', name: 'All Areas'),
  ];
  bool _loadingAreas = true;

  // Category filter (by LABEL)
  String _selectedCategoryLabel = 'All';
  List<_CategoryOption> _categories = const [
    _CategoryOption(label: 'All'),
  ];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    // 📊 Analytics: screen view
    AnalyticsService.logView('StayPage');
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: 'stay')
          .orderBy('sortOrder')
          .get();

      final options = <_CategoryOption>[
        const _CategoryOption(label: 'All'),
        ...snap.docs.map((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString();
          return _CategoryOption(label: name);
        }),
      ];

      setState(() {
        _categories = options;
        _loadingCategories = false;

        final labels = options.map((c) => c.label).toSet();
        if (!labels.contains(_selectedCategoryLabel)) {
          _selectedCategoryLabel = 'All';
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
    final cs = Theme.of(context).colorScheme;
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
                title: const Text('Stay'),
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
                                    _selectedCategoryLabel == cat.label;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(cat.label),
                                  onSelected: (_) {
                                    setState(() =>
                                        _selectedCategoryLabel = cat.label);
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
                    .collection('stays')
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

                  // Convert to model + filter
                  final items = docs.map((d) => Stay.fromDoc(d)).where((stay) {
                    // AREA FILTER (by ID)
                    final areaMatches = _selectedAreaId == 'all' ||
                        (stay.areaId.isNotEmpty &&
                            stay.areaId == _selectedAreaId);

                    // CATEGORY FILTER (by LABEL – Stay.category stores name)
                    final catMatches = _selectedCategoryLabel == 'All' ||
                        stay.category == _selectedCategoryLabel;

                    return areaMatches && catMatches;
                  }).toList();

                  // Sort by category label, then areaName, then name
                  items.sort((a, b) {
                    final aCat = a.category.toLowerCase();
                    final bCat = b.category.toLowerCase();
                    final byCat = aCat.compareTo(bCat);
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
                      final stay = items[index];
                      final heroTag = stay.heroTag.isNotEmpty
                          ? stay.heroTag
                          : 'stay_${stay.id}';

                      final subtitleLines = <String>[];

                      // Category + city
                      if (stay.category.isNotEmpty || stay.city.isNotEmpty) {
                        subtitleLines.add(
                          [
                            if (stay.category.isNotEmpty) stay.category,
                            if (stay.city.isNotEmpty) stay.city,
                          ].join(' • '),
                        );
                      }

                      if (stay.address.isNotEmpty) {
                        subtitleLines.add(stay.address);
                      }

                      final todayHours = _formatTodayHours(stay);
                      if (todayHours != null && todayHours.isNotEmpty) {
                        subtitleLines.add(todayHours);
                      }

                      return GestureDetector(
                        onTap: () {
                          // 📊 Analytics: user opened stay detail
                          AnalyticsService.logEvent('view_stay_detail',
                              params: {
                                'stay_id': stay.id,
                                'stay_name': stay.name,
                                'category': stay.category,
                                'city': stay.city,
                                'state_name': stay.stateName,
                                'metro_name': stay.metroName,
                                'area_name': stay.areaName,
                              });

                          context.pushNamed(
                            'stayDetail',
                            extra: stay,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // IMAGE
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Hero(
                                    tag: heroTag,
                                    child: stay.imageUrl.isNotEmpty
                                        ? Image.network(
                                            stay.imageUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: cs.surfaceVariant,
                                            child: Icon(
                                              Icons.hotel,
                                              size: 40,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                  ),
                                ),

                                // TEXT
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
                                                stay.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            if (stay.featured)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4.0),
                                                child: Icon(
                                                  Icons.star,
                                                  size: 18,
                                                  color: cs.primary,
                                                ),
                                              ),
                                            // ⭐ Favorite toggle for stays
                                            FavoriteButton(
                                              type: 'lodging',
                                              itemId: stay.id,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (subtitleLines.isNotEmpty)
                                          Text(
                                            subtitleLines.join('\n'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (stay.description.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              stay.description,
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

  /// Returns a short "today" hours string using structured hours if present,
  /// otherwise falls back to the legacy `stay.hours` string.
  String? _formatTodayHours(Stay stay) {
    final map = stay.hoursByDay;
    if (map == null || map.isEmpty) {
      // fallback to legacy string
      return stay.hours;
    }

    final now = DateTime.now();
    final weekdayKey = switch (now.weekday) {
      DateTime.monday => 'mon',
      DateTime.tuesday => 'tue',
      DateTime.wednesday => 'wed',
      DateTime.thursday => 'thu',
      DateTime.friday => 'fri',
      DateTime.saturday => 'sat',
      DateTime.sunday => 'sun',
      _ => 'mon',
    };

    final day = map[weekdayKey];
    if (day == null || day.closed) {
      return 'Closed today';
    }

    final open = (day.open ?? '').trim();
    final close = (day.close ?? '').trim();

    if (open.isEmpty && close.isEmpty) {
      return 'Open today';
    } else if (open.isNotEmpty && close.isNotEmpty) {
      return '$open – $close';
    } else if (open.isNotEmpty) {
      return 'From $open';
    } else {
      return 'Until $close';
    }
  }
}
