import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../api/chat_api.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  late final ChatApi _chatApi;
  
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  ApiService._() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging only in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ));
    }

    // Add simple error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 429) {
          // Rate limiting
          error = error.copyWith(
            message: 'Too many requests. Please slow down.',
          );
        } else if (error.type == DioExceptionType.connectionTimeout ||
                   error.type == DioExceptionType.connectionError) {
          error = error.copyWith(
            message: 'Cannot connect to server. Please check if backend is running.',
          );
        }
        handler.next(error);
      },
    ));

    _chatApi = ChatApi(_dio, baseUrl: _getBaseUrl());
  }

  ChatApi get chatApi => _chatApi;

  String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For real device, use actual IP. For emulator, use 10.0.2.2
      return 'http://192.168.29.64:8000'; // Update with your IP
    }
    return 'http://localhost:8000';
  }
}