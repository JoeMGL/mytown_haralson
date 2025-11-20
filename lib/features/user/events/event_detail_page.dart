// lib/features/events/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({
    super.key,
    required this.event,
    this.heroTag,
  });

  final Event event;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Prefer banner if present, else main imageUrl
    final headerUrl = event.bannerImageUrl.isNotEmpty
        ? event.bannerImageUrl
        : (event.imageUrl ?? '');
    final dateText = _formatEventDateRange(event.start, event.end);

    // Build "City, ST ZIP"
    final cityStateZip = _formatCityStateZip(
      city: event.city,
      state: event.state,
      zip: event.zip,
    );

    // Full location line: Venue • Street • City, ST ZIP
    final locationText = [
      if (event.venue.isNotEmpty) event.venue,
      if (event.address.isNotEmpty) event.address,
      if (cityStateZip.isNotEmpty) cityStateZip,
    ].join(' • ');

    final categoryLabel = _formatCategoryLabel(event.category);

    // Build gallery list (exclude header to avoid obvious duplicate)
    final galleryImages = event.galleryImageUrls
        .where((u) => u.isNotEmpty)
        .where((u) => u != headerUrl)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HEADER IMAGE
          if (headerUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      child: Image.network(
                        headerUrl,
                        fit: BoxFit.cover,
                        height: 220,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: cs.surfaceContainerHighest,
                        ),
                      ),
                    )
                  : Image.network(
                      headerUrl,
                      fit: BoxFit.cover,
                      height: 220,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: cs.surfaceContainerHighest,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],

          // 📸 GALLERY
          if (galleryImages.isNotEmpty) ...[
            Text(
              'Photos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = galleryImages[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Title
          Text(
            event.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Date row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.event, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Location
          if (locationText.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locationText,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Category / City chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (event.city.isNotEmpty || event.state.isNotEmpty)
                Chip(
                  label: Text(
                    _formatCityState(
                      city: event.city,
                      state: event.state,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              if (event.category.isNotEmpty)
                Chip(
                  label: Text(categoryLabel),
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
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(),
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                ),
              ),
              if (event.website != null && event.website!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openWebsite(),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Event Website'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (event.description.isNotEmpty) ...[
            Text(
              'About this event',
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

          // ---- Announcements ----
          const SizedBox(height: 24),
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
                  'No announcements at this time.',
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

  // ---- Helpers ----

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

  String _formatCityState({
    required String city,
    required String state,
  }) {
    if (city.isEmpty && state.isEmpty) return '';
    if (city.isEmpty) return state;
    if (state.isEmpty) return city;
    return '$city, $state';
  }

  /// Convert slug to nice label, e.g. "family-fun" → "Family Fun"
  String _formatCategoryLabel(String slug) {
    if (slug.isEmpty) return '';
    final withSpaces = slug.replaceAll('-', ' ');
    return withSpaces
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map(
          (w) => w[0].toUpperCase() + w.substring(1),
        )
        .join(' ');
  }

  Future<void> _openWebsite() async {
    final url = event.website;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps() async {
    final parts = <String>[];

    if (event.venue.isNotEmpty) parts.add(event.venue);
    if (event.address.isNotEmpty) parts.add(event.address);

    final cityStateZip = _formatCityStateZip(
      city: event.city,
      state: event.state,
      zip: event.zip,
    );
    if (cityStateZip.isNotEmpty) parts.add(cityStateZip);

    // Include title as a fallback search hint
    if (event.title.isNotEmpty) parts.add(event.title);

    final query = parts.join(' ');
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
