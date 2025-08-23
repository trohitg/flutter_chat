import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_models.dart';
import '../core/utils/error_handler.dart';
import 'api_service.dart';
import 'chat_service.dart';

class ImageChatService {
  static ImageChatService? _instance;
  final ApiService _apiService;
  final ChatService _chatService;
  
  static ImageChatService get instance {
    _instance ??= ImageChatService._();
    return _instance!;
  }

  ImageChatService._() 
    : _apiService = ApiService.instance,
      _chatService = ChatService.instance;

  Future<MessageResponse> sendImageMessage(String message, XFile imageFile) async {
    await _chatService.ensureSession();
    
    try {
      MessageResponse response;
      
      if (kIsWeb) {
        // On web, use direct API call with bytes instead of File
        response = await _sendImageMessageWeb(message, imageFile);
      } else {
        // On mobile/desktop, use File-based approach
        final file = File(imageFile.path);
        response = await _apiService.chatApi.sendImageMessage(
          _chatService.currentSessionId!,
          message,
          file,
        );
      }
      
      return response;
      
    } on DioException catch (e) {
      if (ErrorHandler.isSessionExpiredError(e)) {
        // Session expired, let ChatService create new one and retry
        await _chatService.createNewSession();
        
        MessageResponse response;
        if (kIsWeb) {
          response = await _sendImageMessageWeb(message, imageFile);
        } else {
          final file = File(imageFile.path);
          response = await _apiService.chatApi.sendImageMessage(
            _chatService.currentSessionId!,
            message,
            file,
          );
        }
        
        return response;
      }
      
      throw Exception(ErrorHandler.parseApiError(e));
    }
  }
  
  Future<MessageResponse> _sendImageMessageWeb(String message, XFile imageFile) async {
    // Ensure we have a valid session ID
    final sessionId = _chatService.currentSessionId;
    if (sessionId == null) {
      throw Exception('No active session. Please try again.');
    }
    
    final bytes = await imageFile.readAsBytes();
    
    // Match the exact FormData structure used by Retrofit mobile version
    final formData = FormData();
    formData.fields.add(MapEntry('message', message));
    formData.files.add(MapEntry(
      'image',
      MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
      ),
    ));
    
    final response = await _apiService.dio.post(
      '/api/v1/images/sessions/$sessionId/messages',
      data: formData,
    );
    
    return MessageResponse.fromJson(response.data);
  }
}