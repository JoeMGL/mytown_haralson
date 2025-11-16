import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/stay.dart';

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
          if (stay.address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stay.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

          // Hours
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
