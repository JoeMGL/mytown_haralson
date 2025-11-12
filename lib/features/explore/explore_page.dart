import 'package:flutter/material.dart';
import '../../core/widgets/city_chips.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  City city = City.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CityChips(selected: city, onChanged: (c) => setState(() => city = c)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('Helton Howland Park'), subtitle: Text('Tallapoosa • Outdoor')),
                  ListTile(title: Text('Bremen Depot Museum'), subtitle: Text('Bremen • Museum')),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
