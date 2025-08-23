import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class PerformanceMonitor {
  static final Map<String, int> _rebuildCounts = {};
  static final Map<String, DateTime> _lastRebuildTimes = {};
  
  /// Track widget rebuilds in development mode
  static void trackRebuild(String widgetName) {
    if (!AppConfig.getPerformanceSetting<bool>('enablePerformanceLogging')) {
      return;
    }
    
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
    _lastRebuildTimes[widgetName] = DateTime.now();
    
    if (kDebugMode) {
      final count = _rebuildCounts[widgetName]!;
      if (count % 10 == 0) { // Log every 10th rebuild
        debugPrint('Performance: $widgetName rebuilt $count times');
      }
    }
  }
  
  /// Track expensive operations
  static Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!AppConfig.getPerformanceSetting<bool>('enablePerformanceLogging')) {
      return operation();
    }
    
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      
      if (kDebugMode && stopwatch.elapsedMilliseconds > 100) {
        debugPrint('Performance: $operationName took ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('Performance: $operationName failed after ${stopwatch.elapsedMilliseconds}ms');
      }
      rethrow;
    }
  }
  
  /// Get performance stats (development only)
  static Map<String, dynamic> getStats() {
    if (!AppConfig.isDevelopment) return {};
    
    return {
      'rebuildCounts': Map.from(_rebuildCounts),
      'totalRebuilds': _rebuildCounts.values.fold(0, (a, b) => a + b),
      'mostActiveWidget': _rebuildCounts.entries
          .fold<MapEntry<String, int>?>(null, (prev, curr) {
        if (prev == null || curr.value > prev.value) return curr;
        return prev;
      })?.key,
    };
  }
  
  /// Clear performance data
  static void clearStats() {
    _rebuildCounts.clear();
    _lastRebuildTimes.clear();
  }
}