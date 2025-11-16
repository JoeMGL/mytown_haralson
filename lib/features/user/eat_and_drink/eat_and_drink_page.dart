import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/location/location_provider.dart';
import '../../../models/eat_and_drink.dart';

class EatAndDrinkPage extends ConsumerStatefulWidget {
  const EatAndDrinkPage({super.key});

  @override
  ConsumerState<EatAndDrinkPage> createState() => _EatAndDrinkPageState();
}

class _EatAndDrinkPageState extends ConsumerState<EatAndDrinkPage> {
  String _categoryFilter = 'All';

  static const _categories = [
    'All',
    'Restaurant',
    'Bar / Pub',
    'Coffee / Cafe',
    'Bakery / Sweets',
    'Brewery / Winery',
    'Food Truck',
    'Other',
  ];

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

        // If no active location is configured, don't show anything generic
        if (stateId == null || metroId == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Select a state and metro in Settings to see places to eat.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Eat & Drink'),
          ),
          body: Column(
            children: [
              // Category chips
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = _categoryFilter == cat;

                    return ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _categoryFilter = cat);
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('eatAndDrink')
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
                          'Error loading places to eat: ${snapshot.error}',
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No places to eat yet in this metro.'),
                      );
                    }

                    var places = docs
                        .map((d) => EatAndDrink.fromDoc(d))
                        .where((p) => p.active)
                        .toList();

                    // Category filter
                    if (_categoryFilter != 'All') {
                      places = places
                          .where((p) => p.category == _categoryFilter)
                          .toList();
                    }

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
                        final eat = places[index];
                        final heroTag = eat.heroTag.isNotEmpty
                            ? eat.heroTag
                            : 'eat_${eat.id}';

                        final subtitleLines = <String>[];

                        if (eat.category.isNotEmpty || eat.city.isNotEmpty) {
                          subtitleLines.add(
                            [
                              if (eat.category.isNotEmpty) eat.category,
                              if (eat.city.isNotEmpty) eat.city,
                            ].join(' • '),
                          );
                        }

                        if (eat.hours != null && eat.hours!.isNotEmpty) {
                          subtitleLines.add(eat.hours!);
                        }

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              context.pushNamed(
                                'eatDetail',
                                extra: eat,
                              );
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: Hero(
                                    tag: heroTag,
                                    child: eat.imageUrl.isNotEmpty
                                        ? Image.network(
                                            eat.imageUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: cs.surfaceContainerHighest,
                                            child: Icon(
                                              Icons.restaurant,
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
                                                eat.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            if (eat.featured)
                                              Icon(
                                                Icons.star,
                                                size: 18,
                                                color: cs.primary,
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
                                        if (eat.description.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              eat.description,
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
