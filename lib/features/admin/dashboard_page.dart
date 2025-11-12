import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final card = (String label, String value) => Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ]),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Row(children: [card('Published Attractions', '18'), card('Upcoming Events', '12'), card('Dining Listings', '44')]),
          const SizedBox(height: 24),
          Text('Moderation Queue', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(child: ListTile(title: const Text('Ranger-led Hike'), subtitle: const Text('Submitted by Parks • Tallapoosa'), trailing: Wrap(spacing: 8, children: [OutlinedButton(onPressed: (){}, child: const Text('Review')), ElevatedButton(onPressed: (){}, child: const Text('Approve'))]))),
        ],
      ),
    );
  }
}
