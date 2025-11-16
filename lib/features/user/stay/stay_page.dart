import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/stay.dart';

class StayPage extends StatefulWidget {
  const StayPage({super.key});

  @override
  State<StayPage> createState() => _StayPageState();
}

class _StayPageState extends State<StayPage> {
  String _categoryFilter = 'All';

  static const _categories = [
    'All',
    'Hotel',
    'Motel',
    'Cabin / Cottage',
    'Campground / RV Park',
    'Vacation Rental',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stay'),
      ),
      body: Column(
        children: [
          // Category chips row
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

          // Lodging list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('stays')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading lodging: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No lodging options yet.'),
                  );
                }

                var stays = docs
                    .map((d) => Stay.fromDoc(d))
                    .where((s) => s.active)
                    .toList();

                // Category filter
                if (_categoryFilter != 'All') {
                  stays = stays
                      .where((s) => s.category == _categoryFilter)
                      .toList();
                }

                if (stays.isEmpty) {
                  return const Center(
                    child: Text('No lodging matches this filter.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stays.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final stay = stays[index];
                    final heroTag = stay.heroTag.isNotEmpty
                        ? stay.heroTag
                        : 'stay_${stay.id}';

                    final subtitleLines = <String>[];

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

                    if (stay.hours != null && stay.hours!.isNotEmpty) {
                      subtitleLines.add(stay.hours!);
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(
                            'stayDetail', // matches router name
                            extra: stay,
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail image
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

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        if (stay.featured)
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
