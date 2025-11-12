import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminAnnouncementsPage extends StatelessWidget {
  const AdminAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Announcements', style: Theme.of(context).textTheme.headlineMedium),
          ElevatedButton.icon(onPressed: () => context.go('/admin/announcements/add'), icon: const Icon(Icons.add_alert_outlined), label: const Text('Compose'))
        ]),
        const SizedBox(height: 12),
        Expanded(child: Card(child: ListView(children: const [
          ListTile(title: Text('Parade route changes on Saturday'), subtitle: Text('County-wide • Scheduled')),
          Divider(height: 0),
          ListTile(title: Text('Farmers Market opens at 9am'), subtitle: Text('Tallapoosa • Draft')),
        ])))
      ]),
    );
  }
}
