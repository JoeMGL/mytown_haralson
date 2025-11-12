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
          ListTile(title: Text('Dogwood Festival'), subtitle: Text('Tallapoosa • April 13')),
          ListTile(title: Text('Summer Concert Series'), subtitle: Text('Bremen • June 21')),
        ],
      ),
    );
  }
}
