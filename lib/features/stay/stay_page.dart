// stay_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../models/stay.dart';

/// Filters for lodging, mapped to the `type` field from AddLodgingPage
enum LodgingFilter { hotel, cabin, campground, bnb, rental }

const lodgingFilterLabels = {
  LodgingFilter.hotel: 'Hotel / Motel',
  LodgingFilter.cabin: 'Cabin',
  LodgingFilter.campground: 'Campground / RV Park',
  LodgingFilter.bnb: 'Bed & Breakfast',
  LodgingFilter.rental: 'Vacation Rental',
};

class StayPage extends StatefulWidget {
  const StayPage({super.key});

  @override
  State<StayPage> createState() => _StayPageState();
}

class _StayPageState extends State<StayPage> {
  LodgingFilter filter = LodgingFilter.hotel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Stay')),
      body: Column(
        children: [
          // Filter chips (by lodging type)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: LodgingFilter.values.map((f) {
                  final selected = f == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lodgingFilterLabels[f]!),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => filter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Lodging list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('lodging')
                  .where('type', isEqualTo: lodgingFilterLabels[filter])
                  //.orderBy('name')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Error loading lodging: ${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No lodging found for this category yet.'),
                  );
                }

                final stays = docs
                    .map((doc) => Stay.fromDoc(doc))
                    .toList(growable: false);

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final stay = stays[index];
                    return _StayTile(stay: stay);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: stays.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StayTile extends StatelessWidget {
  const _StayTile({required this.stay});

  final Stay stay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.pushNamed('stayDetail', extra: stay);
      },
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon "avatar"
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel),
              ),
              const SizedBox(width: 12),

              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stay.featured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (stay.featured) const SizedBox(height: 4),

                    Text(
                      stay.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stay.city} · ${stay.type}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stay.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Amenity pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (stay.hasBreakfast)
                          _pill(context, Icons.free_breakfast, 'Breakfast'),
                        if (stay.hasPool) _pill(context, Icons.pool, 'Pool'),
                        if (stay.petFriendly)
                          _pill(context, Icons.pets, 'Pet Friendly'),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Contact row (icons only – you can wire tap handlers later)
                    Row(
                      children: [
                        if (stay.phone.isNotEmpty) ...[
                          Icon(Icons.phone, size: 16, color: cs.primary),
                          const SizedBox(width: 8),
                        ],
                        if (stay.website.isNotEmpty)
                          Icon(Icons.language, size: 16, color: cs.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSecondaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
