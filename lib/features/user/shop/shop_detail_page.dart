import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/shop.dart';
import '../../../widgets/favorite_button.dart';
import '../../../widgets/claim_banner.dart';
import '../../../core/analytics/analytics_service.dart';

class ShopDetailPage extends StatelessWidget {
  const ShopDetailPage({
    super.key,
    required this.shop,
  });

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final heroTag = 'shop_${shop.id}';

    final regionLine = [
      if (shop.city.isNotEmpty) shop.city,
      if (shop.stateName.isNotEmpty) shop.stateName,
      if (shop.metroName.isNotEmpty) shop.metroName,
      if (shop.areaName.isNotEmpty) shop.areaName,
    ].join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        actions: [
          // ⭐ Favorite button in the app bar
          FavoriteButton(
            type: 'shop', // or 'explore' if you prefer
            itemId: shop.id,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: heroTag,
              child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                  ? Image.network(
                      shop.imageUrl!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 220,
                      color: cs.surfaceVariant,
                      child: Icon(
                        Icons.storefront,
                        size: 64,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            shop.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),

          if (shop.category.isNotEmpty || regionLine.isNotEmpty)
            Text(
              [
                if (shop.category.isNotEmpty) shop.category,
                if (regionLine.isNotEmpty) regionLine,
              ].join(' • '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),

          const SizedBox(height: 12),

          if (shop.address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shop.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

          if (shop.hours != null && shop.hours!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shop.hours!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          if (shop.description.isNotEmpty) ...[
            Text(
              shop.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],

          // ACTION BUTTONS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shop.phone != null && shop.phone!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    // 📊 Analytics: Call tap
                    AnalyticsService.logEvent('shop_call_tap', params: {
                      'shop_id': shop.id,
                      'shop_name': shop.name,
                      'phone': shop.phone ?? '',
                      'city': shop.city,
                      'category': shop.category,
                    });

                    _launchPhone(shop.phone!);
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              if (shop.website != null && shop.website!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    // 📊 Analytics: Website tap
                    AnalyticsService.logEvent('shop_website_tap', params: {
                      'shop_id': shop.id,
                      'shop_name': shop.name,
                      'url': shop.website ?? '',
                      'city': shop.city,
                      'category': shop.category,
                    });

                    _launchUrl(shop.website!);
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('Website'),
                ),
              if (shop.facebook != null && shop.facebook!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    // 📊 Analytics: Facebook tap
                    AnalyticsService.logEvent('shop_facebook_tap', params: {
                      'shop_id': shop.id,
                      'shop_name': shop.name,
                      'url': shop.facebook ?? '',
                      'city': shop.city,
                      'category': shop.category,
                    });

                    _launchUrl(shop.facebook!);
                  },
                  icon: const Icon(Icons.facebook),
                  label: const Text('Facebook'),
                ),
              if (shop.address.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    final encoded = Uri.encodeComponent(shop.address);
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=$encoded';

                    // 📊 Analytics: Map tap
                    AnalyticsService.logEvent('shop_map_tap', params: {
                      'shop_id': shop.id,
                      'shop_name': shop.name,
                      'address': shop.address,
                      'city': shop.city,
                      'category': shop.category,
                    });

                    _launchUrl(url);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Maps'),
                ),

              // 📣 Claim banner (shops can be claimed too)
              ClaimBanner(
                docPath: 'shops/${shop.id}',
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
