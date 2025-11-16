// lib/widgets/weekly_hours_field.dart
import 'package:flutter/material.dart';

import '../models/place.dart'; // for DayHours

typedef HoursByDay = Map<String, DayHours>;

const _dayLabels = <String, String>{
  'mon': 'Monday',
  'tue': 'Tuesday',
  'wed': 'Wednesday',
  'thu': 'Thursday',
  'fri': 'Friday',
  'sat': 'Saturday',
  'sun': 'Sunday',
};

class WeeklyHoursField extends StatefulWidget {
  final HoursByDay initialValue;
  final ValueChanged<HoursByDay> onChanged;
  final String label;

  const WeeklyHoursField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.label = 'Hours',
  });

  @override
  State<WeeklyHoursField> createState() => _WeeklyHoursFieldState();
}

class _WeeklyHoursFieldState extends State<WeeklyHoursField> {
  late HoursByDay _value;

  @override
  void initState() {
    super.initState();

    // Start with all days present
    _value = {
      for (final entry in _dayLabels.entries)
        entry.key:
            widget.initialValue[entry.key] ?? const DayHours(closed: true),
    };
  }

  String _summaryText() {
    final openDays = _value.entries.where((e) => !e.value.closed).length;
    if (openDays == 0) return 'Closed all week';
    if (openDays == 7) return 'Open every day';
    return 'Open $openDays day(s) per week';
  }

  Future<void> _showHoursDialog() async {
    // Local working copy
    final temp = Map<String, DayHours>.from(_value);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text(widget.label),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _dayLabels.entries.map((entry) {
                      final key = entry.key;
                      final label = entry.value;
                      final day = temp[key] ?? const DayHours(closed: true);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(label),
                              value: !day.closed,
                              onChanged: (isOpen) {
                                setStateDialog(() {
                                  temp[key] = DayHours(
                                    closed: !isOpen,
                                    open: isOpen ? day.open : null,
                                    close: isOpen ? day.close : null,
                                  );
                                });
                              },
                            ),
                            if (!day.closed)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: day.open ?? '',
                                      decoration: const InputDecoration(
                                        labelText: 'Open',
                                        hintText: '9:00 AM',
                                      ),
                                      onChanged: (v) {
                                        setStateDialog(() {
                                          temp[key] = DayHours(
                                            closed: false,
                                            open: v.trim().isEmpty
                                                ? null
                                                : v.trim(),
                                            close: temp[key]?.close,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: day.close ?? '',
                                      decoration: const InputDecoration(
                                        labelText: 'Close',
                                        hintText: '5:00 PM',
                                      ),
                                      onChanged: (v) {
                                        setStateDialog(() {
                                          temp[key] = DayHours(
                                            closed: false,
                                            open: temp[key]?.open,
                                            close: v.trim().isEmpty
                                                ? null
                                                : v.trim(),
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // Normalize all days
                    final normalized = <String, DayHours>{
                      for (final entry in _dayLabels.entries)
                        entry.key:
                            temp[entry.key] ?? const DayHours(closed: true),
                    };

                    setState(() {
                      _value = normalized;
                    });
                    widget.onChanged(_value);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label),
      subtitle: Text(
        _summaryText(),
        style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
      ),
      trailing: OutlinedButton(
        onPressed: _showHoursDialog,
        child: const Text('Edit'),
      ),
    );
  }
}
