import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/eat_and_drink.dart';

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
                      color: cs.surfaceContainerHighest, // ✅ no surfaceVariant
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

          // (No address here – model has no address field)

          // Hours
          if (place.hours != null && place.hours!.isNotEmpty) ...[
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
