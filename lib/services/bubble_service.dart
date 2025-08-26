import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BubbleService {
  static const MethodChannel _channel =
      MethodChannel('com.example.flutter_chat/bubble');

  // Cache bubble state to avoid unnecessary calls
  static bool? _cachedBubbleState;
  static bool? _cachedPermissionState;

  static Future<bool> showBubble() async {
    return _executeBubbleOperation('showBubble', () async {
      if (_cachedBubbleState == true) return true; // Already visible
      
      final result = await _channel.invokeMethod<bool>('showBubble') ?? false;
      if (result) _cachedBubbleState = true;
      return result;
    });
  }

  static Future<bool> hideBubble() async {
    return _executeBubbleOperation('hideBubble', () async {
      if (_cachedBubbleState == false) return true; // Already hidden
      
      final result = await _channel.invokeMethod<bool>('hideBubble') ?? false;
      if (result) _cachedBubbleState = false;
      return result;
    });
  }

  static Future<bool> canDrawOverlays() async {
    // Return cached result if available
    if (_cachedPermissionState != null) {
      return _cachedPermissionState!;
    }

    return _executeBubbleOperation('canDrawOverlays', () async {
      final result = await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
      _cachedPermissionState = result;
      return result;
    });
  }

  static Future<bool> requestOverlayPermission() async {
    return _executeBubbleOperation('requestOverlayPermission', () async {
      final result = await _channel.invokeMethod<bool>('requestOverlayPermission') ?? false;
      _cachedPermissionState = result;
      return result;
    });
  }

  // Get current bubble state without platform call
  static bool? get cachedBubbleState => _cachedBubbleState;

  // Clear cache when needed (e.g., app resume)
  static void clearCache() {
    _cachedBubbleState = null;
    _cachedPermissionState = null;
  }

  static Future<T> _executeBubbleOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("BubbleService: $operationName failed - ${e.message}");
      }
      
      // Clear cache on errors to force refresh
      if (operationName.contains('Bubble')) {
        _cachedBubbleState = null;
      } else if (operationName.contains('Overlay')) {
        _cachedPermissionState = null;
      }
      
      return false as T;
    } catch (e) {
      if (kDebugMode) {
        print("BubbleService: Unexpected error in $operationName - $e");
      }
      return false as T;
    }
  }

  // Initialize cache on app start
  static Future<void> initialize() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Pre-load permission state
      await canDrawOverlays();
    }
  }
}