import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/lodging.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/claim_banner.dart';
import '../../../core/analytics/analytics_service.dart';

class StayDetailPage extends StatelessWidget {
  const StayDetailPage({
    super.key,
    required this.stay,
  });

  final Stay stay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Use heroTag if present, otherwise fall back to id
    final heroTag = stay.heroTag.isNotEmpty ? stay.heroTag : 'stay_${stay.id}';

    final regionLine = [
      if (stay.city.isNotEmpty) stay.city,
      if (stay.stateName.isNotEmpty) stay.stateName,
      if (stay.metroName.isNotEmpty) stay.metroName,
      if (stay.areaName.isNotEmpty) stay.areaName,
    ].join(' • ');

    final todayHoursText = _formatTodayHours(stay);
    final weeklyLines = _formatWeeklyHours(stay);

    return Scaffold(
      appBar: AppBar(
        title: Text(stay.name),
        actions: [
          // ⭐ Favorite button in the app bar
          FavoriteButton(
            type: 'lodging',
            itemId: stay.id,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: heroTag,
              child: stay.imageUrl.isNotEmpty
                  ? Image.network(
                      stay.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 220,
                      color: cs.surfaceVariant,
                      child: Icon(
                        Icons.hotel,
                        size: 64,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            stay.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),

          // Category + region
          if (stay.category.isNotEmpty || regionLine.isNotEmpty)
            Text(
              [
                if (stay.category.isNotEmpty) stay.category,
                if (regionLine.isNotEmpty) regionLine,
              ].join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),

          // Address
          _buildAddressSection(context),

          // HOURS: today + optional full week
          if (todayHoursText != null && todayHoursText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todayHoursText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          if (weeklyLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Full week hours',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              children: weeklyLines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(
                        left: 32,
                        right: 8,
                        top: 2,
                        bottom: 2,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          line,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            // Fallback legacy hours if no structured hours / weeklyLines
            if (stay.hours != null && stay.hours!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stay.hours!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Description
          if (stay.description.isNotEmpty) ...[
            Text(
              stay.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // ACTION BUTTONS + CLAIM
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (stay.phone != null && stay.phone!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    AnalyticsService.logEvent('stay_call_tap', params: {
                      'stay_id': stay.id,
                      'stay_name': stay.name,
                      'phone': stay.phone ?? '',
                    });
                    _launchPhone(stay.phone!);
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              if (stay.website != null && stay.website!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    AnalyticsService.logEvent('stay_website_tap', params: {
                      'stay_id': stay.id,
                      'stay_name': stay.name,
                      'url': stay.website ?? '',
                    });
                    _launchUrl(stay.website!);
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Website'),
                ),
              if (stay.mapQuery != null && stay.mapQuery!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    AnalyticsService.logEvent('stay_map_tap', params: {
                      'stay_id': stay.id,
                      'stay_name': stay.name,
                      'query': stay.mapQuery ?? '',
                    });
                    final encoded = Uri.encodeComponent(stay.mapQuery!);
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$encoded';
                    _launchUrl(url);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),

              // 🧾 Claim this business
              ClaimBanner(
                docPath: 'stays/${stay.id}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- ADDRESS ----------

  Widget _buildAddressSection(BuildContext context) {
    // Prefer structured street/city/state/zip if available
    final hasStructuredAddress = stay.street.isNotEmpty || stay.zip.isNotEmpty;

    if (!hasStructuredAddress && stay.address.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: hasStructuredAddress
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stay.street.isNotEmpty)
                      Text(
                        stay.street,
                        style: textTheme.bodyMedium,
                      ),
                    Text(
                      [
                        if (stay.city.isNotEmpty) stay.city,
                        if (stay.state.isNotEmpty) stay.state,
                        if (stay.zip.isNotEmpty) stay.zip,
                      ].join(' ').trim(),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                )
              : Text(
                  stay.address,
                  style: textTheme.bodyMedium,
                ),
        ),
      ],
    );
  }

  // ---------- HOURS HELPERS ----------

  /// Short "today" hours string using structured hours if present,
  /// otherwise falls back to legacy `stay.hours`.
  String? _formatTodayHours(Stay stay) {
    final map = stay.hoursByDay;
    if (map == null || map.isEmpty) {
      // fallback to legacy string
      return stay.hours;
    }

    final now = DateTime.now();
    final weekdayKey = _weekdayKey(now.weekday);

    final day = map[weekdayKey];
    if (day == null || day.closed) {
      return 'Closed today';
    }

    final open = (day.open ?? '').trim();
    final close = (day.close ?? '').trim();

    if (open.isEmpty && close.isEmpty) {
      return 'Open today';
    } else if (open.isNotEmpty && close.isNotEmpty) {
      return 'Today: $open – $close';
    } else if (open.isNotEmpty) {
      return 'Today: from $open';
    } else {
      return 'Today: until $close';
    }
  }

  /// Full week lines like "Mon: 9:00 AM – 5:00 PM"
  List<String> _formatWeeklyHours(Stay stay) {
    final map = stay.hoursByDay;
    if (map == null || map.isEmpty) return const [];

    const dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    const labels = <String, String>{
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };

    final lines = <String>[];

    for (final key in dayOrder) {
      final label = labels[key] ?? key;
      final day = map[key];

      if (day == null || day.closed) {
        lines.add('$label: Closed');
        continue;
      }

      final open = (day.open ?? '').trim();
      final close = (day.close ?? '').trim();

      if (open.isEmpty && close.isEmpty) {
        lines.add('$label: Open');
      } else if (open.isNotEmpty && close.isNotEmpty) {
        lines.add('$label: $open – $close');
      } else if (open.isNotEmpty) {
        lines.add('$label: from $open');
      } else {
        lines.add('$label: until $close');
      }
    }

    return lines;
  }

  /// IMPORTANT: use 'mon', 'tue', ... to match how you're storing hoursByDay
  String _weekdayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
      default:
        return 'sun';
    }
  }

  // ---------- LAUNCH HELPERS ----------

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
