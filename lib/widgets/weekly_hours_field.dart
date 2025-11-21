// lib/widgets/weekly_hours_field.dart
import 'package:flutter/material.dart';
import 'package:visit_haralson/models/place.dart'; // for DayHours

/// A map of weekday key -> DayHours, e.g. "mon", "tue", ...
typedef HoursByDay = Map<String, DayHours>;

const _kDayOrder = <String>[
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
  'sun',
];

const _kDayLabels = <String, String>{
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
    _value = _normalize(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant WeeklyHoursField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = _normalize(widget.initialValue);
    }
  }

  HoursByDay _normalize(HoursByDay input) {
    final map = <String, DayHours>{};
    for (final key in _kDayOrder) {
      map[key] = input[key] ?? const DayHours(closed: true);
    }
    return map;
  }

  void _setDay(
    String key, {
    bool? closed,
    String? open,
    String? close,
  }) {
    final current = _value[key] ?? const DayHours(closed: true);

    final next = DayHours(
      closed: closed ?? current.closed,
      open: open ?? current.open,
      close: close ?? current.close,
    );

    setState(() {
      _value = {
        ..._value,
        key: next,
      };
    });

    widget.onChanged(_value);
  }

  String _labelForDay(DayHours dh) {
    if (dh.closed) return 'Closed';
    if (dh.open == null && dh.close == null) return 'Hours not set';
    if (dh.open == null) return 'Closes ${dh.close}';
    if (dh.close == null) return 'Opens ${dh.open}';
    return '${dh.open} – ${dh.close}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final key in _kDayOrder)
                _DayRow(
                  dayKey: key,
                  label: _kDayLabels[key] ?? key,
                  hours: _value[key] ?? const DayHours(closed: true),
                  colorScheme: cs,
                  onChanged: (updated) {
                    _setDay(
                      key,
                      closed: updated.closed,
                      open: updated.open,
                      close: updated.close,
                    );
                  },
                  displayLabel: _labelForDay(
                    _value[key] ?? const DayHours(closed: true),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String dayKey;
  final String label;
  final DayHours hours;
  final ColorScheme colorScheme;
  final void Function(DayHours) onChanged;
  final String displayLabel;

  const _DayRow({
    required this.dayKey,
    required this.label,
    required this.hours,
    required this.colorScheme,
    required this.onChanged,
    required this.displayLabel,
  });

  @override
  Widget build(BuildContext context) {
    // REVERSED MEANING:
    // toggle ON  = OPEN
    // toggle OFF = CLOSED
    final isOpen = !hours.closed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(label),
                  subtitle: Text(displayLabel),
                ),
              ),

              //
              // 🔄 reversed toggle meaning
              //
              Switch(
                value: isOpen,
                onChanged: (v) {
                  if (v == true) {
                    // switched ON → now OPEN
                    onChanged(
                      DayHours(
                        closed: false,
                        open: hours.open,
                        close: hours.close,
                      ),
                    );
                  } else {
                    // switched OFF → now CLOSED
                    onChanged(const DayHours(closed: true));
                  }
                },
              ),

              const SizedBox(width: 8),
            ],
          ),

          // Only show Open/Close fields when OPEN
          if (isOpen)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: hours.open,
                      decoration: const InputDecoration(
                        labelText: 'Open',
                        hintText: 'e.g. 9:00 AM',
                      ),
                      onChanged: (v) {
                        onChanged(
                          DayHours(
                            closed: false,
                            open: v.trim().isEmpty ? null : v.trim(),
                            close: hours.close,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: hours.close,
                      decoration: const InputDecoration(
                        labelText: 'Close',
                        hintText: 'e.g. 5:00 PM',
                      ),
                      onChanged: (v) {
                        onChanged(
                          DayHours(
                            closed: false,
                            open: hours.open,
                            close: v.trim().isEmpty ? null : v.trim(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),
        ],
      ),
    );
  }
}
