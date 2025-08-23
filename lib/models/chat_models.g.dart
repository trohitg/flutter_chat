// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionRequest _$SessionRequestFromJson(Map<String, dynamic> json) =>
    SessionRequest();

Map<String, dynamic> _$SessionRequestToJson(SessionRequest instance) =>
    <String, dynamic>{};

SessionResponse _$SessionResponseFromJson(Map<String, dynamic> json) =>
    SessionResponse(
      sessionId: json['session_id'] as String,
      createdAt: json['created_at'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$SessionResponseToJson(SessionResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'created_at': instance.createdAt,
      'expires_in': instance.expiresIn,
    };

MessageRequest _$MessageRequestFromJson(Map<String, dynamic> json) =>
    MessageRequest(
      message: json['message'] as String,
      stream: json['stream'] as bool? ?? false,
    );

Map<String, dynamic> _$MessageRequestToJson(MessageRequest instance) =>
    <String, dynamic>{
      'message': instance.message,
      'stream': instance.stream,
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      id: json['id'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      createdAt: json['created_at'] as String,
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'role': instance.role,
      'created_at': instance.createdAt,
      'image_url': instance.imageUrl,
    };

DeleteSessionResponse _$DeleteSessionResponseFromJson(
        Map<String, dynamic> json) =>
    DeleteSessionResponse(
      message: json['message'] as String,
    );

Map<String, dynamic> _$DeleteSessionResponseToJson(
        DeleteSessionResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
    };

MessageHistoryItem _$MessageHistoryItemFromJson(Map<String, dynamic> json) =>
    MessageHistoryItem(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$MessageHistoryItemToJson(MessageHistoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'created_at': instance.createdAt,
      'image_url': instance.imageUrl,
    };

MessageHistoryResponse _$MessageHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    MessageHistoryResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => MessageHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
    );

Map<String, dynamic> _$MessageHistoryResponseToJson(
        MessageHistoryResponse instance) =>
    <String, dynamic>{
      'messages': instance.messages,
      'total_count': instance.totalCount,
    };
