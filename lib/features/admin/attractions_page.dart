import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminAttractionsPage extends StatelessWidget {
  const AdminAttractionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Attractions', style: Theme.of(context).textTheme.headlineMedium),
          ElevatedButton.icon(onPressed: () => context.go('/admin/attractions/add'), icon: const Icon(Icons.add), label: const Text('New Attraction'))
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: ListView(children: const [
              ListTile(title: Text('Helton Howland Park'), subtitle: Text('Tallapoosa • Outdoor'), trailing: Icon(Icons.chevron_right)),
              Divider(height: 0),
              ListTile(title: Text('Bremen Depot Museum'), subtitle: Text('Bremen • Museum'), trailing: Icon(Icons.chevron_right)),
            ]),
          ),
        )
      ]),
    );
  }
}
