import 'package:flutter/foundation.dart';

enum Environment { development, production }

class AppConfig {
  static const Environment _currentEnvironment =
      kDebugMode ? Environment.development : Environment.production;

  // Backend URLs - simplified configuration
  static const Map<Environment, String> _defaultUrls = {
    Environment.development: 'http://localhost:8000',
    Environment.production:
        'http://192.168.29.64:8000', // Use Cloudflare tunnel
  };

  // Platform-specific overrides (Android needs network IP for development)
  static const String _androidDevUrl = 'http://192.168.29.64:8000';

  // Performance settings
  static const Map<Environment, Map<String, dynamic>> _performanceSettings = {
    Environment.development: {
      'messagePageSize': 50,
      'maxCachedMessages': 500,
      'typingIndicatorDelay': 100,
      'enablePerformanceLogging': true,
    },
    Environment.production: {
      'messagePageSize': 100,
      'maxCachedMessages': 1000,
      'typingIndicatorDelay': 50,
      'enablePerformanceLogging': false,
    },
  };

  static String getBackendUrl() {
    if (kIsWeb) {
      return _defaultUrls[_currentEnvironment]!;
    }

    // Special case for Android development
    if (_currentEnvironment == Environment.development &&
        defaultTargetPlatform == TargetPlatform.android) {
      return _androidDevUrl;
    }

    return _defaultUrls[_currentEnvironment]!;
  }

  static T getPerformanceSetting<T>(String key) {
    return _performanceSettings[_currentEnvironment]![key] as T;
  }

  static Environment get currentEnvironment => _currentEnvironment;
  static bool get isProduction => _currentEnvironment == Environment.production;
  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;
}
