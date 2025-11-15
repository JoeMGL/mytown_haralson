import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';
import '../events/admin_add_event_page.dart'; // adjust import path if needed
import 'admin_events_details_page.dart'; // for quick “view” from admin

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // AdminShell provides Scaffold/AppBar – we just return content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Text(
              'Events',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEventPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
            ),
          ],
        ),
        const SizedBox(height: 16),

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
                return const Center(
                  child: Text('No events added yet.'),
                );
              }

              final events = docs.map((d) => Event.fromDoc(d)).toList();

              // Table-style layout like your clubs admin
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 40,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('City')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Starts')),
                      DataColumn(label: Text('Featured')),
                      DataColumn(label: Text('Free')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: events.map((event) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(event.city)),
                          DataCell(Text(event.category)),
                          DataCell(Text(_formatShortDateTime(event.start))),
                          DataCell(
                            Icon(
                              event.featured
                                  ? Icons.star
                                  : Icons.star_border_outlined,
                              size: 18,
                              color: event.featured
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          DataCell(
                            Icon(
                              event.free
                                  ? Icons.check_circle
                                  : Icons.attach_money,
                              size: 18,
                              color:
                                  event.free ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'View',
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AdminEventDetailPage(
                                          event: event,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // TODO: Add edit page later if you want full CRUD
                                // IconButton(
                                //   tooltip: 'Edit',
                                //   icon: const Icon(Icons.edit),
                                //   onPressed: () { ... },
                                // ),

                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline),
                                  color: cs.error,
                                  onPressed: () => _confirmDelete(event),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
