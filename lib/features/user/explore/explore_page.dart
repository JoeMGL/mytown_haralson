import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/place.dart';
import '/core/location/location_provider.dart';

/// Categories for Explore
enum ExploreCategory { outdoor, museums, landmarks, family }

const categoryLabels = {
  ExploreCategory.outdoor: 'Outdoor Recreation',
  ExploreCategory.museums: 'Museums',
  ExploreCategory.landmarks: 'Landmarks',
  ExploreCategory.family: 'Family',
};

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage> {
  ExploreCategory _cat = ExploreCategory.outdoor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locationAsync = ref.watch(locationProvider);

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
          appBar: AppBar(title: const Text('Explore')),
          body: Column(
            children: [
              // Category chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: ExploreCategory.values.map((c) {
                    final selected = _cat == c;
                    return ChoiceChip(
                      label: Text(categoryLabels[c] ?? c.name),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _cat = c);
                      },
                    );
                  }).toList(),
                ),
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

                    // Filter by our categories
                    places = places.where((p) {
                      switch (_cat) {
                        case ExploreCategory.outdoor:
                          return p.category == 'Outdoor';
                        case ExploreCategory.museums:
                          return p.category == 'History' ||
                              p.category == 'Museum';
                        case ExploreCategory.landmarks:
                          return p.category == 'Landmarks' ||
                              p.category == 'Shopping';
                        case ExploreCategory.family:
                          return p.tags
                              .map((t) => t.toLowerCase())
                              .contains('family-friendly');
                      }
                    }).toList();

                    if (places.isEmpty) {
                      return const Center(
                        child: Text('No places match this filter.'),
                      );
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
                                                place.title,
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
                                            if (place.category.isNotEmpty)
                                              place.category,
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
}
