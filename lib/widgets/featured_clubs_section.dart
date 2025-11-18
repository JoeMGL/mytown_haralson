import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/clubs_model.dart'; // 👈 use the Club model

class FeaturedClubsSection extends StatelessWidget {
  const FeaturedClubsSection({
    super.key,
    required this.title,
    this.stateId,
    this.metroId,
    this.onClubTap,
  });

  /// Header label, e.g. "Clubs & Groups"
  final String title;

  /// Optional filters (match what you save in AddClubPage)
  final String? stateId;
  final String? metroId;

  /// Called when a club card is tapped
  final void Function(Club club)? onClubTap;

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('clubs')
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
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // no featured clubs -> hide section
          return const SizedBox.shrink();
        }

        final clubs =
            snapshot.data!.docs.map((doc) => Club.fromDoc(doc)).toList();

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
                itemCount: clubs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final club = clubs[index];
                  return _ClubCard(
                    club: club,
                    onTap: onClubTap == null ? null : () => onClubTap!(club),
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

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.club,
    this.onTap,
  });

  final Club club;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Prefer banner, then imageUrl, then nothing
    final banner = club.bannerImageUrl.trim();
    final primaryImage = club.imageUrl.trim();
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
                      child: const Icon(Icons.group),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            club.name,
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
