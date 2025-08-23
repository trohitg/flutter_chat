import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../services/chat_service.dart';
import '../../services/app_lifecycle_service.dart';

/// Concrete implementation of ChatRepository
/// This bridges the domain layer with the data layer (services)
class ChatRepositoryImpl implements ChatRepository {
  final ChatService _chatService;
  final AppLifecycleService _appLifecycleService;

  ChatRepositoryImpl({
    required ChatService chatService,
    required AppLifecycleService appLifecycleService,
  })  : _chatService = chatService,
        _appLifecycleService = appLifecycleService;

  @override
  Future<String> sendMessage(String message) async {
    return await _chatService.sendMessage(message);
  }

  @override
  Future<void> loadSession() async {
    await _chatService.loadSession();
  }

  @override
  Future<List<ChatMessage>> loadChatHistory() async {
    final historyData = await _appLifecycleService.loadChatHistory();
    
    // Convert raw data to domain entities
    return historyData.map((data) {
      return ChatMessage(
        text: data['content'] ?? '',
        isUser: data['role'] == 'user',
        timestamp: DateTime.now(), // In a real app, we'd store actual timestamps
      );
    }).toList();
  }

  @override
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    // Convert domain entities to raw data format
    final historyData = messages.map((message) {
      return {
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      };
    }).toList();
    
    await _appLifecycleService.saveChatHistory(historyData);
  }

  @override
  Future<void> clearSession() async {
    await _chatService.clearSession();
  }

  @override
  Future<void> clearAppData() async {
    await _appLifecycleService.clearAppData();
  }
}