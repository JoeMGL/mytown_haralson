import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Haralson')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Discover Haralson County', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(onPressed: () => context.go('/explore'), child: const Text('Explore')),
              ElevatedButton(onPressed: () => context.go('/events'), child: const Text('Events')),
              OutlinedButton(onPressed: () => context.go('/admin'), child: const Text('Open Admin (Web)')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('This is a starter screen. Replace with your hero carousel, featured events, etc.'),
        ],
      ),
    );
  }
}
