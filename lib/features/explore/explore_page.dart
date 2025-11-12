// explore_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/place.dart';

/// Categories for Explore
enum ExploreCategory { outdoor, museums, landmarks, family }

const categoryLabels = {
  ExploreCategory.outdoor: 'Outdoor Recreation',
  ExploreCategory.museums: 'Museums',
  ExploreCategory.landmarks: 'Landmarks',
  ExploreCategory.family: 'Family',
};

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  ExploreCategory cat = ExploreCategory.outdoor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ExploreCategory.values.map((c) {
                final selected = c == cat;
                final cs = Theme.of(context).colorScheme;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      categoryLabels[c]!,
                      style: TextStyle(
                        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    showCheckmark: false,
                    checkmarkColor: Colors.transparent,
                    selectedColor: cs.primary,
                    backgroundColor:
                        cs.surfaceContainerHighest, // updated non-selected fill
                    side: BorderSide(color: cs.outlineVariant),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onSelected: (_) => setState(() => cat = c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Cards
          _placeCard(
            photo:
                'https://images.unsplash.com/photo-1470770903676-69b98201ea1c?q=80&w=800',
            heroTag: 'HeltonHowland',
            title: 'Helton Howland Park',
            subtitle: '4 miles • Wood trail',
            hours: '3:00 AM – 6:00 PM',
            description:
                'A peaceful wooded park in Tallapoosa featuring nature trails, picnic areas, and open fields. Perfect for families and morning walks.',
            tags: const ['Trail', 'Picnic Area', 'Parking', 'Pet Friendly'],
          ),
          _placeCard(
            photo:
                'https://images.unsplash.com/photo-1501706362039-c06b2d715385?q=80&w=800',
            heroTag: 'TallyMtnGolf',
            title: 'Tally Mountain Golf Course',
            subtitle: '5 miles',
            hours: '7:00 AM – 7:00 PM',
            description:
                '18-hole course with rolling hills and a friendly clubhouse. Great for a morning round and afternoon practice.',
            tags: const ['Golf', 'Pro Shop', 'Cart Rental'],
          ),
          _placeCard(
            photo:
                'https://images.unsplash.com/photo-1523419409543-8e91ffd7a2c0?q=80&w=800',
            heroTag: 'BremenDepot',
            title: 'Bremen Depot Museum',
            subtitle: 'In Bremen',
            hours: '10:00 AM – 4:00 PM',
            description:
                'Local history museum in a restored depot. Exhibits highlight rail heritage and regional culture.',
            tags: const ['Museum', 'Historic', 'Guided Tours'],
          ),
        ],
      ),
    );
  }

  /// A single place row card.
  Widget _placeCard({
    required String photo,
    required String heroTag,
    required String title,
    required String subtitle,
    required String description,
    required List<String> tags,
    String? hours,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Hero(
            tag: heroTag,
            child: _netThumb(photo),
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (hours != null)
              Text(hours, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push(
            '/explore/detail',
            extra: Place(
              title: title,
              imageUrl: photo,
              heroTag: heroTag,
              description: description,
              hours: hours,
              tags: tags,
            ),
          );
        },
      ),
    );
  }

  /// 56x56 network thumb with fallbacks (JPEG-safe Unsplash).
  Widget _netThumb(String url) {
    const uiW = 56, uiH = 56;
    const fetchW = 112, fetchH = 112;
    final safeUrl = _unsplashSafe(url, w: fetchW, h: fetchH, forceJpg: true);

    return Image.network(
      safeUrl,
      width: uiW.toDouble(),
      height: uiH.toDouble(),
      fit: BoxFit.cover,
      cacheWidth: fetchW,
      cacheHeight: fetchH,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: uiW.toDouble(),
          height: uiH.toDouble(),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: uiW.toDouble(),
          height: uiH.toDouble(),
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, size: 20),
        );
      },
    );
  }

  /// For Unsplash, ensure decodeable JPEG/crop and target size.
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
