import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class SessionRequest {
  SessionRequest();

  factory SessionRequest.fromJson(Map<String, dynamic> json) =>
      _$SessionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SessionRequestToJson(this);
}

@JsonSerializable()
class SessionResponse {
  @JsonKey(name: 'session_id')
  final String sessionId;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  SessionResponse({
    required this.sessionId,
    required this.createdAt,
    required this.expiresIn,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SessionResponseToJson(this);
}

@JsonSerializable()
class MessageRequest {
  final String message;
  final bool stream;

  MessageRequest({
    required this.message,
    this.stream = false,
  });

  factory MessageRequest.fromJson(Map<String, dynamic> json) =>
      _$MessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MessageRequestToJson(this);
}

@JsonSerializable()
class MessageResponse {
  final String id;
  final String content;
  final String role;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  MessageResponse({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    this.imageUrl,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);
}


@JsonSerializable()
class DeleteSessionResponse {
  final String message;

  DeleteSessionResponse({
    required this.message,
  });

  factory DeleteSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteSessionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteSessionResponseToJson(this);
}

@JsonSerializable()
class MessageHistoryItem {
  final String id;
  final String role;
  final String content;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  MessageHistoryItem({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.imageUrl,
  });

  factory MessageHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$MessageHistoryItemFromJson(json);
  Map<String, dynamic> toJson() => _$MessageHistoryItemToJson(this);
}

@JsonSerializable()
class MessageHistoryResponse {
  final List<MessageHistoryItem> messages;
  @JsonKey(name: 'total_count')
  final int totalCount;

  MessageHistoryResponse({
    required this.messages,
    required this.totalCount,
  });

  factory MessageHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageHistoryResponseToJson(this);
}