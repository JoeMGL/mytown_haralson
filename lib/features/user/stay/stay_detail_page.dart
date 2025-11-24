import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/lodging.dart';
import '../../../widgets/favorite_button.dart';

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

          // Hours (structured first, legacy fallback)
          _buildHoursSection(context),

          const SizedBox(height: 16),

          // Description
          if (stay.description.isNotEmpty) ...[
            Text(
              stay.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // ACTION BUTTONS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (stay.phone != null && stay.phone!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchPhone(stay.phone!),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              if (stay.website != null && stay.website!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(stay.website!),
                  icon: const Icon(Icons.public),
                  label: const Text('Website'),
                ),
              if (stay.mapQuery != null && stay.mapQuery!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    final encoded = Uri.encodeComponent(stay.mapQuery!);
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$encoded';
                    _launchUrl(url);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
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

  // ---------- HOURS ----------

  Widget _buildHoursSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    // Prefer structured hours if present
    final hoursByDay = stay.hoursByDay;
    if (hoursByDay != null && hoursByDay.isNotEmpty) {
      final now = DateTime.now();
      final weekdayKey = _weekdayKey(now.weekday);

      final today = hoursByDay[weekdayKey];
      String label;
      if (today == null || today.closed) {
        label = 'Closed today';
      } else {
        final open = today.open ?? '';
        final close = today.close ?? '';
        if (open.isEmpty && close.isEmpty) {
          label = 'Hours not available';
        } else if (open.isNotEmpty && close.isNotEmpty) {
          label = '$open – $close';
        } else {
          label = (open + ' ' + close).trim();
        }
      }

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's hours",
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Fallback: legacy free-text hours string
    if (stay.hours != null && stay.hours!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stay.hours!,
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _weekdayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
      default:
        return 'sunday';
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
