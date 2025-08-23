import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static String parseApiError(DioException e) {
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
    return _getStatusCodeMessage(e.response?.statusCode);
  }

  static String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
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

  static bool isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.connectionError ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.sendTimeout;
  }

  static bool isSessionExpiredError(DioException e) {
    return e.response?.statusCode == 404;
  }
}