import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/shop.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String _categoryFilter = 'All';

  // Match categories used in Add/EditShop
  static const _categories = [
    'All',
    'Retail / Boutique',
    'Antiques & Vintage',
    'Home & Gifts',
    'Salon / Spa',
    'Professional Services',
    'Food & Drink',
    'Entertainment',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Local'),
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _categories.length,
            ),
          ),

          const Divider(height: 1),

          // List of shops
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('shops')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading shops: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No shops to show yet.'),
                  );
                }

                // Map docs → models, keep only active
                var shops = docs
                    .map((d) => Shop.fromFirestore(d))
                    .where((s) => s.active)
                    .toList();

                // Apply category filter in memory
                if (_categoryFilter != 'All') {
                  shops = shops
                      .where((s) => s.category == _categoryFilter)
                      .toList();
                }

                if (shops.isEmpty) {
                  return const Center(
                    child: Text('No shops match this filter.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    final heroTag = 'shop_${shop.id}';

                    final subtitleLines = <String>[];
                    if (shop.category.isNotEmpty || shop.city.isNotEmpty) {
                      subtitleLines.add(
                        [
                          if (shop.category.isNotEmpty) shop.category,
                          if (shop.city.isNotEmpty) shop.city,
                        ].join(' • '),
                      );
                    }
                    if (shop.address.isNotEmpty) {
                      subtitleLines.add(shop.address);
                    }
                    if (shop.hours != null && shop.hours!.isNotEmpty) {
                      subtitleLines.add(shop.hours!);
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(
                            'shopDetail',
                            extra: shop,
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: Hero(
                                tag: heroTag,
                                child: shop.imageUrl != null &&
                                        shop.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        shop.imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: cs.surfaceVariant,
                                        child: Icon(
                                          Icons.storefront,
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
                                            shop.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        if (shop.featured)
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
                                    if (shop.description.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          shop.description,
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
