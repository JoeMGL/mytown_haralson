// lib/features/admin/clubs/admin_clubs_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/clubs_model.dart';

class AdminClubsPage extends StatefulWidget {
  const AdminClubsPage({super.key});

  @override
  State<AdminClubsPage> createState() => _AdminClubsPageState();
}

class _AdminClubsPageState extends State<AdminClubsPage> {
  // Filters (all applied in memory)
  bool _showInactive = false;
  bool _featuredOnly = false;

  String? _filterStateId;
  String? _filterMetroId;
  String? _filterAreaId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Groups'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('clubs')
            .orderBy('name') // simple query, no composite index
            .snapshots(),
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
              child: Text('No clubs or groups yet.'),
            );
          }

          // Convert docs to models
          final allClubs = docs.map((d) => Club.fromFirestore(d)).toList();

          // Build label maps from the data
          final Map<String, String> stateLabels = {};
          final Map<String, String> metroLabels = {};
          final Map<String, String> areaLabels = {};

          for (final c in allClubs) {
            if (c.stateId.isNotEmpty) {
              stateLabels[c.stateId] =
                  (c.stateName.isNotEmpty ? c.stateName : c.stateId);
            }
            if (c.metroId.isNotEmpty) {
              metroLabels[c.metroId] =
                  (c.metroName.isNotEmpty ? c.metroName : c.metroId);
            }
            if (c.areaId.isNotEmpty) {
              areaLabels[c.areaId] =
                  (c.areaName.isNotEmpty ? c.areaName : c.areaId);
            }
          }

          // Build option sets (include null for "All …")
          final stateOptions = <String?>{null, ...stateLabels.keys};
          final metroOptions = <String?>{null, ...metroLabels.keys};
          final areaOptions = <String?>{null, ...areaLabels.keys};

          // Apply filters in memory
          final filteredClubs = allClubs.where((club) {
            if (!_showInactive && !club.active) return false;
            if (_featuredOnly && !club.featured) return false;
            if (_filterStateId != null &&
                _filterStateId!.isNotEmpty &&
                club.stateId != _filterStateId) return false;
            if (_filterMetroId != null &&
                _filterMetroId!.isNotEmpty &&
                club.metroId != _filterMetroId) return false;
            if (_filterAreaId != null &&
                _filterAreaId!.isNotEmpty &&
                club.areaId != _filterAreaId) return false;
            return true;
          }).toList();

          return Column(
            children: [
              // FILTER BAR
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick chips
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Featured only'),
                          selected: _featuredOnly,
                          onSelected: (v) {
                            setState(() => _featuredOnly = v);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Show inactive'),
                          selected: _showInactive,
                          onSelected: (v) {
                            setState(() => _showInactive = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // State + Metro filters
                    Row(
                      children: [
                        // State filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterStateId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'State filter',
                              border: OutlineInputBorder(),
                            ),
                            items: stateOptions
                                .map(
                                  (stateId) => DropdownMenuItem(
                                    value: stateId,
                                    child: Text(
                                      stateId == null || stateId.isEmpty
                                          ? 'All states'
                                          : stateLabels[stateId] ?? stateId,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _filterStateId =
                                    (value == null || value.isEmpty)
                                        ? null
                                        : value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Metro filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _filterMetroId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Metro filter',
                              border: OutlineInputBorder(),
                            ),
                            items: metroOptions
                                .map(
                                  (metroId) => DropdownMenuItem(
                                    value: metroId,
                                    child: Text(
                                      metroId == null || metroId.isEmpty
                                          ? 'All metros'
                                          : metroLabels[metroId] ?? metroId,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _filterMetroId =
                                    (value == null || value.isEmpty)
                                        ? null
                                        : value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Area filter
                    DropdownButtonFormField<String>(
                      value: _filterAreaId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Area filter',
                        border: OutlineInputBorder(),
                      ),
                      items: areaOptions
                          .map(
                            (areaId) => DropdownMenuItem(
                              value: areaId,
                              child: Text(
                                areaId == null || areaId.isEmpty
                                    ? 'All areas'
                                    : areaLabels[areaId] ?? areaId,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _filterAreaId =
                              (value == null || value.isEmpty) ? null : value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // LIST
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredClubs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final club = filteredClubs[index];

                    return ListTile(
                      title: Text(
                        club.name,
                        style: TextStyle(
                          fontWeight:
                              club.featured ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${club.city} • ${club.category}'),
                          if (club.meetingSchedule.isNotEmpty)
                            Text(
                              club.meetingSchedule,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (club.stateName.isNotEmpty ||
                              club.metroName.isNotEmpty ||
                              club.areaName.isNotEmpty)
                            Text(
                              [
                                if (club.stateName.isNotEmpty) club.stateName,
                                if (club.metroName.isNotEmpty) club.metroName,
                                if (club.areaName.isNotEmpty) club.areaName,
                              ].join(' • '),
                              style: const TextStyle(fontSize: 11),
                            ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Featured pill
                          InkWell(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('clubs')
                                  .doc(club.id)
                                  .update({'featured': !club.featured});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: club.featured
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: club.featured
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    club.featured
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: club.featured
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Featured',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: club.featured
                                          ? cs.primary
                                          : cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Active toggle
                          Switch(
                            value: club.active,
                            onChanged: (v) async {
                              await FirebaseFirestore.instance
                                  .collection('clubs')
                                  .doc(club.id)
                                  .update({'active': v});
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push(
                          '/admin/clubs/edit',
                          extra: club,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/admin/clubs/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Club / Group'),
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF146C43),
      ),
    );
  }
}
