import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  /// LOG SCREEN VIEW
  static Future<void> logView(String screenName, {String? screenClass}) {
    return analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /// LOG EVENTS (Firebase requires Map<String, Object>)
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? params,
  }) async {
    // Remove null values to satisfy Firebase
    final filteredParams = params == null
        ? null
        : params.map((key, value) {
            if (value == null) return MapEntry(key, "null");
            return MapEntry(key, value);
          });

    return analytics.logEvent(
      name: name,
      parameters: filteredParams,
    );
  }
}
