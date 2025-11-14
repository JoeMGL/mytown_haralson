// lib/features/admin/clubs/admin_clubs_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminClubsPage extends StatelessWidget {
  const AdminClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('clubs')
              //.orderBy('city')
              //.orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading clubs: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('No clubs or groups yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final name = data['name'] ?? '';
                final city = data['city'] ?? '';
                final category = data['category'] ?? '';
                final meetingSchedule = data['meetingSchedule'] ?? '';
                final featured = data['featured'] ?? false;
                final active = data['active'] ?? true;

                return ListTile(
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: featured ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$city • $category'),
                      if (meetingSchedule.isNotEmpty)
                        Text(
                          meetingSchedule,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Featured toggle
                      InkWell(
                        onTap: () async {
                          await doc.reference.update({'featured': !featured});
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: featured
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: featured ? cs.primary : cs.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                featured ? Icons.star : Icons.star_border,
                                size: 16,
                                color: featured ? cs.primary : cs.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: featured ? cs.primary : cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Active switch
                      Switch(
                        value: active,
                        onChanged: (v) async {
                          await doc.reference.update({'active': v});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        // Floating Add Button (overlay)
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/admin/clubs/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Club / Group'),
          ),
        ),
      ],
    );
  }
}
