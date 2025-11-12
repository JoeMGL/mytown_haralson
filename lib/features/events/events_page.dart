import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _EventItem(
              month: 'APR',
              day: '13',
              title: 'Dogwood Festival',
              city: 'Tallapoosa'),
          _EventItem(
              month: 'JUN',
              day: '21',
              title: 'Summer Concert Series',
              city: 'Bremen'),
          _EventItem(
              month: 'JUL',
              day: '4',
              title: 'Independence Day Celebration',
              city: 'Buchanan'),
          _EventItem(
              month: 'SEPT',
              day: '18',
              title: 'Haralson County Fair',
              city: '2024'),
        ],
      ),
    );
  }
}

class _EventItem extends StatelessWidget {
  final String month, day, title, city;
  const _EventItem(
      {required this.month,
      required this.day,
      required this.title,
      required this.city});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(month,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(day,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
        title: Text(title),
        subtitle: Text(city),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
