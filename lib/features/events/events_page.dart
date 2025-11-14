import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/event.dart';
import 'event_detail_page.dart';

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

          // Event list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                  return const Center(child: Text('No events found.'));
                }

                final now = DateTime.now();
                final events = docs.map((d) => Event.fromDoc(d)).toList();

                final filtered = events.where((event) {
                  switch (_filter) {
                    case EventFilter.all:
                      return true;
                    case EventFilter.today:
                      return _isSameDay(event.start, now);
                    case EventFilter.weekend:
                      return _isThisWeekend(event.start, now);
                    case EventFilter.upcoming:
                      return event.start.isAfter(now);
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
                    final event = filtered[index];
                    final dateText =
                        _formatEventDateRange(event.start, event.end);

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(
                              event: event,
                              heroTag: 'event-${event.id}',
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
                              offset: const Offset(0, 2),
                              color: cs.shadow.withValues(alpha: 0.08),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DateBadge(date: event.start, colorScheme: cs),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
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
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.venue.isNotEmpty
                                        ? '${event.venue} • ${event.city}'
                                        : event.city,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                  ),
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      event.description,
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isThisWeekend(DateTime date, DateTime now) {
    // weekend = Friday–Sunday of current week
    final weekday = now.weekday; // 1=Mon, 7=Sun
    final monday = now.subtract(Duration(days: weekday - 1));
    final friday = DateTime(monday.year, monday.month, monday.day + 4);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59);

    return !date.isBefore(friday) && !date.isAfter(sunday);
  }

  String _formatEventDateRange(DateTime start, DateTime end) {
    String _format12h(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }

    final datePart = '${_monthAbbrev(start.month)} ${start.day}, ${start.year}';
    final startStr = _format12h(start);
    final endStr = _format12h(end);

    if (_isSameDay(start, end)) {
      return '$datePart • $startStr–$endStr';
    }

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
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.date,
    required this.colorScheme,
  });

  final DateTime date;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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
