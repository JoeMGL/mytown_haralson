// lib/features/stay/stay_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/stay.dart';

class StayDetailPage extends StatelessWidget {
  const StayDetailPage({super.key, required this.stay});

  final Stay stay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(stay.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name + type + city
          Text(
            stay.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${stay.city} · ${stay.type}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),

          if (stay.featured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Featured',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stay.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amenities chips
          Text(
            'Amenities',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (stay.hasBreakfast)
                _amenityChip(context, Icons.free_breakfast, 'Breakfast'),
              if (stay.hasPool) _amenityChip(context, Icons.pool, 'Pool'),
              if (stay.petFriendly)
                _amenityChip(context, Icons.pets, 'Pet Friendly'),
              if (!stay.hasBreakfast && !stay.hasPool && !stay.petFriendly)
                Text(
                  'No amenities listed yet.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact & actions
          Text(
            'Contact & Info',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          if (stay.phone.isNotEmpty)
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone),
              title: Text(stay.phone),
              trailing: TextButton(
                onPressed: () => _launchPhone(stay.phone),
                child: const Text('Call'),
              ),
            ),

          if (stay.website.isNotEmpty)
            ListTile(
              dense: true,
              leading: const Icon(Icons.language),
              title: Text(
                stay.website,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () => _launchWebsite(stay.website),
                child: const Text('Visit'),
              ),
            ),

          ListTile(
            dense: true,
            leading: const Icon(Icons.map),
            title: Text(stay.address),
            trailing: TextButton(
              onPressed: () => _launchMaps('${stay.name}, ${stay.address}'),
              child: const Text('Open in Maps'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: cs.onSecondaryContainer),
      label: Text(label),
      backgroundColor: cs.secondaryContainer,
      labelStyle: TextStyle(color: cs.onSecondaryContainer),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    Uri uri;
    try {
      uri = Uri.parse(url);
      // Add https if missing
      if (!uri.hasScheme) {
        uri = Uri.parse('https://$url');
      }
    } catch (_) {
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
