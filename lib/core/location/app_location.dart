import 'package:flutter/foundation.dart';

class AppLocation {
  final String? stateId;
  final String? metroId;
  final String? areaId;

  const AppLocation({
    this.stateId,
    this.metroId,
    this.areaId,
  });

  bool get isComplete => stateId != null && metroId != null && areaId != null;

  factory AppLocation.fromData(Map<String, dynamic>? data) {
    if (data == null) return const AppLocation();

    final app = (data['app'] ?? {}) as Map<String, dynamic>;
    final dev = (data['dev'] ?? {}) as Map<String, dynamic>;
    final loc = (app['defaultLocation'] ?? {}) as Map<String, dynamic>;

    // Live/default
    String? stateId = loc['stateId'] as String?;
    String? metroId = loc['metroId'] as String?;
    String? areaId = loc['areaId'] as String?;

    // Dev overrides ONLY in debug
    if (kDebugMode) {
      stateId = dev['stateId'] as String? ?? stateId;
      metroId = dev['metroId'] as String? ?? metroId;
      areaId = dev['areaId'] as String? ?? areaId;
    }

    return AppLocation(
      stateId: stateId,
      metroId: metroId,
      areaId: areaId,
    );
  }
}
