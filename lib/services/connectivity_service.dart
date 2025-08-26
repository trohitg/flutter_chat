import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._internal();
    return _instance!;
  }
  
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  // Get stream of connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;
  
  // Get current connection status
  bool get isConnected => _isConnected;
  
  // Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connection status
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        if (kDebugMode) {
          print('Connectivity subscription error: $error');
        }
      },
    );
  }
  
  // Update connection status and notify listeners
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
    
    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);
      
      if (kDebugMode) {
        print('Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}');
        print('Active connections: ${results.map((e) => e.name).join(", ")}');
      }
    }
  }
  
  // Get detailed connection info
  Future<Map<String, dynamic>> getConnectionInfo() async {
    final results = await _connectivity.checkConnectivity();
    
    return {
      'isConnected': _isConnected,
      'connectionTypes': results.map((e) => e.name).toList(),
      'hasWifi': results.contains(ConnectivityResult.wifi),
      'hasMobile': results.contains(ConnectivityResult.mobile),
      'hasEthernet': results.contains(ConnectivityResult.ethernet),
      'hasVpn': results.contains(ConnectivityResult.vpn),
    };
  }
  
  // Check if specific connection type is available
  Future<bool> hasConnectionType(ConnectivityResult type) async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(type);
  }
  
  // Wait for connection to be available
  Future<void> waitForConnection({Duration? timeout}) async {
    if (_isConnected) return;
    
    final completer = Completer<void>();
    late StreamSubscription subscription;
    
    subscription = connectionStream.listen((isConnected) {
      if (isConnected) {
        subscription.cancel();
        completer.complete();
      }
    });
    
    if (timeout != null) {
      Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError(TimeoutException('Connection timeout', timeout));
        }
      });
    }
    
    return completer.future;
  }
  
  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}

// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final String? details;
  
  const NetworkException(this.message, [this.details]);
  
  @override
  String toString() {
    return details != null ? '$message: $details' : message;
  }
}

// Timeout exception
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() {
    return '$message (${timeout.inSeconds}s)';
  }
}