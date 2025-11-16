import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/place.dart';
import '../../../widgets/location_selector.dart';
import 'edit_attraction_page.dart';

class AdminExplorePage extends StatefulWidget {
  const AdminExplorePage({super.key});

  @override
  State<AdminExplorePage> createState() => _AdminExplorePageState();
}

class _AdminExplorePageState extends State<AdminExplorePage> {
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
        title: const Text('Attractions / Explore'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('attractions')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child:
                  Text('Error loading attractions: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No attractions added yet.'),
            );
          }

          final allPlaces =
              docs.map((d) => Place.fromFirestore(d)).toList();

          // Build label maps
          final Map<String, String> stateLabels = {};
          final Map<String, String> metroLabels = {};
          final Map<String, String> areaLabels = {};

          for (final p in allPlaces) {
            if (p.stateId.isNotEmpty) {
              stateLabels[p.stateId] =
                  p.stateName.isNotEmpty ? p.stateName : p.stateId;
            }
            if (p.metroId.isNotEmpty) {
              metroLabels[p.metroId] =
                  p.metroName.isNotEmpty ? p.metroName : p.metroId;
            }
            if (p.areaId.isNotEmpty) {
              areaLabels[p.areaId] =
                  p.areaName.isNotEmpty ? p.areaName : p.areaId;
            }
          }

          final stateOptions = <String?>{null, ...stateLabels.keys};
          final metroOptions = <String?>{null, ...metroLabels.keys};
          final areaOptions = <String?>{null, ...areaLabels.keys};

          // Apply filters
          final filteredPlaces = allPlaces.where((p) {
            if (!_showInactive && !p.active) return false;
            if (_featuredOnly && !p.featured) return false;
            if (_filterStateId != null &&
                _filterStateId!.isNotEmpty &&
                p.stateId != _filterStateId) return false;
            if (_filterMetroId != null &&
                _filterMetroId!.isNotEmpty &&
                p.metroId != _filterMetroId) return false;
            if (_filterAreaId != null &&
                _filterAreaId!.isNotEmpty &&
                p.areaId != _filterAreaId) return false;
            return true;
          }).toList();

          return Column(
            children: [
              // Filter bar
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

                    // State + Metro
                    Row(
                      children: [
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

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPlaces.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = filteredPlaces[index];

                    return ListTile(
                      title: Text(
                        place.title,
                        style: TextStyle(
                          fontWeight: place.featured
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${place.city} • ${place.category}'),
                          if (place.hours != null &&
                              place.hours!.isNotEmpty)
                            Text(
                              place.hours!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (place.stateName.isNotEmpty ||
                              place.metroName.isNotEmpty ||
                              place.areaName.isNotEmpty)
                            Text(
                              [
                                if (place.stateName.isNotEmpty)
                                  place.stateName,
                                if (place.metroName.isNotEmpty)
                                  place.metroName,
                                if (place.areaName.isNotEmpty)
                                  place.areaName,
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
                                  .collection('attractions')
                                  .doc(place.id)
                                  .update(
                                      {'featured': !place.featured});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: place.featured
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: place.featured
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    place.featured
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: place.featured
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Featured',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: place.featured
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
                            value: place.active,
                            onChanged: (v) async {
                              await FirebaseFirestore.instance
                                  .collection('attractions')
                                  .doc(place.id)
                                  .update({'active': v});
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditAttractionPage(place: place),
                          ),
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
          // If you have /admin/attractions/add route, you can use GoRouter here
          // For now, assume AddAttractionPage is wired in the router
          context.push('/admin/attractions');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Attraction'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF146C43),
      ),
    );
  }
}
