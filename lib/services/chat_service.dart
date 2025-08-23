import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
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

  Future<void> ensureSession() async {
    if (_currentSessionId == null) {
      await _createSession();
    }
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
      if (e.response?.statusCode == 404) {
        // Session expired, create new one and retry
        await _createSession();
        final request = MessageRequest(message: message);
        final response = await _apiService.chatApi.sendMessageToSession(
          _currentSessionId!,
          request,
        );
        return response.content;
      }
      
      // Parse structured error response if available
      String errorMessage = _parseErrorMessage(e);
      throw Exception(errorMessage);
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
      String errorMessage = _parseErrorMessage(e);
      throw Exception(errorMessage);
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
      if (e.response?.statusCode == 404) {
        // Session not found, clear it
        _currentSessionId = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('session_id');
        return [];
      }

      // Handle other network errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Cannot connect to server');
      }

      if (kDebugMode) print('Failed to get conversation history: $e');
      return [];
    } catch (e) {
      if (kDebugMode) print('Failed to get conversation history: $e');
      return [];
    }
  }

  String _parseErrorMessage(DioException e) {
    // Handle network/connection errors first
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Cannot connect to server. Please check if backend is running.';
    }

    // Try to parse structured error response
    if (e.response?.data != null) {
      try {
        final data = e.response!.data;
        
        // Check for structured error format
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          final error = data['error'];
          if (error is Map<String, dynamic> && error.containsKey('message')) {
            return error['message'] as String;
          }
        }
        
        // Fallback to simple string detail
        if (data is Map<String, dynamic> && data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String) {
            return detail;
          } else if (detail is Map<String, dynamic> && detail.containsKey('error')) {
            final nestedError = detail['error'];
            if (nestedError is Map<String, dynamic> && nestedError.containsKey('message')) {
              return nestedError['message'] as String;
            }
          }
        }
      } catch (parseError) {
        if (kDebugMode) print('Error parsing response: $parseError');
      }
    }

    // Fallback based on status codes
    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'API authentication failed. Please check server configuration.';
      case 404:
        return 'Session not found. A new session will be created.';
      case 429:
        return 'Too many requests. Please slow down.';
      case 500:
        return 'Server error. Please try again.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}