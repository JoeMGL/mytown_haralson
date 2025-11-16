// lib/features/admin/shops/admin_shops_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/shop.dart';

class AdminShopsPage extends StatefulWidget {
  const AdminShopsPage({super.key});

  @override
  State<AdminShopsPage> createState() => _AdminShopsPageState();
}

class _AdminShopsPageState extends State<AdminShopsPage> {
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
        title: const Text('Shops & Businesses'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading shops: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No shops added yet.'),
            );
          }

          final allShops = docs.map((d) => Shop.fromFirestore(d)).toList();

          // Build label maps like Clubs/Events
          final Map<String, String> stateLabels = {};
          final Map<String, String> metroLabels = {};
          final Map<String, String> areaLabels = {};

          for (final s in allShops) {
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

          final stateOptions = <String?>{null, ...stateLabels.keys};
          final metroOptions = <String?>{null, ...metroLabels.keys};
          final areaOptions = <String?>{null, ...areaLabels.keys};

          // Apply filters in memory
          final filteredShops = allShops.where((shop) {
            if (!_showInactive && !shop.active) return false;
            if (_featuredOnly && !shop.featured) return false;

            if (_filterStateId != null &&
                _filterStateId!.isNotEmpty &&
                shop.stateId != _filterStateId) return false;

            if (_filterMetroId != null &&
                _filterMetroId!.isNotEmpty &&
                shop.metroId != _filterMetroId) return false;

            if (_filterAreaId != null &&
                _filterAreaId!.isNotEmpty &&
                shop.areaId != _filterAreaId) return false;

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

                    // Area
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
                  itemCount: filteredShops.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final shop = filteredShops[index];

                    final mainLine = [
                      if (shop.category.isNotEmpty) shop.category,
                      if (shop.city.isNotEmpty) shop.city,
                    ].join(' • ');

                    final addressLine =
                        shop.address.isNotEmpty ? shop.address : '';

                    final regionLine = [
                      if (shop.stateName.isNotEmpty) shop.stateName,
                      if (shop.metroName.isNotEmpty) shop.metroName,
                      if (shop.areaName.isNotEmpty) shop.areaName,
                    ].join(' • ');

                    final hoursLine =
                        (shop.hours != null && shop.hours!.isNotEmpty)
                            ? shop.hours!
                            : '';

                    return ListTile(
                      title: Text(
                        shop.name,
                        style: TextStyle(
                          fontWeight:
                              shop.featured ? FontWeight.bold : FontWeight.w500,
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
                          if (addressLine.isNotEmpty)
                            Text(
                              addressLine,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (regionLine.isNotEmpty)
                            Text(
                              regionLine,
                              style: const TextStyle(fontSize: 11),
                            ),
                          if (hoursLine.isNotEmpty)
                            Text(
                              hoursLine,
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
                                  .collection('shops')
                                  .doc(shop.id)
                                  .update({'featured': !shop.featured});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: shop.featured
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: shop.featured
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    shop.featured
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: shop.featured
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
                            value: shop.active,
                            onChanged: (v) async {
                              await FirebaseFirestore.instance
                                  .collection('shops')
                                  .doc(shop.id)
                                  .update({'active': v});
                            },
                          ),

                          // Edit
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              context.push(
                                '/admin/shops/edit',
                                extra: shop,
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
          context.push('/admin/shops/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Shop'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF146C43),
      ),
    );
  }
}
