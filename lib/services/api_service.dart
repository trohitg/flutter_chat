import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../api/chat_api.dart';
import '../core/config/app_config.dart';

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
      // Reasonable timeouts for mobile networks
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
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

    // Simple error interceptor
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
            message:
                'Cannot connect to server. Please check your internet connection.',
          );
        }
        handler.next(error);
      },
    ));

    _chatApi = ChatApi(_dio, baseUrl: _getBaseUrl());
  }

  ChatApi get chatApi => _chatApi;
  Dio get dio => _dio;
  String get baseUrl => _getBaseUrl();

  String _getBaseUrl() {
    return AppConfig.getBackendUrl();
  }
}
