// lib/models/place.dart
class Place {
  final String title;
  final String imageUrl;
  final String heroTag;
  final String description;
  final String? hours;
  final List<String> tags;
  final String? mapQuery;

  Place({
    required this.title,
    required this.imageUrl,
    required this.heroTag,
    required this.description,
    this.hours,
    this.tags = const [],
    this.mapQuery,
  });
}
