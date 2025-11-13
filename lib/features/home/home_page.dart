import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 16, bottom: 12),
              title: const Text('VISIT HARALSON'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1482192596544-9eb780fc7f66?q=80&w=1600',
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _quick(context, Icons.explore, 'Explore',
                          () => context.go('/explore')),
                      _quick(context, Icons.restaurant, 'Eat & Drink',
                          () => context.go('/eat')),
                      _quick(context, Icons.hotel, 'Stay', () {}),
                      _quick(context, Icons.event, 'Events',
                          () => context.go('/events')),
                      _quick(context, Icons.group, 'Clubs & Groups', () {})
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search restaurants, trails or festivals…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Near Me',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _nearMeCard(),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.amber.withValues(alpha: .4)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: const Text(
                      'Did You Know?\nBuchanan is home to the historic Haralson County Courthouse (1891).',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _quick(
          BuildContext ctx, IconData icon, String label, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(8), // 10 → 8 gives a bit more room
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon,
                  size: 22,
                  color: Theme.of(ctx).colorScheme.primary), // 24 → 22
              const SizedBox(height: 4), // 6 → 4
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _nearMeCard() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=400',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          title: const Text('Crocked Creek Park'),
          subtitle: const Text('⭐ 4.7 • 3 mi'),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}
