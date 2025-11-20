// lib/features/admin/events/admin_events_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../events/admin_add_event_page.dart';
import 'admin_edit_event_page.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({
    super.key,
    this.initialStateId,
    this.initialMetroId,
  });

  final String? initialStateId;
  final String? initialMetroId;

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  // Filters (in-memory)
  bool _featuredOnly = false;
  bool _freeOnly = false;

  String? _filterStateId;
  String? _filterMetroId;
  String? _filterAreaId;

  @override
  void initState() {
    super.initState();
    // Seed filters from router (dashboard → admin)
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
        title: const Text('Events'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('start')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error loading events: ${snap.error}'),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No events added yet.'),
            );
          }

          final allEvents = docs.map((d) => Event.fromDoc(d)).toList();

          // Build label maps from data (like Clubs)
          final Map<String, String> stateLabels = {};
          final Map<String, String> metroLabels = {};
          final Map<String, String> areaLabels = {};

          for (final e in allEvents) {
            if (e.stateId.isNotEmpty) {
              stateLabels[e.stateId] =
                  e.stateName.isNotEmpty ? e.stateName : e.stateId;
            }
            if (e.metroId.isNotEmpty) {
              metroLabels[e.metroId] =
                  e.metroName.isNotEmpty ? e.metroName : e.metroId;
            }
            if (e.areaId.isNotEmpty) {
              areaLabels[e.areaId] =
                  e.areaName.isNotEmpty ? e.areaName : e.areaId;
            }
          }

          // 🔹 Effective filters (only if the id actually appears in data)
          final String? effectiveStateFilter = (_filterStateId != null &&
                  stateLabels.containsKey(_filterStateId))
              ? _filterStateId
              : null;

          final String? effectiveMetroFilter = (_filterMetroId != null &&
                  metroLabels.containsKey(_filterMetroId))
              ? _filterMetroId
              : null;

          final String? effectiveAreaFilter =
              (_filterAreaId != null && areaLabels.containsKey(_filterAreaId))
                  ? _filterAreaId
                  : null;

          // Option sets (only real keys + null)
          final stateOptions = <String?>{null, ...stateLabels.keys};
          final metroOptions = <String?>{null, ...metroLabels.keys};
          final areaOptions = <String?>{null, ...areaLabels.keys};

          // Apply filters in memory using effective filters
          final filteredEvents = allEvents.where((event) {
            if (_featuredOnly && !event.featured) return false;
            if (_freeOnly && !event.free) return false;

            if (effectiveStateFilter != null &&
                effectiveStateFilter.isNotEmpty &&
                event.stateId != effectiveStateFilter) {
              return false;
            }

            if (effectiveMetroFilter != null &&
                effectiveMetroFilter.isNotEmpty &&
                event.metroId != effectiveMetroFilter) {
              return false;
            }

            if (effectiveAreaFilter != null &&
                effectiveAreaFilter.isNotEmpty &&
                event.areaId != effectiveAreaFilter) {
              return false;
            }

            return true;
          }).toList();

          return Column(
            children: [
              // FILTER BAR (mirrors AdminClubsPage)
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
                          label: const Text('Free events only'),
                          selected: _freeOnly,
                          onSelected: (v) {
                            setState(() => _freeOnly = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // State + Metro filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: effectiveStateFilter,
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
                            value: effectiveMetroFilter,
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
                      value: effectiveAreaFilter,
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

              // LIST (now with thumbnail image)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];

                    final dateText = _formatShortDateTime(event.start);

                    final locationLine = [
                      if (event.city.isNotEmpty) event.city,
                      if (event.venue.isNotEmpty) event.venue,
                      if (event.address.isNotEmpty) event.address,
                    ].join(' • ');

                    final regionLine = [
                      if (event.stateName.isNotEmpty) event.stateName,
                      if (event.metroName.isNotEmpty) event.metroName,
                      if (event.areaName.isNotEmpty) event.areaName,
                    ].join(' • ');

                    final priceText = event.free
                        ? 'Free event'
                        : (event.price > 0
                            ? 'From \$${event.price.toStringAsFixed(2)}'
                            : 'Admission info not set');

                    final thumbUrl = event.imageUrl ?? '';

                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditEventPage(event: event),
                          ),
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: thumbUrl.isNotEmpty
                            ? Image.network(
                                thumbUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: cs.surfaceContainerHighest,
                                  child: const Icon(Icons.event),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: cs.surfaceContainerHighest,
                                child: const Icon(Icons.event),
                              ),
                      ),
                      title: Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: event.featured
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dateText • ${event.category}',
                          ),
                          if (locationLine.isNotEmpty)
                            Text(
                              locationLine,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (regionLine.isNotEmpty)
                            Text(
                              regionLine,
                              style: const TextStyle(fontSize: 11),
                            ),
                          Text(
                            priceText,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  event.free ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Featured pill toggle
                          InkWell(
                            onTap: () async {
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(event.id)
                                  .update({'featured': !event.featured});
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: event.featured
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: event.featured
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    event.featured
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: event.featured
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
                          // Delete
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            color: cs.error,
                            onPressed: () => _confirmDelete(event),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEventPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF146C43),
      ),
    );
  }

  String _formatShortDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year • $h:$m $ampm';
  }

  Future<void> _confirmDelete(Event event) async {
    final ctx = context;
    final ok = await showDialog<bool>(
          context: ctx,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete event?'),
              content: Text(
                'Are you sure you want to delete "${event.title}"? '
                'This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok) return;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" deleted.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
          ),
        );
      }
    }
  }
}
