import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/lodging.dart';

class AdminLodgingPage extends StatefulWidget {
  const AdminLodgingPage({
    super.key,
    this.initialStateId,
    this.initialMetroId,
  });

  final String? initialStateId;
  final String? initialMetroId;

  @override
  State<AdminLodgingPage> createState() => _AdminLodgingPageState();
}

class _AdminLodgingPageState extends State<AdminLodgingPage> {
  bool _showInactive = false;
  bool _featuredOnly = false;

  String? _filterStateId;
  String? _filterMetroId;
  String? _filterAreaId;

  @override
  void initState() {
    super.initState();
    // Seed filters from the router (dashboard → admin)
    _filterStateId =
        (widget.initialStateId != null && widget.initialStateId!.isNotEmpty)
            ? widget.initialStateId
            : null;
    _filterMetroId =
        (widget.initialMetroId != null && widget.initialMetroId!.isNotEmpty)
            ? widget.initialMetroId
            : null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lodging'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('stays')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading lodging: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No lodging added yet.'),
            );
          }

          final allStays = docs.map((d) => Stay.fromDoc(d)).toList();

          // Label maps
          final Map<String, String> stateLabels = {};
          final Map<String, String> metroLabels = {};
          final Map<String, String> areaLabels = {};

          for (final s in allStays) {
            if (s.stateId.isNotEmpty) {
              stateLabels[s.stateId] =
                  s.stateName.isNotEmpty ? s.stateName : s.stateId;
            }
            if (s.metroId.isNotEmpty) {
              metroLabels[s.metroId] =
                  s.metroName.isNotEmpty ? s.metroName : s.metroId;
            }
            if (s.areaId.isNotEmpty) {
              areaLabels[s.areaId] =
                  s.areaName.isNotEmpty ? s.areaName : s.areaId;
            }
          }

          // Include any current filters in options so dropdowns stay valid
          final stateOptions = <String?>{
            null,
            if (_filterStateId != null) _filterStateId,
            ...stateLabels.keys,
          };
          final metroOptions = <String?>{
            null,
            if (_filterMetroId != null) _filterMetroId,
            ...metroLabels.keys,
          };
          final areaOptions = <String?>{
            null,
            if (_filterAreaId != null) _filterAreaId,
            ...areaLabels.keys,
          };

          // Filters
          final filteredStays = allStays.where((stay) {
            if (!_showInactive && !stay.active) return false;
            if (_featuredOnly && !stay.featured) return false;

            if (_filterStateId != null &&
                _filterStateId!.isNotEmpty &&
                stay.stateId != _filterStateId) {
              return false;
            }

            if (_filterMetroId != null &&
                _filterMetroId!.isNotEmpty &&
                stay.metroId != _filterMetroId) {
              return false;
            }

            if (_filterAreaId != null &&
                _filterAreaId!.isNotEmpty &&
                stay.areaId != _filterAreaId) {
              return false;
            }

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
                  itemCount: filteredStays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final stay = filteredStays[index];

                    final mainLine = [
                      if (stay.category.isNotEmpty) stay.category,
                      if (stay.city.isNotEmpty) stay.city,
                    ].join(' • ');

                    final regionLine = [
                      if (stay.stateName.isNotEmpty) stay.stateName,
                      if (stay.metroName.isNotEmpty) stay.metroName,
                      if (stay.areaName.isNotEmpty) stay.areaName,
                    ].join(' • ');

                    final hasStructuredHours =
                        stay.hoursByDay != null && stay.hoursByDay!.isNotEmpty;

                    return ListTile(
                      title: Text(
                        stay.name,
                        style: TextStyle(
                          fontWeight:
                              stay.featured ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mainLine.isNotEmpty)
                            Text(
                              mainLine,
                              style: const TextStyle(fontSize: 13),
                            ),
                          if (stay.address.isNotEmpty)
                            Text(
                              stay.address,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (regionLine.isNotEmpty)
                            Text(
                              regionLine,
                              style: const TextStyle(fontSize: 11),
                            ),

                          // Hours: prefer structured indicator, fall back to legacy text
                          if (hasStructuredHours)
                            Text(
                              'Hours schedule set',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else if (stay.hours != null && stay.hours!.isNotEmpty)
                            Text(
                              stay.hours!,
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
                                  .collection('stays')
                                  .doc(stay.id)
                                  .update({'featured': !stay.featured});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: stay.featured
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: stay.featured
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    stay.featured
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: stay.featured
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Featured',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Active toggle
                          Switch(
                            value: stay.active,
                            onChanged: (v) async {
                              await FirebaseFirestore.instance
                                  .collection('stays')
                                  .doc(stay.id)
                                  .update({'active': v});
                            },
                          ),

                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              context.push(
                                '/admin/lodging/edit',
                                extra: stay,
                              );
                            },
                          ),
                        ],
                      ),
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
          context.push('/admin/lodging/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Lodging'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF146C43),
      ),
    );
  }
}
