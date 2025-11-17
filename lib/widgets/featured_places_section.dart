import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/place.dart';

class FeaturedAttractionsSection extends StatelessWidget {
  const FeaturedAttractionsSection({
    super.key,
    required this.title,
    this.stateId,
    this.metroId,
    this.onPlaceTap,
  });

  /// Header text for the section, e.g. "Featured Attractions"
  final String title;

  /// Location filters (match what AddAttractionPage saves)
  final String? stateId;
  final String? metroId;

  /// Optional: navigate when a card is tapped
  final void Function(Place place)? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('attractions')
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
          // You could show a shimmer here later
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // No featured attractions -> hide section
          return const SizedBox.shrink();
        }

        final places =
            snapshot.data!.docs.map((doc) => Place.fromFirestore(doc)).toList();

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

            // Horizontal strip of attraction cards
            SizedBox(
              height: 220,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _FeaturedAttractionCard(
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

class _FeaturedAttractionCard extends StatelessWidget {
  const _FeaturedAttractionCard({
    required this.place,
    this.onTap,
  });

  final Place place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              child: place.imageUrl.isNotEmpty
                  ? Image.network(
                      place.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceVariant,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: cs.surfaceVariant,
                      alignment: Alignment.center,
                      child: const Icon(Icons.photo),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            place.title, // matches what you save: 'title': title
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
