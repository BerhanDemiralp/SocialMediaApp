import 'package:flutter_riverpod/flutter_riverpod.dart';

final appAnalyticsProvider = Provider<AppAnalytics>((ref) {
  return const AppAnalytics();
});

class AppAnalytics {
  const AppAnalytics();

  void trackEvent(String name, [Map<String, Object?> properties = const {}]) {
    // Placeholder for real analytics integration.
    // For now, this can be wired to print/logging or a future analytics SDK.
    // ignore: avoid_print
    print('Analytics event: $name $properties');
  }
}

