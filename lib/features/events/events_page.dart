// lib/features/events/events_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../events/event_details_page.dart';

/// Simple enum for event filters
enum EventFilter { all, today, weekend, upcoming }

const eventFilterLabels = {
  EventFilter.all: 'All',
  EventFilter.today: 'Today',
  EventFilter.weekend: 'This Weekend',
  EventFilter.upcoming: 'Upcoming',
};

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventFilter _filter = EventFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: EventFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(eventFilterLabels[f]!),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _filter = f);
                      },
                      selectedColor: cs.primary.withValues(alpha: .12),
                      labelStyle: TextStyle(
                        color: selected ? cs.primary : cs.onSurface,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Event list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('start') // assume a "start" Timestamp field
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
                  return const Center(child: Text('No events found.'));
                }

                final now = DateTime.now();
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final ts = data['start'];
                  if (ts is! Timestamp) return _filter == EventFilter.all;

                  final dt = ts.toDate();
                  switch (_filter) {
                    case EventFilter.all:
                      return true;
                    case EventFilter.today:
                      return _isSameDay(dt, now);
                    case EventFilter.weekend:
                      return _isThisWeekend(dt, now);
                    case EventFilter.upcoming:
                      return dt.isAfter(now);
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('No events for this filter.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    final title = (data['title'] ??
                        data['name'] ??
                        'Untitled Event') as String;
                    final city = (data['city'] ?? 'Haralson County') as String;
                    final venue = (data['venue'] ?? '') as String;
                    final tsStart = data['start'] as Timestamp?;
                    final tsEnd = data['end'] as Timestamp?;
                    final start = tsStart?.toDate();
                    final end = tsEnd?.toDate();
                    final description = (data['description'] ?? '') as String;

                    final dateText = start != null
                        ? _formatEventDateRange(start, end)
                        : 'Date TBA';

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(
                              title: title,
                              heroTag: 'event-${doc.id}',
                              description: description,
                              imageUrl: data['imageUrl'], // if you store one
                              start: start,
                              end: end,
                              venue: venue,
                              city: city,
                              tags: (data['tags'] as List?)?.cast<String>() ??
                                  const [],
                              website: data['website'],
                              mapQuery: data['mapQuery'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                              color: cs.shadow.withValues(alpha: 0.08),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date badge
                            if (start != null)
                              _DateBadge(date: start, colorScheme: cs)
                            else
                              _DateBadge(date: now, colorScheme: cs, tba: true),
                            const SizedBox(width: 12),
                            // Title + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    venue.isNotEmpty ? '$venue • $city' : city,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers -------------------------------------------------------------

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isThisWeekend(DateTime date, DateTime now) {
    // weekend = Friday–Sunday of the current week
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final monday = now.subtract(Duration(days: weekday - 1));
    final friday = monday.add(const Duration(days: 4));
    final sunday = monday.add(const Duration(days: 6));

    return !date.isBefore(
          DateTime(friday.year, friday.month, friday.day),
        ) &&
        !date.isAfter(
          DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
        );
  }

  String _formatEventDateRange(DateTime start, DateTime? end) {
    String _format12h(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }

    final datePart = '${_monthAbbrev(start.month)} ${start.day}, ${start.year}';
    final startStr = _format12h(start);

    if (end == null) return '$datePart • $startStr';

    final endStr = _format12h(end);

    // Same-day event
    if (_isSameDay(start, end)) {
      return '$datePart • $startStr–$endStr';
    }

    // Multi-day event
    final endDatePart =
        '${_monthAbbrev(end.month)} ${end.day}, ${end.year} $endStr';

    return '$datePart $startStr – $endDatePart';
  }

  String _monthAbbrev(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }

  void _showEventBottomSheet({
    required BuildContext context,
    required String title,
    required String city,
    required String venue,
    required DateTime? start,
    required DateTime? end,
    required String description,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final dateText =
            start != null ? _formatEventDateRange(start, end) : 'Date TBA';

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      dateText,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      venue.isNotEmpty ? '$venue • $city' : city,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.date,
    required this.colorScheme,
    this.tba = false,
  });

  final DateTime date;
  final ColorScheme colorScheme;
  final bool tba;

  @override
  Widget build(BuildContext context) {
    if (tba) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'TBA',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final month = _monthAbbrev(date.month).toUpperCase();
    final day = date.day.toString();

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            day,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _monthAbbrev(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }
}
