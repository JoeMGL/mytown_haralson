import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/eat_and_drink.dart'; // 👈 use your EatAndDrink model

class FeaturedEatAndDrinkSection extends StatelessWidget {
  const FeaturedEatAndDrinkSection({
    super.key,
    required this.title,
    this.stateId,
    this.metroId,
    this.onPlaceTap,
  });

  /// Header label, e.g. "Featured Eats & Drinks"
  final String title;

  /// Optional filters (match what you save in AddEatAndDrinkPage)
  final String? stateId;
  final String? metroId;

  /// Called when a place card is tapped
  final void Function(EatAndDrink place)? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('eatAndDrink')
        .where('featured', isEqualTo: true)
        .where('active', isEqualTo: true);

    if (stateId != null && stateId!.isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateId);
    }
    if (metroId != null && metroId!.isNotEmpty) {
      query = query.where('metroId', isEqualTo: metroId);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // keep home page clean while loading
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // no featured places -> hide section
          return const SizedBox.shrink();
        }

        final places = snapshot.data!.docs
            .map((doc) => EatAndDrink.fromDoc(doc)) // 👈 make sure this exists
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Horizontal list of cards
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _EatAndDrinkCard(
                    place: place,
                    onTap: onPlaceTap == null ? null : () => onPlaceTap!(place),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EatAndDrinkCard extends StatelessWidget {
  const _EatAndDrinkCard({
    required this.place,
    this.onTap,
  });

  final EatAndDrink place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Prefer banner, then main imageUrl, then nothing
    final banner = place.bannerImageUrl.trim();
    final primaryImage = place.imageUrl.trim();
    final imageUrl = banner.isNotEmpty ? banner : primaryImage;

    final card = SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceVariant,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      color: cs.surfaceVariant,
                      alignment: Alignment.center,
                      child: const Icon(Icons.restaurant),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          // Optional city line (nice for context)
          if (place.city.isNotEmpty)
            Text(
              place.city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}
