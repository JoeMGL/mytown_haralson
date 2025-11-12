import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example metrics (wire to Firestore later)
    final metrics = const [
      _Metric(
          label: 'Published Attractions',
          value: '18',
          icon: Icons.park_outlined),
      _Metric(
          label: 'Upcoming Events', value: '12', icon: Icons.event_outlined),
      _Metric(
          label: 'Dining Listings',
          value: '44',
          icon: Icons.restaurant_outlined),
      _Metric(
          label: 'Pending Reviews',
          value: '5',
          icon: Icons.pending_actions_outlined),
    ];

    // Example moderation items
    final queue = const [
      _QueueItem(
          title: 'Ranger-led Hike',
          submitter: 'Parks • Tallapoosa',
          tag: 'Event'),
      _QueueItem(
          title: 'Helton Howland Playground',
          submitter: 'Community',
          tag: 'Attraction'),
      _QueueItem(
          title: 'Santa Fe Taco Tuesday', submitter: 'Santa Fe', tag: 'Dining'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Text('Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                if (kDebugMode)
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // —— SUMMARY GRID (responsive) ——
            LayoutBuilder(
              builder: (context, constraints) {
                // Simple breakpointing
                int columns = 1;
                final w = constraints.maxWidth;
                if (w >= 1200) {
                  columns = 4;
                } else if (w >= 900) {
                  columns = 3;
                } else if (w >= 600) {
                  columns = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (context, i) => _MetricCard(metric: metrics[i]),
                );
              },
            ),

            const SizedBox(height: 24),

            // —— TOOLBAR ——
            Row(
              children: [
                Text('Moderation Queue',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search submissions…',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (q) {
                      // TODO: apply filter
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // —— QUEUE LIST ——
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: queue.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = queue[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(item.tag.characters.first),
                    ),
                    title: Text(item.title),
                    subtitle: Text('${item.tag} • ${item.submitter}'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // TODO: open review screen
                          },
                          child: const Text('Review'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: approve
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Approved: ${item.title}')),
                            );
                          },
                          child: const Text('Approve'),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          onPressed: () {
                            // TODO: reject dialog / reason
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Rejected: ${item.title}')),
                            );
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 48),

            // —— QUICK ACTIONS ——
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Add Attraction',
                  onTap: () async {
                    // Push the add page on top of the dashboard
                    final result = await context.push('/admin/attractions/new');

                    // Optional: show a toast / refresh metrics when returning
                    if (result == 'saved') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attraction created')),
                      );
                      // TODO: trigger a refresh of metrics/queue here
                    }
                  },
                ),
                _QuickAction(
                  icon: Icons.event_available_outlined,
                  label: 'Add Event',
                  onTap: () async {
                    final result = await context
                        .push<Map<String, dynamic>>('/admin/events/add');
                    if (result != null) {
                      await FirebaseFirestore.instance
                          .collection('events')
                          .add({
                        ...result,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Event added successfully')),
                        );
                      }
                    }
                  },
                ),
                _QuickAction(
                  icon: Icons.campaign_outlined,
                  label: 'Add Announcement',
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.push('/admin/settings'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Icon(metric.icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.label,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(
                    metric.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueItem {
  final String title;
  final String submitter;
  final String tag;
  const _QueueItem(
      {required this.title, required this.submitter, required this.tag});
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
