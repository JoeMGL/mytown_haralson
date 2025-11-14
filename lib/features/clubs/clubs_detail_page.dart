// lib/features/clubs/club_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/clubs_model.dart';

class ClubDetailPage extends StatelessWidget {
  const ClubDetailPage({super.key, required this.club});

  final Club club;

  void _launchIfNotEmpty(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrlString(uri.toString())) {
      await launchUrlString(uri.toString(),
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(club.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            club.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${club.city} • ${club.category}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Meeting info
          if (club.meetingLocation.isNotEmpty ||
              club.meetingSchedule.isNotEmpty) ...[
            Text(
              'Meetings',
              style: Theme.of(context).textTheme.titleMedium,
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

          // Contact info
          Text(
            'Contact',
            style: Theme.of(context).textTheme.titleMedium,
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
                  onPressed: () => _launchIfNotEmpty(club.website),
                  icon: const Icon(Icons.language),
                  label: const Text('Website'),
                ),
              if (club.facebook.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _launchIfNotEmpty(club.facebook),
                  icon: const Icon(Icons.facebook),
                  label: const Text('Facebook'),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Featured badge
          if (club.featured)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.star, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Featured club',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
