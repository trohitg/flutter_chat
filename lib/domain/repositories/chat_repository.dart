import '../entities/chat_message.dart';

/// Abstract repository defining chat-related operations
/// This follows the Repository pattern from Clean Architecture
abstract class ChatRepository {
  /// Send a message and get AI response
  Future<String> sendMessage(String message);
  
  /// Load chat session from storage
  Future<void> loadSession();
  
  /// Get chat history from local storage
  Future<List<ChatMessage>> loadChatHistory();
  
  /// Save chat history to local storage
  Future<void> saveChatHistory(List<ChatMessage> messages);
  
  /// Clear current session and all data
  Future<void> clearSession();
  
  /// Clear all app data
  Future<void> clearAppData();
}