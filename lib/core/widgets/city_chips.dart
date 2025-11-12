import 'package:flutter/material.dart';

enum City { tallapoosa, bremen, buchanan, waco, all }

const cityLabels = {
  City.all: 'All',
  City.tallapoosa: 'Tallapoosa',
  City.bremen: 'Bremen',
  City.buchanan: 'Buchanan',
  City.waco: 'Waco',
};

class CityChips extends StatelessWidget {
  final City selected;
  final ValueChanged<City> onChanged;
  final bool includeAll;
  const CityChips({super.key, required this.selected, required this.onChanged, this.includeAll = true});

  @override
  Widget build(BuildContext context) {
    final values = includeAll ? City.values : City.values.where((c) => c != City.all);
    return Wrap(
      spacing: 8,
      children: values.map((c) => ChoiceChip(
        label: Text(cityLabels[c]!), 
        selected: selected == c,
        onSelected: (_) => onChanged(c),
      )).toList(),
    );
  }
}
