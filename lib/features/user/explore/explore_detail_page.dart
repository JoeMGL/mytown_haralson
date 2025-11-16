// explore_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreDetailPage extends StatelessWidget {
  const ExploreDetailPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.heroTag,
    required this.description,
    this.hours,
    this.tags = const [],
    this.mapQuery, // optional custom maps query string
  });

  final String title;
  final String imageUrl;
  final String heroTag;
  final String description;
  final String? hours;
  final List<String> tags;
  final String? mapQuery;

  @override
  Widget build(BuildContext context) {
    // Larger image size for header
    final headerUrl = _unsplashSafe(imageUrl, w: 1600, h: 900, forceJpg: true);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: heroTag,
              child: Image.network(
                headerUrl,
                fit: BoxFit.cover,
                height: 220,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (hours != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text(hours!,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 20),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: -4,
              children: tags.map((t) => Chip(label: Text(t))).toList(),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openMaps(),
            icon: const Icon(Icons.map),
            label: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps() async {
    final q = Uri.encodeComponent(mapQuery ?? title);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _unsplashSafe(
    String url, {
    required int w,
    required int h,
    bool forceJpg = false,
  }) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'images.unsplash.com') return url;

    final qp = Map<String, String>.from(uri.queryParameters)
      ..putIfAbsent('auto', () => 'format')
      ..putIfAbsent('fit', () => 'crop')
      ..putIfAbsent('w', () => '$w')
      ..putIfAbsent('h', () => '$h')
      ..putIfAbsent('q', () => '80');
    if (forceJpg) qp.putIfAbsent('fm', () => 'jpg');

    return uri.replace(queryParameters: qp).toString();
  }
}
