// explore_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/place.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          // Category chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExploreCategory.values.map((c) {
                  final selected = c == cat;

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
                      backgroundColor: cs.surfaceContainerHighest,
                      side: BorderSide(color: cs.outlineVariant),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onSelected: (_) => setState(() => cat = c),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Firestore list
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('attractions')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading attractions: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Apply simple category filter based on the string "category"
                final filtered = docs.where((doc) {
                  final data = doc.data();
                  return _matchesCategory(data, cat);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No attractions found yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    final title =
                        (data['title'] ?? data['name'] ?? 'Attraction')
                            .toString();
                    final imageUrl = (data['imageUrl'] ?? '').toString().trim();
                    final heroTag =
                        (data['heroTag'] ?? title).toString().trim();

                    final city = (data['city'] ?? '').toString().trim();
                    final category = (data['category'] ?? '').toString().trim();

                    // Use City • Category as subtitle if available
                    final subtitleParts = <String>[];
                    if (city.isNotEmpty) subtitleParts.add(city);
                    if (category.isNotEmpty) subtitleParts.add(category);
                    final subtitle =
                        subtitleParts.isEmpty ? '' : subtitleParts.join(' • ');

                    final description =
                        (data['description'] ?? '').toString().trim();
                    final hours = (data['hours'] as String?)?.trim();

                    final tags = (data['tags'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .where((e) => e.isNotEmpty)
                            .toList() ??
                        const <String>[];

                    final mapQuery = (data['mapQuery'] as String?)?.trim();

                    return _placeCard(
                      photo: imageUrl,
                      heroTag: heroTag,
                      title: title,
                      subtitle: subtitle,
                      description: description,
                      tags: tags,
                      hours: hours,
                      mapQuery: mapQuery,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Simple mapping of Firestore "category" string to ExploreCategory.
  /// You can tweak this however you like.
  bool _matchesCategory(
    Map<String, dynamic> data,
    ExploreCategory selected,
  ) {
    final catStr = (data['category'] ?? '').toString().toLowerCase();
    final tags = (data['tags'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        const <String>[];

    switch (selected) {
      case ExploreCategory.outdoor:
        // Matches your AddAttraction "Outdoor" category
        return catStr == 'outdoor';
      case ExploreCategory.museums:
        return catStr == 'history' || catStr == 'museum' || catStr == 'museums';
      case ExploreCategory.landmarks:
        return catStr == 'shopping' ||
            catStr == 'landmark' ||
            catStr == 'landmarks';
      case ExploreCategory.family:
        // Either explicitly tagged, or just show everything as a catch-all
        if (tags.any((t) => t.contains('family'))) return true;
        return true; // loosen this if you want a stricter filter
    }
  }

  /// A single place row card built from Firestore data.
  Widget _placeCard({
    required String photo,
    required String heroTag,
    required String title,
    required String subtitle,
    required String description,
    required List<String> tags,
    String? hours,
    String? mapQuery,
  }) {
    // Fallback image if none set
    final effectivePhoto = (photo.isEmpty)
        ? 'https://images.unsplash.com/photo-1470770903676-69b98201ea1c?q=80&w=800'
        : photo;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Hero(
            tag: heroTag,
            child: _netThumb(effectivePhoto),
          ),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) Text(subtitle),
            if (hours != null && hours.isNotEmpty)
              Text(hours, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push(
            '/explore/detail',
            extra: Place(
              title: title,
              imageUrl: effectivePhoto,
              heroTag: heroTag,
              description: description,
              hours: hours,
              tags: tags,
              mapQuery: mapQuery,
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
