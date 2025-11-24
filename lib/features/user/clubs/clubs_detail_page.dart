// lib/features/clubs/club_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../models/clubs_model.dart';
import '../../../widgets/favorite_button.dart';
import '/core/analytics/analytics_service.dart'; // 👈 NEW

class ClubDetailPage extends StatelessWidget {
  const ClubDetailPage({super.key, required this.club});

  final Club club;

  void _launchIfNotEmpty(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrlString(uri.toString())) {
      // If LaunchMode isn't available in your import, you can remove the mode parameter.
      await launchUrlString(
        uri.toString(),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  String _buildAddress() {
    final line1 = club.street.trim();
    final city = club.city.trim();
    final state = club.state.trim();
    final zip = club.zip.trim();

    final line2Parts = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (zip.isNotEmpty) zip,
    ];
    final line2 = line2Parts.join(', ');

    if (line1.isEmpty && line2.isEmpty) {
      // fallback to legacy combined address if present
      return club.address;
    }
    if (line1.isNotEmpty && line2.isNotEmpty) {
      return '$line1\n$line2';
    }
    return line1.isNotEmpty ? line1 : line2;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final addressText = _buildAddress();
    final hasBanner = club.bannerImageUrl.isNotEmpty;
    final hasGallery = club.imageUrls.isNotEmpty;
    final hasDescription = club.description.trim().isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // HERO BANNER
          SliverAppBar(
            pinned: true,
            expandedHeight: hasBanner ? 220 : 120,
            actions: [
              FavoriteButton(
                type: 'club',
                itemId: club.id,
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                club.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: hasBanner
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          club.bannerImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: cs.surfaceVariant,
                              child: const Icon(Icons.broken_image, size: 48),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: cs.primaryContainer,
                      child: Center(
                        child: Icon(
                          Icons.group,
                          size: 72,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CATEGORY + FEATURED
                  Row(
                    children: [
                      if (club.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            club.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      if (club.featured) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star, color: cs.primary, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ADDRESS
                  if (addressText.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            addressText,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ABOUT / DESCRIPTION
                  if (hasDescription) ...[
                    Text(
                      'About',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      club.description.trim(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],

                  // IMAGE GALLERY
                  if (hasGallery) ...[
                    Text(
                      'Photos',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: club.imageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final url = club.imageUrls[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: cs.surfaceVariant,
                                  child:
                                      const Icon(Icons.broken_image, size: 28),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],

                  // MEETING INFO
                  if (club.meetingLocation.isNotEmpty ||
                      club.meetingSchedule.isNotEmpty) ...[
                    Text(
                      'Meetings',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (club.meetingLocation.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(club.meetingLocation)),
                        ],
                      ),
                    if (club.meetingSchedule.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(club.meetingSchedule)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                  ],

                  // CONTACT INFO
                  Text(
                    'Contact',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (club.contactName.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(club.contactName),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                  if (club.contactPhone.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(club.contactPhone),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // 📊 phone tap
                        AnalyticsService.logEvent(
                          'club_contact_phone_tap',
                          params: {
                            'club_id': club.id,
                            'club_name': club.name,
                            'phone': club.contactPhone,
                          },
                        );
                        _launchIfNotEmpty('tel:${club.contactPhone}');
                      },
                    ),

                  if (club.contactEmail.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(club.contactEmail),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // 📊 email tap
                        AnalyticsService.logEvent(
                          'club_contact_email_tap',
                          params: {
                            'club_id': club.id,
                            'club_name': club.name,
                            'email': club.contactEmail,
                          },
                        );
                        _launchIfNotEmpty('mailto:${club.contactEmail}');
                      },
                    ),

                  const SizedBox(height: 8),

                  // Website / Facebook buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (club.website.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () {
                            // 📊 website tap
                            AnalyticsService.logEvent(
                              'club_website_tap',
                              params: {
                                'club_id': club.id,
                                'club_name': club.name,
                                'url': club.website,
                              },
                            );
                            _launchIfNotEmpty(club.website);
                          },
                          icon: const Icon(Icons.language),
                          label: const Text('Website'),
                        ),
                      if (club.facebook.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () {
                            // 📊 facebook tap
                            AnalyticsService.logEvent(
                              'club_facebook_tap',
                              params: {
                                'club_id': club.id,
                                'club_name': club.name,
                                'url': club.facebook,
                              },
                            );
                            _launchIfNotEmpty(club.facebook);
                          },
                          icon: const Icon(Icons.facebook),
                          label: const Text('Facebook'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Active state
                  if (!club.active)
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.error),
                        const SizedBox(width: 8),
                        Text(
                          'This club is currently inactive.',
                          style: TextStyle(color: cs.error),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
