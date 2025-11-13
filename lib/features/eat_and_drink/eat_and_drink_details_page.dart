// lib/features/eat_and_drink/eat_and_drink_details_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EatAndDrinkDetailsPage extends StatelessWidget {
  const EatAndDrinkDetailsPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.heroTag,
    required this.description,
    this.hours,
    this.tags = const [],
    this.mapQuery,
    this.phone,
    this.website,
  });

  final String title;
  final String imageUrl;
  final String heroTag;
  final String description;
  final String? hours;
  final List<String> tags;
  final String? mapQuery;
  final String? phone;
  final String? website;

  @override
  Widget build(BuildContext context) {
    final headerUrl = _unsplashSafe(imageUrl, w: 1600, h: 900, forceJpg: true);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: heroTag,
              child: Image.network(
                headerUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title + optional tags
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      labelStyle: const TextStyle(fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),

          // Action buttons: Call / Website / Directions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (phone != null && phone!.trim().isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () => _launchPhone(phone!),
                ),
              if (website != null && website!.trim().isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.language),
                  label: const Text('Website'),
                  onPressed: () => _launchUrl(website!),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Directions'),
                onPressed: () {
                  final q = (mapQuery == null || mapQuery!.isEmpty)
                      ? title
                      : mapQuery!;
                  _openInMaps(q);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hours card
          if (hours != null && hours!.trim().isNotEmpty)
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hours!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hours != null && hours!.trim().isNotEmpty)
            const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Make Unsplash (or similar) image URLs safer for larger headers.
String _unsplashSafe(
  String url, {
  int? w,
  int? h,
  bool forceJpg = false,
}) {
  if (!url.contains('unsplash.com')) return url;
  Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (_) {
    return url;
  }

  final params = Map<String, String>.from(uri.queryParameters);
  if (w != null) params['w'] = '$w';
  if (h != null) params['h'] = '$h';
  if (forceJpg) params['fm'] = 'jpg';

  return uri.replace(queryParameters: params).toString();
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // ignore: avoid_print
    print('Could not launch $url');
  }
}

Future<void> _launchPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (!await launchUrl(uri)) {
    // ignore: avoid_print
    print('Could not launch phone dialer for $phone');
  }
}

Future<void> _openInMaps(String query) async {
  final encoded = Uri.encodeComponent(query);
  final uri =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // ignore: avoid_print
    print('Could not open maps for $query');
  }
}
