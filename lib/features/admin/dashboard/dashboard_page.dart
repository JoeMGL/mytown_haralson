import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = const [
      _Stat(label: 'Attractions', value: '12', icon: Icons.park_outlined),
      _Stat(label: 'Events', value: '8', icon: Icons.event_outlined),
      _Stat(label: 'Dining', value: '15', icon: Icons.restaurant_outlined),
      _Stat(label: 'Lodging', value: '10', icon: Icons.hotel_outlined),
    ];

    final rows = const [
      _Row(
          name: 'Helton Howland Park',
          city: 'Tallapoosa',
          category: 'Parks',
          updated: '1 day ago'),
      _Row(
          name: 'Bremen Depot Museum',
          city: 'Bremen',
          category: 'Museums',
          updated: '2 days ago'),
      _Row(
          name: 'Historic Courthouse',
          city: 'Buchanan',
          category: 'Landmarks',
          updated: '2 days ago'),
      _Row(
          name: 'Tally Mountain Golf Course',
          city: 'Tallapoosa',
          category: 'Outdoor Recreation',
          updated: '4 days ago'),
      _Row(
          name: 'Museum on Main',
          city: 'Bremen',
          category: 'Museums',
          updated: '6 days ago'),
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
                Row(
                  children: [
                    Text('Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const Spacer(),
                    //FilledButton(
                    //  onPressed: () => context.push('/admin/announcements'),
                    //  child: const Text('Add Announcement'),
                    //),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _StatGrid(stats: stats),
                const SizedBox(height: 24),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 3, child: _RecentAttractionsCard(rows: rows)),
                      const SizedBox(width: 16),
                      Expanded(
                          flex: 2,
                          child:
                              _AnnouncementsCard(announcement: announcement)),
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
  const _Stat({required this.label, required this.value, required this.icon});
}

class _StatGrid extends StatelessWidget {
  final List<_Stat> stats;
  const _StatGrid({required this.stats, super.key});
  @override
  Widget build(BuildContext context) {
    int columns = 1;
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200)
      columns = 4;
    else if (w >= 900)
      columns = 3;
    else if (w >= 620) columns = 2;
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(stat.icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(stat.label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(stat.value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ])),
        ]),
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
  const _Row(
      {required this.name,
      required this.city,
      required this.category,
      required this.updated});
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Recent Attractions',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _AttractionsTable(rows: rows),
        ]),
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
        3: FlexColumnWidth(1.5)
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          _th(context, 'Name'),
          _th(context, 'City'),
          _th(context, 'Category'),
          _th(context, 'Updated'),
        ]),
        for (final r in rows) _tr(context, r),
      ],
    );
  }

  Widget _th(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
      );
  TableRow _tr(BuildContext context, _Row r) => TableRow(
        decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Text(r.name)),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Text(r.city)),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Text(r.category)),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Text(r.updated)),
        ],
      );
}

/* ---- Announcements ---- */
class _Announcement {
  final String title;
  final String scope;
  final String date;
  final String body;
  const _Announcement(
      {required this.title,
      required this.scope,
      required this.date,
      required this.body});
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Announcements', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(announcement.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 12),
                Text(announcement.scope,
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              const SizedBox(height: 12),
              Text(announcement.date,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(announcement.body),
            ]),
          ),
        ]),
      ),
    );
  }
}
