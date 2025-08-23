import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/chat_models.dart';

part 'chat_api.g.dart';

@RestApi()
abstract class ChatApi {
  factory ChatApi(Dio dio, {String? baseUrl}) = _ChatApi;

  @POST('/api/v1/sessions')
  Future<SessionResponse> createSession(@Body() SessionRequest request);

  @POST('/api/v1/sessions/{sessionId}/messages')
  Future<MessageResponse> sendMessageToSession(
    @Path('sessionId') String sessionId,
    @Body() MessageRequest request,
  );

  @POST('/api/v1/images/sessions/{sessionId}/messages')
  @MultiPart()
  Future<MessageResponse> sendImageMessage(
    @Path('sessionId') String sessionId,
    @Part(name: 'message') String message,
    @Part(name: 'image') File image,
  );

  @DELETE('/api/v1/sessions/{sessionId}')
  Future<DeleteSessionResponse> deleteSession(
    @Path('sessionId') String sessionId,
  );

  @GET('/api/v1/sessions/{sessionId}/messages')
  Future<MessageHistoryResponse> getSessionMessages(
    @Path('sessionId') String sessionId,
  );
}