import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppLifecycleService {
  static const String _chatHistoryKey = 'chat_history';
  static const String _appStateKey = 'app_state';
  static const String _bubbleStateKey = 'bubble_enabled';
  
  static AppLifecycleService? _instance;
  static AppLifecycleService get instance {
    _instance ??= AppLifecycleService._internal();
    return _instance!;
  }
  
  AppLifecycleService._internal();
  
  SharedPreferences? _prefs;
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Listen to system lifecycle events
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (kDebugMode) {
        print('System lifecycle: $message');
      }
      
      switch (message) {
        case 'AppLifecycleState.paused':
          await _onAppPaused();
          break;
        case 'AppLifecycleState.resumed':
          await _onAppResumed();
          break;
        case 'AppLifecycleState.detached':
          await _onAppDetached();
          break;
        case 'AppLifecycleState.inactive':
          await _onAppInactive();
          break;
      }
      return null;
    });
  }
  
  // Save chat history to persistent storage
  Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    if (_prefs == null) return;
    
    try {
      final String encoded = jsonEncode(messages);
      await _prefs!.setString(_chatHistoryKey, encoded);
      
      if (kDebugMode) {
        print('Chat history saved: ${messages.length} messages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving chat history: $e');
      }
    }
  }
  
  // Load chat history from persistent storage
  Future<List<Map<String, dynamic>>> loadChatHistory() async {
    if (_prefs == null) return [];
    
    try {
      final String? encoded = _prefs!.getString(_chatHistoryKey);
      if (encoded != null) {
        final List<dynamic> decoded = jsonDecode(encoded);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat history: $e');
      }
    }
    
    return [];
  }
  
  // Save app state
  Future<void> saveAppState(Map<String, dynamic> state) async {
    if (_prefs == null) return;
    
    try {
      final String encoded = jsonEncode(state);
      await _prefs!.setString(_appStateKey, encoded);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving app state: $e');
      }
    }
  }
  
  // Load app state
  Future<Map<String, dynamic>> loadAppState() async {
    if (_prefs == null) return {};
    
    try {
      final String? encoded = _prefs!.getString(_appStateKey);
      if (encoded != null) {
        return Map<String, dynamic>.from(jsonDecode(encoded));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading app state: $e');
      }
    }
    
    return {};
  }
  
  // Save bubble state
  Future<void> saveBubbleState(bool enabled) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_bubbleStateKey, enabled);
  }
  
  // Load bubble state
  Future<bool> loadBubbleState() async {
    if (_prefs == null) return false;
    return _prefs!.getBool(_bubbleStateKey) ?? false;
  }
  
  // Clear all app data
  Future<void> clearAppData() async {
    if (_prefs == null) return;
    
    await _prefs!.remove(_chatHistoryKey);
    await _prefs!.remove(_appStateKey);
    await _prefs!.remove(_bubbleStateKey);
    
    if (kDebugMode) {
      print('App data cleared');
    }
  }
  
  // Private lifecycle handlers
  Future<void> _onAppPaused() async {
    if (kDebugMode) {
      print('App paused - saving state');
    }
    // State is saved automatically by the UI components
  }
  
  Future<void> _onAppResumed() async {
    if (kDebugMode) {
      print('App resumed - restoring state');
    }
    // State is loaded automatically by the UI components
  }
  
  Future<void> _onAppInactive() async {
    if (kDebugMode) {
      print('App inactive');
    }
  }
  
  Future<void> _onAppDetached() async {
    if (kDebugMode) {
      print('App detached - final cleanup');
    }
    // Perform final cleanup
  }
}