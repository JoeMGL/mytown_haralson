import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Location filter state
  String _selectedStateId = 'all'; // 'all' = all states
  String _selectedMetroId = 'all'; // 'all' = all metros

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _states = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _metros = [];

  bool _loadingStateFilter = false;
  bool _loadingMetroFilter = false;

  // Stats state
  bool _loadingStats = true;
  String? _statsError;

  int? _exploreCount;
  int? _eatAndDrinkCount;
  int? _lodgingCount;
  int? _eventsCount;
  int? _clubsCount;
  int? _shopsCount;

  @override
  void initState() {
    super.initState();
    _loadStates();
    _loadStats();
  }

  Future<void> _loadStates() async {
    setState(() => _loadingStateFilter = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .orderBy('name')
          .get();

      if (!mounted) return;
      setState(() {
        _states = snap.docs;
        _loadingStateFilter = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStateFilter = false);
      debugPrint('Error loading states for dashboard filter: $e');
    }
  }

  Future<void> _loadMetros() async {
    if (_selectedStateId == 'all') {
      // No state selected → clear metros
      setState(() {
        _metros = [];
        _selectedMetroId = 'all';
      });
      return;
    }

    setState(() {
      _loadingMetroFilter = true;
      _metros = [];
      _selectedMetroId = 'all';
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_selectedStateId)
          .collection('metros')
          .orderBy('sortOrder')
          .get();

      if (!mounted) return;
      setState(() {
        _metros = snap.docs.where((doc) {
          final data = doc.data();
          return (data['isActive'] ?? true) == true;
        }).toList();
        _loadingMetroFilter = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMetroFilter = false);
      debugPrint('Error loading metros for dashboard filter: $e');
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final explore = await _countCollection('attractions'); // Explore
      final eat = await _countCollection('eatAndDrink'); // Eat & Drink
      final lodging = await _countCollection('stays'); // Lodging
      final events = await _countCollection('events'); // Events
      final clubs = await _countCollection('clubs'); // Clubs
      final shops = await _countCollection('shops'); // Shop

      if (!mounted) return;
      setState(() {
        _exploreCount = explore;
        _eatAndDrinkCount = eat;
        _lodgingCount = lodging;
        _eventsCount = events;
        _clubsCount = clubs;
        _shopsCount = shops;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        _statsError = 'Failed to load stats';
      });
      debugPrint('Error loading stats: $e');
    }
  }

  Future<int> _countCollection(
    String path, {
    bool onlyActive = true,
  }) async {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection(path);

    if (onlyActive) {
      q = q.where('active', isEqualTo: true);
    }

    // Apply location filters from the dashboard
    final String? stateFilter =
        _selectedStateId == 'all' ? null : _selectedStateId;
    final String? metroFilter =
        _selectedMetroId == 'all' ? null : _selectedMetroId;

    if (stateFilter != null) {
      q = q.where('stateId', isEqualTo: stateFilter);
    }
    if (metroFilter != null) {
      q = q.where('metroId', isEqualTo: metroFilter);
    }

    final snap = await q.count().get(); // AggregateQuerySnapshot
    return snap.count ?? 0;
  }

  /// Build route with query params for current filters, e.g.
  /// /admin/attractions?stateId=GA&metroId=tallapoosa
  String _buildRouteWithFilters(String basePath) {
    final params = <String, String>{};
    if (_selectedStateId != 'all') {
      params['stateId'] = _selectedStateId;
    }
    if (_selectedMetroId != 'all') {
      params['metroId'] = _selectedMetroId;
    }

    if (params.isEmpty) return basePath;

    final qp = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    return '$basePath?$qp';
  }

  String _formatCount(int? value) {
    if (_loadingStats) return '—';
    if (value == null) return '0';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat(
        label: 'Explore',
        value: _formatCount(_exploreCount),
        icon: Icons.map_outlined,
        onTap: (ctx) {
          if (_loadingStats || _exploreCount == null) return;
          final hasAny = _exploreCount! > 0;
          final basePath =
              hasAny ? '/admin/attractions' : '/admin/attractions/add';
          final route = _buildRouteWithFilters(basePath);
          ctx.go(route);
        },
      ),
      _Stat(
        label: 'Eat & Drink',
        value: _formatCount(_eatAndDrinkCount),
        icon: Icons.restaurant_outlined,
        onTap: (ctx) {
          if (_loadingStats || _eatAndDrinkCount == null) return;
          final hasAny = _eatAndDrinkCount! > 0;
          final basePath = hasAny ? '/admin/eat' : '/admin/eat/add';
          final route = _buildRouteWithFilters(basePath);
          ctx.go(route);
        },
      ),
      _Stat(
        label: 'Lodging',
        value: _formatCount(_lodgingCount),
        icon: Icons.hotel_outlined,
        onTap: (ctx) {
          if (_loadingStats || _lodgingCount == null) return;
          final hasAny = _lodgingCount! > 0;
          final basePath = hasAny ? '/admin/lodging' : '/admin/lodging/add';
          final route = _buildRouteWithFilters(basePath);
          ctx.go(route);
        },
      ),
      _Stat(
        label: 'Events',
        value: _formatCount(_eventsCount),
        icon: Icons.event_outlined,
        onTap: (ctx) {
          // For events we only have /admin/events; AddEvent is opened inside that page.
          if (_loadingStats || _eventsCount == null) return;
          final route = _buildRouteWithFilters('/admin/events');
          ctx.go(route);
        },
      ),
      _Stat(
        label: 'Clubs & Groups',
        value: _formatCount(_clubsCount),
        icon: Icons.groups_outlined,
        onTap: (ctx) {
          if (_loadingStats || _clubsCount == null) return;
          final hasAny = _clubsCount! > 0;
          final basePath = hasAny ? '/admin/clubs' : '/admin/clubs/add';
          final route = _buildRouteWithFilters(basePath);
          ctx.go(route);
        },
      ),
      _Stat(
        label: 'Shop',
        value: _formatCount(_shopsCount),
        icon: Icons.storefront_outlined,
        onTap: (ctx) {
          if (_loadingStats || _shopsCount == null) return;
          final hasAny = _shopsCount! > 0;
          final basePath = hasAny ? '/admin/shops' : '/admin/shops/add';
          final route = _buildRouteWithFilters(basePath);
          ctx.go(route);
        },
      ),
    ];

    // Demo recent rows + announcement (unchanged)
    final rows = const [
      _Row(
        name: 'Helton Howland Park',
        city: 'Tallapoosa',
        category: 'Parks',
        updated: '1 day ago',
      ),
      _Row(
        name: 'Bremen Depot Museum',
        city: 'Bremen',
        category: 'Museums',
        updated: '2 days ago',
      ),
      _Row(
        name: 'Historic Courthouse',
        city: 'Buchanan',
        category: 'Landmarks',
        updated: '2 days ago',
      ),
      _Row(
        name: 'Tally Mountain Golf Course',
        city: 'Tallapoosa',
        category: 'Outdoor Recreation',
        updated: '4 days ago',
      ),
      _Row(
        name: 'Museum on Main',
        city: 'Bremen',
        category: 'Museums',
        updated: '6 days ago',
      ),
    ];

    final announcement = const _Announcement(
      title: 'Dogwood Festival\nNext Weekend',
      scope: 'County-wide',
      date: 'April 12, 2024',
      body:
          'Annual spring Dogwood Festival in downtown Tallapoosa on April 20–21!',
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // Location filters card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter by location',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),

                        // State dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedStateId,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All States'),
                            ),
                            ..._states.map((doc) {
                              final data = doc.data();
                              final name = data['name'] ?? doc.id;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(name),
                              );
                            }),
                          ],
                          onChanged: _loadingStateFilter
                              ? null
                              : (value) async {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedStateId = value;
                                    // When state changes, reset metro
                                    _selectedMetroId = 'all';
                                    _metros = [];
                                  });
                                  await _loadMetros();
                                  await _loadStats();
                                },
                        ),
                        const SizedBox(height: 12),

                        // Metro dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedMetroId,
                          decoration: InputDecoration(
                            labelText: _selectedStateId == 'all'
                                ? 'Metro (select a state first)'
                                : 'Metro',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All Metros'),
                            ),
                            ..._metros.map((doc) {
                              final data = doc.data();
                              final name = data['name'] ?? doc.id;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(name),
                              );
                            }),
                          ],
                          onChanged:
                              (_selectedStateId == 'all' || _loadingMetroFilter)
                                  ? null
                                  : (value) async {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedMetroId = value;
                                      });
                                      await _loadStats();
                                    },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Overview + stats
                Row(
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 12),
                    if (_loadingStats)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_statsError != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _StatGrid(stats: stats),
                const SizedBox(height: 24),

                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _RecentAttractionsCard(rows: rows),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _AnnouncementsCard(announcement: announcement),
                      ),
                    ],
                  )
                else ...[
                  _RecentAttractionsCard(rows: rows),
                  const SizedBox(height: 16),
                  _AnnouncementsCard(announcement: announcement),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---- Stats ---- */
class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final void Function(BuildContext)? onTap;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
}

class _StatGrid extends StatelessWidget {
  final List<_Stat> stats;
  const _StatGrid({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    int columns = 1;
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) {
      columns = 4;
    } else if (w >= 900) {
      columns = 3;
    } else if (w >= 620) {
      columns = 2;
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.2,
      ),
      itemBuilder: (context, i) => _StatCard(stat: stats[i]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: stat.onTap == null ? null : () => stat.onTap!(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat.icon, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stat.value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---- Recent table ---- */
class _Row {
  final String name;
  final String city;
  final String category;
  final String updated;
  const _Row({
    required this.name,
    required this.city,
    required this.category,
    required this.updated,
  });
}

class _RecentAttractionsCard extends StatelessWidget {
  final List<_Row> rows;
  const _RecentAttractionsCard({required this.rows, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Attractions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _AttractionsTable(rows: rows),
          ],
        ),
      ),
    );
  }
}

class _AttractionsTable extends StatelessWidget {
  final List<_Row> rows;
  const _AttractionsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            _th(context, 'Name'),
            _th(context, 'City'),
            _th(context, 'Category'),
            _th(context, 'Updated'),
          ],
        ),
        for (final r in rows) _tr(context, r),
      ],
    );
  }

  Widget _th(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  TableRow _tr(BuildContext context, _Row r) => TableRow(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Text(r.name),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Text(r.city),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Text(r.category),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Text(r.updated),
          ),
        ],
      );
}

/* ---- Announcements ---- */
class _Announcement {
  final String title;
  final String scope;
  final String date;
  final String body;
  const _Announcement({
    required this.title,
    required this.scope,
    required this.date,
    required this.body,
  });
}

class _AnnouncementsCard extends StatelessWidget {
  final _Announcement announcement;
  const _AnnouncementsCard({required this.announcement, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Announcements',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        announcement.scope,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(announcement.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
