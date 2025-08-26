import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../core/utils/error_handler.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static ChatService? _instance;
  final ApiService _apiService;
  String? _currentSessionId;
  
  static ChatService get instance {
    _instance ??= ChatService._();
    return _instance!;
  }

  ChatService._() : _apiService = ApiService.instance;

  String? get currentSessionId => _currentSessionId;

  Future<void> ensureSession() async {
    if (_currentSessionId == null) {
      await _createSession();
    }
  }

  Future<void> createNewSession() async {
    await _createSession();
  }

  Future<String> sendMessage(String message) async {
    await ensureSession();
    
    try {
      final request = MessageRequest(message: message);
      final response = await _apiService.chatApi.sendMessageToSession(
        _currentSessionId!,
        request,
      );
      
      return response.content;
      
    } on DioException catch (e) {
      if (ErrorHandler.isSessionExpiredError(e)) {
        // Session expired, create new one and retry
        await _createSession();
        final request = MessageRequest(message: message);
        final response = await _apiService.chatApi.sendMessageToSession(
          _currentSessionId!,
          request,
        );
        return response.content;
      }
      
      throw Exception(ErrorHandler.parseApiError(e));
    }
  }

  Future<void> clearSession() async {
    if (_currentSessionId != null) {
      try {
        await _apiService.chatApi.deleteSession(_currentSessionId!);
      } catch (e) {
        if (kDebugMode) print('Failed to delete session: $e');
      }
    }
    
    _currentSessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
  }

  Future<void> _createSession() async {
    try {
      final request = SessionRequest();
      final response = await _apiService.chatApi.createSession(request);
      
      _currentSessionId = response.sessionId;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_id', _currentSessionId!);
      
    } on DioException catch (e) {
      throw Exception(ErrorHandler.parseApiError(e));
    }
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionId = prefs.getString('session_id');
  }

  Future<List<MessageHistoryItem>> getConversationHistory() async {
    if (_currentSessionId == null) {
      return [];
    }

    try {
      final response = await _apiService.chatApi.getSessionMessages(_currentSessionId!);
      return response.messages;
    } on DioException catch (e) {
      if (ErrorHandler.isSessionExpiredError(e)) {
        // Session not found, clear it
        _currentSessionId = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('session_id');
        return [];
      }

      if (ErrorHandler.isNetworkError(e)) {
        throw Exception('Cannot connect to server');
      }

      if (kDebugMode) print('Failed to get conversation history: $e');
      return [];
    } catch (e) {
      if (kDebugMode) print('Failed to get conversation history: $e');
      return [];
    }
  }
}