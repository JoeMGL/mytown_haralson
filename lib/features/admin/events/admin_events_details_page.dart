import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../add_announcement_page.dart'; // adjust path if needed

class AdminEventDetailPage extends StatelessWidget {
  const AdminEventDetailPage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateText = _formatEventDateRange(event.start, event.end);
    final locationText = [
      if (event.venue.isNotEmpty) event.venue,
      if (event.address.isNotEmpty) event.address,
      if (event.city.isNotEmpty) event.city,
    ].join(' • ');

    // ⚠️ No Scaffold here – AdminShell should wrap this
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header row with back + buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddAnnouncementPage(
                        eventId: event.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.campaign),
                label: const Text('Add Announcement'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Basic info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.event,
                    label: 'Date & Time',
                    value: dateText,
                  ),
                  const SizedBox(height: 8),
                  if (locationText.isNotEmpty)
                    _InfoRow(
                      icon: Icons.place,
                      label: 'Location',
                      value: locationText,
                    ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.category,
                    label: 'Category',
                    value: event.category,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_city,
                    label: 'City',
                    value: event.city,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.sell_outlined,
                    label: 'Featured',
                    value: event.featured ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Price',
                    value: event.free
                        ? 'Free'
                        : '\$${event.price.toStringAsFixed(2)}',
                  ),
                  if (event.website != null && event.website!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.link,
                      label: 'Website',
                      value: event.website!,
                      isLink: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description card
          if (event.description.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tags / category chips (for quick scan)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (event.city.isNotEmpty)
                Chip(
                  label: Text(event.city),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              if (event.category.isNotEmpty)
                Chip(
                  label: Text(event.category),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ...event.tags.map(
                (t) => Chip(
                  label: Text(t),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Announcements section
          Text(
            'Announcements',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('eventAnnouncements')
                .where('eventId', isEqualTo: event.id)
                .orderBy('when', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }
              if (snap.hasError) {
                return Text(
                  'Error loading announcements',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.error),
                );
              }

              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text(
                  'No announcements yet for this event.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                );
              }

              return Column(
                children: docs.map((d) {
                  final data = d.data();
                  final title = (data['title'] ?? 'Update') as String;
                  final msg = (data['message'] ?? '') as String;
                  final when = (data['when'] as Timestamp?)?.toDate();

                  String whenText = '';
                  if (when != null) {
                    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
                    final m = when.minute.toString().padLeft(2, '0');
                    final ampm = when.hour >= 12 ? 'PM' : 'AM';
                    whenText =
                        '${when.month}/${when.day}/${when.year} • $h:$m $ampm';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.campaign),
                      title: Text(title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (whenText.isNotEmpty)
                            Text(
                              whenText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          if (msg.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(msg),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- Helpers (unchanged) ----------
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isLink ? cs.primary : cs.onSurface,
                      decoration: isLink
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
