// lib/features/eat_and_drink/eat_and_drink_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/eat_and_drink_model.dart'; // <-- your EatAndDrink model

/// Categories for Eat & Drink
enum EatCategory { all, restaurants, coffee, sweets }

const eatCategoryLabels = {
  EatCategory.all: 'All',
  EatCategory.restaurants: 'Restaurants',
  EatCategory.coffee: 'Coffee & Cafés',
  EatCategory.sweets: 'Bakery & Sweets',
};

class EatAndDrinkPage extends StatefulWidget {
  const EatAndDrinkPage({super.key});

  @override
  State<EatAndDrinkPage> createState() => _EatAndDrinkPageState();
}

class _EatAndDrinkPageState extends State<EatAndDrinkPage> {
  EatCategory cat = EatCategory.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Eat & Drink')),
      body: Column(
        children: [
          // Category chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: EatCategory.values.map((c) {
                  final selected = c == cat;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        eatCategoryLabels[c]!,
                        style: TextStyle(
                          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      checkmarkColor: Colors.transparent,
                      selectedColor: cs.primary,
                      backgroundColor: cs.surfaceContainerHighest,
                      side: BorderSide(color: cs.outlineVariant),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onSelected: (_) => setState(() => cat = c),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Firestore list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('eat_and_drink') // collection name you’re using
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading dining spots: ${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Map docs → model
                final items =
                    docs.map((doc) => EatAndDrink.fromDoc(doc)).toList();

                // Apply category filter
                final filtered =
                    items.where((e) => _matchesCategory(e, cat)).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No dining locations found yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final eat = filtered[index];
                    return _placeCard(eat);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Category filter for Eat & Drink.
  bool _matchesCategory(EatAndDrink eat, EatCategory selected) {
    final catStr = eat.category.toLowerCase();
    final tags = eat.tags.map((t) => t.toLowerCase()).toList();

    if (selected == EatCategory.all) return true;

    bool hasTag(String keyword) =>
        tags.any((t) => t.contains(keyword.toLowerCase()));

    switch (selected) {
      case EatCategory.all:
        return true;
      case EatCategory.restaurants:
        return catStr.contains('restaurant') ||
            catStr.contains('dining') ||
            catStr.contains('food') ||
            hasTag('restaurant') ||
            hasTag('dining');
      case EatCategory.coffee:
        return catStr.contains('coffee') ||
            catStr.contains('cafe') ||
            hasTag('coffee') ||
            hasTag('café') ||
            hasTag('cafe');
      case EatCategory.sweets:
        return catStr.contains('bakery') ||
            catStr.contains('dessert') ||
            catStr.contains('ice cream') ||
            hasTag('dessert') ||
            hasTag('bakery') ||
            hasTag('ice cream') ||
            hasTag('sweet');
    }
  }

  /// Card for each Eat & Drink location
  Widget _placeCard(EatAndDrink eat) {
    final photo = eat.imageUrl.trim();
    final effectivePhoto = photo.isEmpty
        ? 'https://images.unsplash.com/photo-1470770903676-69b98201ea1c?q=80&w=800'
        : photo;

    // City • Category as subtitle if available
    final subtitleParts = <String>[];
    if (eat.city.trim().isNotEmpty) subtitleParts.add(eat.city.trim());
    if (eat.category.trim().isNotEmpty) subtitleParts.add(eat.category.trim());
    final subtitle = subtitleParts.isEmpty ? '' : subtitleParts.join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Hero(
            tag: eat.heroTag,
            child: _netThumb(effectivePhoto),
          ),
        ),
        title: Text(eat.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) Text(subtitle),
            if (eat.hours != null && eat.hours!.isNotEmpty)
              Text(
                eat.hours!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push(
            '/eat/detail',
            extra: eat, // pass entire EatAndDrink model
          );
        },
      ),
    );
  }

  /// 56x56 network thumb with Unsplash-safe params.
  Widget _netThumb(String url) {
    const uiW = 56, uiH = 56;
    const fetchW = 112, fetchH = 112;
    final safeUrl = _unsplashSafe(url, w: fetchW, h: fetchH, forceJpg: true);

    return Image.network(
      safeUrl,
      width: uiW.toDouble(),
      height: uiH.toDouble(),
      fit: BoxFit.cover,
      cacheWidth: fetchW,
      cacheHeight: fetchH,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: uiW.toDouble(),
          height: uiH.toDouble(),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: uiW.toDouble(),
          height: uiH.toDouble(),
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, size: 20),
        );
      },
    );
  }

  /// For Unsplash, ensure decodable JPEG/crop and target size.
  String _unsplashSafe(
    String url, {
    required int w,
    required int h,
    bool forceJpg = false,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'images.unsplash.com') return url;

    final qp = Map<String, String>.from(uri.queryParameters)
      ..putIfAbsent('auto', () => 'format')
      ..putIfAbsent('fit', () => 'crop')
      ..putIfAbsent('w', () => '$w')
      ..putIfAbsent('h', () => '$h')
      ..putIfAbsent('q', () => '80');
    if (forceJpg) qp.putIfAbsent('fm', () => 'jpg');

    return uri.replace(queryParameters: qp).toString();
  }
}
