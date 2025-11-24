import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/place.dart';
import '../../../widgets/favorite_button.dart'; // ⬅️ existing
import '/core/analytics/analytics_service.dart'; // ⬅️ NEW

class ExploreDetailPage extends StatelessWidget {
  const ExploreDetailPage({
    super.key,
    required this.place,
  });

  final Place place;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final heroTag =
        place.heroTag.isNotEmpty ? place.heroTag : 'place_${place.id}';

    final headerUrl =
        _unsplashSafe(place.imageUrl, w: 1600, h: 900, forceJpg: true);

    final regionLine = [
      if (place.city.isNotEmpty) place.city,
      if (place.stateName.isNotEmpty) place.stateName,
      if (place.metroName.isNotEmpty) place.metroName,
      if (place.areaName.isNotEmpty) place.areaName,
    ].join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: Text(place.title),
        actions: [
          // ⭐ Favorite button in the app bar
          FavoriteButton(
            type: 'attraction', // or 'explore' if you prefer
            itemId: place.id,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: heroTag,
              child: headerUrl.isNotEmpty
                  ? Image.network(
                      headerUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 220,
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.landscape,
                        size: 64,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            place.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          if (place.category.isNotEmpty || regionLine.isNotEmpty)
            Text(
              [
                if (place.category.isNotEmpty) place.category,
                if (regionLine.isNotEmpty) regionLine,
              ].join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
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
          if (place.description.isNotEmpty) ...[
            Text(
              place.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          if (place.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: place.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (place.mapQuery != null && place.mapQuery!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    // 📊 Analytics: user tapped Open in Maps (with stored query)
                    AnalyticsService.logEvent('explore_map_tap', params: {
                      'place_id': place.id,
                      'place_name': place.title,
                      'query': place.mapQuery ?? '',
                    });

                    final encoded = Uri.encodeComponent(place.mapQuery!);
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$encoded';
                    _launchUrl(url);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    // 📊 Analytics: user tapped Search in Maps (fallback to title)
                    AnalyticsService.logEvent('explore_map_search_tap',
                        params: {
                          'place_id': place.id,
                          'place_name': place.title,
                        });

                    final encoded = Uri.encodeComponent(place.title);
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$encoded';
                    _launchUrl(url);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Search in Maps'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _unsplashSafe(
    String url, {
    int w = 1200,
    int h = 800,
    bool forceJpg = false,
  }) {
    if (url.isEmpty) return url;
    if (!url.contains('images.unsplash.com')) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final qp = Map<String, String>.from(uri.queryParameters);
    qp['w'] = '$w';
    qp['h'] = '$h';
    qp['fit'] = 'crop';
    if (forceJpg) qp['fm'] = 'jpg';

    return uri.replace(queryParameters: qp).toString();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
