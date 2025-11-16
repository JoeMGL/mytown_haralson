import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocationValue {
  final String? stateId;
  final String? stateName;
  final String? metroId;
  final String? metroName;
  final String? areaId;
  final String? areaName;

  const LocationValue({
    this.stateId,
    this.stateName,
    this.metroId,
    this.metroName,
    this.areaId,
    this.areaName,
  });

  LocationValue copyWith({
    String? stateId,
    String? stateName,
    String? metroId,
    String? metroName,
    String? areaId,
    String? areaName,
  }) {
    return LocationValue(
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      metroId: metroId ?? this.metroId,
      metroName: metroName ?? this.metroName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
    );
  }
}

/// Shared selector for State → Metro → Area.
///
/// - Uses `states/{stateId}`
/// - `states/{stateId}/metros/{metroId}` (filtered by isActive, ordered by sortOrder)
/// - `states/{stateId}/metros/{metroId}/areas/{areaId}`
///
/// Supports initial values for edit pages.
class LocationSelector extends StatefulWidget {
  const LocationSelector({
    super.key,
    this.initialStateId,
    this.initialMetroId,
    this.initialAreaId,
    required this.onChanged,
    this.showTitle = true,
  });

  final String? initialStateId;
  final String? initialMetroId;
  final String? initialAreaId;

  final ValueChanged<LocationValue> onChanged;
  final bool showTitle;

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String? _stateId;
  String? _stateName;
  String? _metroId;
  String? _metroName;
  String? _areaId;
  String? _areaName;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _states = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _metros = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _areas = [];

  bool _loadingStates = false;
  bool _loadingMetros = false;
  bool _loadingAreas = false;

  bool _didApplyInitialMetros = false;
  bool _didApplyInitialAreas = false;

  @override
  void initState() {
    super.initState();
    _stateId = widget.initialStateId;
    _metroId = widget.initialMetroId;
    _areaId = widget.initialAreaId;
    _loadStates();
  }

  void _emit() {
    widget.onChanged(
      LocationValue(
        stateId: _stateId,
        stateName: _stateName,
        metroId: _metroId,
        metroName: _metroName,
        areaId: _areaId,
        areaName: _areaName,
      ),
    );
  }

  Future<void> _loadStates() async {
    setState(() => _loadingStates = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .orderBy('name')
          .get();

      if (!mounted) return;
      setState(() {
        _states = snap.docs;
        _loadingStates = false;
      });

      // If we have an initial state, apply it and load metros
      if (_stateId != null) {
        final doc = _states
            .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
            .firstWhere(
              (d) => d?.id == _stateId,
              orElse: () => null,
            );
        if (doc != null) {
          final data = doc.data();
          _stateName = data['name'] ?? '';
          await _loadMetros(fromInit: true);
        } else {
          // State not found in list, clear it
          _stateId = null;
          _stateName = null;
          _emit();
        }
      } else {
        _emit();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStates = false);
      debugPrint('Error loading states: $e');
    }
  }

  Future<void> _loadMetros({bool fromInit = false}) async {
    if (_stateId == null) return;

    setState(() {
      _loadingMetros = true;
      _metros = [];
      // Only clear current selection if *not* applying initial values
      if (!fromInit) {
        _metroId = null;
        _metroName = null;
        _areas = [];
        _areaId = null;
        _areaName = null;
      }
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_stateId)
          .collection('metros')
          .orderBy('sortOrder')
          .get();

      if (!mounted) return;
      setState(() {
        _metros = snap.docs.where((doc) {
          final data = doc.data();
          return (data['isActive'] ?? true) == true;
        }).toList();
        _loadingMetros = false;
      });

      // If we're initializing and have an initialMetroId, apply it once
      if (fromInit &&
          !_didApplyInitialMetros &&
          widget.initialMetroId != null &&
          _metros.isNotEmpty) {
        final match = _metros
            .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
            .firstWhere(
              (d) => d?.id == widget.initialMetroId,
              orElse: () => null,
            );
        if (match != null) {
          final data = match.data();
          setState(() {
            _metroId = match.id;
            _metroName = data['name'] ?? match.id;
            _didApplyInitialMetros = true;
          });
          _emit();
          await _loadAreas(fromInit: true);
        } else {
          _emit();
        }
      } else {
        _emit();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMetros = false);
      debugPrint('Error loading metros: $e');
    }
  }

  Future<void> _loadAreas({bool fromInit = false}) async {
    if (_stateId == null || _metroId == null) return;

    setState(() {
      _loadingAreas = true;
      _areas = [];
      if (!fromInit) {
        _areaId = null;
        _areaName = null;
      }
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('states')
          .doc(_stateId)
          .collection('metros')
          .doc(_metroId)
          .collection('areas')
          .orderBy('name')
          .get();

      if (!mounted) return;
      setState(() {
        _areas = snap.docs;
        _loadingAreas = false;
      });

      if (fromInit &&
          !_didApplyInitialAreas &&
          widget.initialAreaId != null &&
          _areas.isNotEmpty) {
        final match = _areas
            .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
            .firstWhere(
              (d) => d?.id == widget.initialAreaId,
              orElse: () => null,
            );
        if (match != null) {
          final data = match.data();
          setState(() {
            _areaId = match.id;
            _areaName = data['name'] ?? match.id;
            _didApplyInitialAreas = true;
          });
        }
      }

      _emit();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAreas = false);
      debugPrint('Error loading areas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (widget.showTitle) {
      children.addAll([
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
      ]);
    }

    // STATE
    children.add(
      DropdownButtonFormField<String>(
        value: _stateId,
        decoration: const InputDecoration(
          labelText: 'State',
          border: OutlineInputBorder(),
        ),
        isExpanded: true,
        items: _states.map((doc) {
          final data = doc.data();
          final name = data['name'] ?? doc.id;
          return DropdownMenuItem(
            value: doc.id,
            child: Text(name),
          );
        }).toList(),
        onChanged: _loadingStates
            ? null
            : (value) async {
                setState(() {
                  _stateId = value;
                  if (value != null) {
                    final doc = _states.firstWhere((d) => d.id == value);
                    final data = doc.data();
                    _stateName = data['name'] ?? '';
                  } else {
                    _stateName = null;
                  }

                  // reset lower levels
                  _metros = [];
                  _metroId = null;
                  _metroName = null;
                  _areas = [];
                  _areaId = null;
                  _areaName = null;
                  _didApplyInitialMetros = false;
                  _didApplyInitialAreas = false;
                });

                _emit();
                await _loadMetros(fromInit: false);
              },
      ),
    );

    children.add(const SizedBox(height: 12));

    // METRO
    children.add(
      DropdownButtonFormField<String>(
        value: _metroId,
        decoration: InputDecoration(
          labelText: _loadingMetros ? 'Loading metros…' : 'Metro',
          border: const OutlineInputBorder(),
        ),
        isExpanded: true,
        items: _metros.map((doc) {
          final data = doc.data();
          final name = data['name'] ?? doc.id;
          return DropdownMenuItem(
            value: doc.id,
            child: Text(name),
          );
        }).toList(),
        onChanged: (_metros.isEmpty || _loadingMetros)
            ? null
            : (value) async {
                setState(() {
                  _metroId = value;
                  if (value != null) {
                    final doc = _metros.firstWhere((d) => d.id == value);
                    final data = doc.data();
                    _metroName = data['name'] ?? '';
                  } else {
                    _metroName = null;
                  }

                  _areas = [];
                  _areaId = null;
                  _areaName = null;
                  _didApplyInitialAreas = false;
                });

                _emit();
                await _loadAreas(fromInit: false);
              },
      ),
    );

    children.add(const SizedBox(height: 12));

    // AREA
    children.add(
      DropdownButtonFormField<String>(
        value: _areaId,
        decoration: InputDecoration(
          labelText: _loadingAreas ? 'Loading areas…' : 'Area',
          border: const OutlineInputBorder(),
        ),
        isExpanded: true,
        items: _areas.map((doc) {
          final data = doc.data();
          final name = data['name'] ?? doc.id;
          return DropdownMenuItem(
            value: doc.id,
            child: Text(name),
          );
        }).toList(),
        onChanged: (_areas.isEmpty || _loadingAreas)
            ? null
            : (value) {
                setState(() {
                  _areaId = value;
                  if (value != null) {
                    final doc = _areas.firstWhere((d) => d.id == value);
                    final data = doc.data();
                    _areaName = data['name'] ?? '';
                  } else {
                    _areaName = null;
                  }
                });

                _emit();
              },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
