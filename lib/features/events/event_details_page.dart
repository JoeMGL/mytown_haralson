// lib/features/events/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({
    super.key,
    required this.title,
    required this.heroTag,
    required this.description,
    this.imageUrl,
    this.start,
    this.end,
    this.venue,
    this.city,
    this.tags = const [],
    this.website,
    this.mapQuery,
  });

  final String title;
  final String heroTag;
  final String description;

  final String? imageUrl;
  final DateTime? start;
  final DateTime? end;
  final String? venue;
  final String? city;
  final List<String> tags;
  final String? website;
  final String? mapQuery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Safe header URL (mirrors the unsplash helper in ExploreDetailPage)
    final headerUrl = (imageUrl == null || imageUrl!.isEmpty)
        ? null
        : _unsplashSafe(imageUrl!, w: 1600, h: 900, forceJpg: true);

    final dateText = (start == null)
        ? 'Date & time TBA'
        : _formatEventDateRange(start!, end);

    final locationText = [
      if (venue != null && venue!.isNotEmpty) venue,
      if (city != null && city!.isNotEmpty) city,
    ].whereType<String>().join(' • ');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (headerUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: heroTag,
                child: Image.network(
                  headerUrl,
                  fit: BoxFit.cover,
                  height: 220,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 220, color: cs.surfaceContainerHighest),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Title
          Text(
            title,
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

          // Location row (if any)
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

          // Tag chips
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              if ((mapQuery != null && mapQuery!.isNotEmpty) ||
                  locationText.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(),
                    icon: const Icon(Icons.map),
                    label: const Text('View on Map'),
                  ),
                ),
              if (website != null && website!.isNotEmpty) ...[
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
          if (description.isNotEmpty) ...[
            Text(
              'About this event',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  // ---- Helpers ------------------------------------------------------------

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

  // Stub for unsplash-style URLs — safe to use with any image URL.
  String _unsplashSafe(
    String url, {
    int? w,
    int? h,
    bool forceJpg = false,
  }) {
    // If you have a real _unsplashSafe implementation in ExploreDetailPage,
    // you can copy that here. For now we just return the original URL.
    return url;
  }

  Future<void> _openWebsite() async {
    if (website == null || website!.isEmpty) return;
    final uri = Uri.tryParse(
        website!.startsWith('http') ? website! : 'https://${website!}');
    if (uri == null) return;
    await _launchUrl(uri);
  }

  Future<void> _openMaps() async {
    // Prefer explicit mapQuery; fall back to "venue + city + title"
    final query = mapQuery?.isNotEmpty == true
        ? mapQuery!
        : [
            if (venue != null && venue!.isNotEmpty) venue,
            if (city != null && city!.isNotEmpty) city,
            title,
          ].whereType<String>().join(' ');

    if (query.isEmpty) return;

    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    await _launchUrl(uri);
  }

  Future<void> _launchUrl(Uri uri) async {
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
