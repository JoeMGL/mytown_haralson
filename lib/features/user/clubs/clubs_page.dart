import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/clubs_model.dart';
import '/core/location/location_provider.dart'; // same as HomePage

class ClubsPage extends ConsumerStatefulWidget {
  const ClubsPage({super.key});

  @override
  ConsumerState<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends ConsumerState<ClubsPage> {
  String _city = 'All Cities';
  String _category = 'All';

  static const _categories = [
    'All',
    'Civic / Service',
    'Youth Sports',
    'Adult Sports',
    'Church / Faith-based',
    'Nonprofit',
    'School / Booster',
    'Hobby / Special Interest',
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
        appBar: AppBar(
          title: const Text('Clubs & Groups'),
        ),
        body: Center(child: Text('Error loading location: $e')),
      ),
      data: (loc) {
        final stateId = loc.stateId;
        final metroId = loc.metroId;

        // Base query: only active clubs
        Query<Map<String, dynamic>> clubsQuery = FirebaseFirestore.instance
            .collection('clubs')
            .where('active', isEqualTo: true);

        // If a metro is configured (including dev override), only show that metro
        if (stateId != null && metroId != null) {
          clubsQuery = clubsQuery.where('metroId', isEqualTo: metroId);
        }

        // City filter
        if (_city != 'All Cities') {
          clubsQuery = clubsQuery.where('city', isEqualTo: _city);
        }

        // Category filter
        if (_category != 'All') {
          clubsQuery = clubsQuery.where('category', isEqualTo: _category);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Clubs & Groups'),
          ),
          body: Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _category = v ?? _category);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // List of clubs
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: clubsQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading clubs: ${snapshot.error}'),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No clubs or groups match your filters.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final club = Club.fromFirestore(docs[index]);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              club.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${club.address} • ${club.category}'),
                                if (club.meetingSchedule.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      club.meetingSchedule,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              GoRouter.of(context).pushNamed(
                                'clubDetail',
                                extra: club,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          backgroundColor: cs.surface,
        );
      },
    );
  }
}
