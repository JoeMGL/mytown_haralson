import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/event.dart';
import '../../../models/category.dart';
import '/core/location/location_provider.dart';
import 'event_detail_page.dart';
import '../../../core/analytics/analytics_service.dart'; // 👈 NEW

enum EventFilter { all, today, weekend, upcoming }

const eventFilterLabels = {
  EventFilter.all: 'All',
  EventFilter.today: 'Today',
  EventFilter.weekend: 'This Weekend',
  EventFilter.upcoming: 'Upcoming',
};

const String kEventsSectionSlug = 'events';

// Simple helper for area options
class _AreaOption {
  final String id; // 'all' for All Areas
  final String name;

  const _AreaOption({required this.id, required this.name});
}

// Helper for category options (slug + label)
class _CategoryOption {
  final String slug; // 'all' for All
  final String label;

  const _CategoryOption({required this.slug, required this.label});
}

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  // Time filter
  EventFilter _filter = EventFilter.upcoming;

  // Area filter (by ID)
  String _selectedAreaId = 'all';
  List<_AreaOption> _areas = const [
    _AreaOption(id: 'all', name: 'All Areas'),
  ];
  bool _loadingAreas = true;

  // Category filter (by slug)
  String _selectedCategorySlug = 'all';
  List<_CategoryOption> _categories = const [
    _CategoryOption(slug: 'all', label: 'All'),
  ];
  bool _loadingCategories = true;
  String? _categoriesError;

  // Track which location we already loaded areas for
  String? _loadedForState;
  String? _loadedForMetro;

  @override
  void initState() {
    super.initState();
    // 📊 Screen view
    AnalyticsService.logView('EventsPage');
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .where('section', isEqualTo: kEventsSectionSlug)
          .orderBy('sortOrder')
          .get();

      final options = <_CategoryOption>[
        const _CategoryOption(slug: 'all', label: 'All'),
        ...snap.docs.map((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString();
          final slug = (data['slug'] ?? '').toString();
          return _CategoryOption(slug: slug, label: name);
        }),
      ];

      setState(() {
        _categories = options;
        _loadingCategories = false;

        final slugs = options.map((c) => c.slug).toSet();
        if (!slugs.contains(_selectedCategorySlug)) {
          _selectedCategorySlug = 'all';
        }
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
        _categoriesError = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _loadAreas(String stateId, String metroId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('metros')
          .doc(metroId)
          .collection('areas')
          .orderBy('name')
          .get();

      final options = <_AreaOption>[
        const _AreaOption(id: 'all', name: 'All Areas'),
        ...snap.docs.map((d) {
          final data = d.data();
          final name = (data['name'] ?? '').toString();
          return _AreaOption(id: d.id, name: name);
        }),
      ];

      setState(() {
        _areas = options;
        _loadingAreas = false;

        final ids = options.map((a) => a.id).toSet();
        if (!ids.contains(_selectedAreaId)) {
          _selectedAreaId = 'all';
        }
      });
    } catch (e) {
      setState(() => _loadingAreas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (loc) {
        if (loc.stateId == null || loc.metroId == null) {
          return const Scaffold(
            body: Center(child: Text('Please select a location')),
          );
        }

        // Load areas only when state/metro changes (prevents infinite loop)
        if (_loadedForState != loc.stateId || _loadedForMetro != loc.metroId) {
          _loadedForState = loc.stateId;
          _loadedForMetro = loc.metroId;

          _loadingAreas = true;
          _loadAreas(loc.stateId!, loc.metroId!);
        }

        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('Events'),
              ),

              // FILTERS
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- AREAS (TOP) ----
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text(
                        'Areas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _loadingAreas
                          ? const LinearProgressIndicator()
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _areas.map((area) {
                                final selected = _selectedAreaId == area.id;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(area.name),
                                  onSelected: (_) {
                                    setState(() => _selectedAreaId = area.id);

                                    // 📊 Area filter change
                                    AnalyticsService.logEvent(
                                      'events_area_filter_changed',
                                      params: {
                                        'state_id': loc.stateId ?? '',
                                        'metro_id': loc.metroId ?? '',
                                        'area_id': area.id,
                                        'area_name': area.name,
                                      },
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // ---- CATEGORIES ----
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCategoryChips(cs, loc.stateId, loc.metroId),
                    ),

                    const SizedBox(height: 20),

                    // ---- TIME FILTER ----
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text(
                        'When',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

                                  // 📊 Time filter change
                                  AnalyticsService.logEvent(
                                    'events_time_filter_changed',
                                    params: {
                                      'state_id': loc.stateId ?? '',
                                      'metro_id': loc.metroId ?? '',
                                      'filter': f.name,
                                    },
                                  );
                                },
                                selectedColor:
                                    cs.primary.withValues(alpha: .12),
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

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // LIST
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('stateId', isEqualTo: loc.stateId)
                    .where('metroId', isEqualTo: loc.metroId)
                    .orderBy('start')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No events found')),
                    );
                  }

                  final now = DateTime.now();
                  final events = docs.map((d) => Event.fromDoc(d)).toList();

                  // Apply time + area + category filters
                  final filtered = events.where((event) {
                    // Time filter
                    final matchTime = switch (_filter) {
                      EventFilter.all => true,
                      EventFilter.today => _isSameDay(event.start, now),
                      EventFilter.weekend => _isThisWeekend(event.start, now),
                      EventFilter.upcoming => event.start.isAfter(now),
                    };
                    if (!matchTime) return false;

                    // Area filter (by areaId)
                    final areaMatches = _selectedAreaId == 'all' ||
                        (event.areaId.isNotEmpty &&
                            event.areaId == _selectedAreaId);
                    if (!areaMatches) return false;

                    // Category filter (slug stored in event.category)
                    final catMatches = _selectedCategorySlug == 'all' ||
                        event.category == _selectedCategorySlug;
                    if (!catMatches) return false;

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text('No events for these filters.'),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final event = filtered[index];
                      final dateText =
                          _formatEventDateRange(event.start, event.end);

                      // Full location line: Venue • Street • City, ST ZIP
                      final cityStateZip = _formatCityStateZip(
                        city: event.city,
                        state: event.state,
                        zip: event.zip,
                      );
                      final parts = <String>[];
                      if (event.venue.isNotEmpty) parts.add(event.venue);
                      if (event.address.isNotEmpty) parts.add(event.address);
                      if (cityStateZip.isNotEmpty) parts.add(cityStateZip);
                      final locationLine = parts.join(' • ');

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // 📊 Event detail view
                            AnalyticsService.logEvent(
                              'view_event_detail',
                              params: {
                                'event_id': event.id,
                                'event_title': event.title,
                                'category_slug': event.category,
                                'area_id': event.areaId,
                                'city': event.city,
                                'state': event.state,
                                'state_id': loc.stateId ?? '',
                                'metro_id': loc.metroId ?? '',
                                'start': event.start.toIso8601String(),
                                'end': event.end.toIso8601String(),
                              },
                            );

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                      if (locationLine.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          locationLine,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                      if (event.description.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          event.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Category chips widget
  Widget _buildCategoryChips(
    ColorScheme cs,
    String? stateId,
    String? metroId,
  ) {
    if (_loadingCategories) {
      return const LinearProgressIndicator();
    }

    if (_categoriesError != null) {
      return Text(
        _categoriesError!,
        style: TextStyle(color: cs.error),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategorySlug == cat.slug;
        return ChoiceChip(
          selected: selected,
          label: Text(cat.label),
          onSelected: (_) {
            setState(() => _selectedCategorySlug = cat.slug);

            // 📊 Category filter change
            AnalyticsService.logEvent(
              'events_category_filter_changed',
              params: {
                'state_id': stateId ?? '',
                'metro_id': metroId ?? '',
                'category_slug': cat.slug,
                'category_label': cat.label,
              },
            );
          },
        );
      }).toList(),
    );
  }

  // Helpers

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

  String _formatCityStateZip({
    required String city,
    required String state,
    required String zip,
  }) {
    if (city.isEmpty && state.isEmpty && zip.isEmpty) return '';

    final cityState = _formatCityState(city: city, state: state);
    if (cityState.isEmpty) return zip;
    if (zip.isEmpty) return cityState;
    return '$cityState $zip';
  }

  String _formatCityState({required String city, required String state}) {
    if (city.isEmpty && state.isEmpty) return '';
    if (city.isEmpty) return state;
    if (state.isEmpty) return city;
    return '$city, $state';
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
