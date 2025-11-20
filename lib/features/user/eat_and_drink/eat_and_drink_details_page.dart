import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/eat_and_drink.dart';

import '../../../widgets/claim_banner.dart';

class EatAndDrinkDetailsPage extends StatelessWidget {
  const EatAndDrinkDetailsPage({
    super.key,
    required this.place,
  });

  final EatAndDrink place;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final heroTag =
        place.heroTag.isNotEmpty ? place.heroTag : 'eat_${place.id}';

    final regionLine = [
      if (place.city.isNotEmpty) place.city,
      if (place.stateName.isNotEmpty) place.stateName,
      if (place.metroName.isNotEmpty) place.metroName,
      if (place.areaName.isNotEmpty) place.areaName,
    ].join(' • ');

    final todayHoursText = _formatTodayHours(place);
    final weeklyLines = _formatWeeklyHours(place);

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: heroTag,
              child: place.imageUrl.isNotEmpty
                  ? Image.network(
                      place.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 220,
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.restaurant,
                        size: 64,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            place.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),

          // Category + region
          if (place.category.isNotEmpty || regionLine.isNotEmpty)
            Text(
              [
                if (place.category.isNotEmpty) place.category,
                if (regionLine.isNotEmpty) regionLine,
              ].join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),

          // HOURS: today + optional full week
          if (todayHoursText != null && todayHoursText.isNotEmpty) ...[
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
            const SizedBox(height: 8),
          ],
          if (weeklyLines.isNotEmpty) ...[
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
            const SizedBox(height: 16),
          ] else ...[
            // Legacy fallback: if no structured hours and we have a single string
            if ((place.hours ?? '').isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.hours!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Description
          if (place.description.isNotEmpty) ...[
            Text(
              place.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // ACTION BUTTONS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (place.phone != null && place.phone!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchPhone(place.phone!),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              if (place.website != null && place.website!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(place.website!),
                  icon: const Icon(Icons.public),
                  label: const Text('Website'),
                ),
              if (place.mapQuery != null && place.mapQuery!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    final encoded = Uri.encodeComponent(place.mapQuery!);
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$encoded';
                    _launchUrl(url);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),
              ClaimBanner(
                docPath: 'eatAndDrink/${place.id}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns a string like:
  /// - "Today: 9:00 AM – 5:00 PM"
  /// - "Closed today"
  /// - or falls back to legacy place.hours
  String? _formatTodayHours(EatAndDrink place) {
    final map = place.hoursByDay;
    if (map == null || map.isEmpty) {
      // Fallback to legacy string if you want it to appear here
      return place.hours;
    }

    final now = DateTime.now();
    final weekdayKey = switch (now.weekday) {
      DateTime.monday => 'mon',
      DateTime.tuesday => 'tue',
      DateTime.wednesday => 'wed',
      DateTime.thursday => 'thu',
      DateTime.friday => 'fri',
      DateTime.saturday => 'sat',
      DateTime.sunday => 'sun',
      _ => 'mon',
    };

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

  /// Returns lines like:
  /// - "Mon: Closed"
  /// - "Tue: 9:00 AM – 5:00 PM"
  List<String> _formatWeeklyHours(EatAndDrink place) {
    final map = place.hoursByDay;
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
