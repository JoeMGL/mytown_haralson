import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/event.dart'; // 👈 your Event model

class FeaturedEventsSection extends StatelessWidget {
  const FeaturedEventsSection({
    super.key,
    required this.title,
    this.stateId,
    this.metroId,
    this.onEventTap,
  });

  /// Header label, e.g. "Featured Events"
  final String title;

  /// Optional filters (match what you save in AddEventPage)
  final String? stateId;
  final String? metroId;

  /// Called when an event card is tapped
  final void Function(Event event)? onEventTap;

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('events')
        .where('featured', isEqualTo: true);

    // Optional filters by state/metro, same pattern as clubs
    if (stateId != null && stateId!.isNotEmpty) {
      query = query.where('stateId', isEqualTo: stateId);
    }
    if (metroId != null && metroId!.isNotEmpty) {
      query = query.where('metroId', isEqualTo: metroId);
    }

    // Optionally you *could* filter for upcoming events only, e.g.:
    // final now = Timestamp.fromDate(DateTime.now());
    // query = query.where('end', isGreaterThan: now);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // keep home page clean while loading
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // no featured events -> hide section
          return const SizedBox.shrink();
        }

        final events = snapshot.data!.docs
            .map((doc) => Event.fromDoc(doc)) // 👈 make sure this exists
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (matches FeaturedClubsSection)
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
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _EventCard(
                    event: event,
                    onTap: onEventTap == null ? null : () => onEventTap!(event),
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

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    this.onTap,
  });

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Prefer banner from Firestore extra fields if you add it later,
    // otherwise use event.imageUrl from the model.
    // Assuming your Event model has `imageUrl` as String?:
    final primaryImage = (event.imageUrl ?? '').trim();
    final imageUrl = primaryImage;

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
                      child: const Icon(Icons.event),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 2),

          // Optional little line for city or venue
          if (event.venue.isNotEmpty || event.city.isNotEmpty)
            Text(
              event.venue.isNotEmpty ? event.venue : event.city,
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
