import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/chat_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/app_lifecycle_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConnected;
  final String? error;
  
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = true,
    this.error,
  });
  
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConnected,
    String? error,
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isConnected: isConnected ?? this.isConnected,
    error: error ?? this.error,
  );
}

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService = ChatService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  
  ChatCubit() : super(const ChatState()) {
    _initializeChat();
  }
  
  Future<void> _initializeChat() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      await _chatService.loadSession();
      final history = await AppLifecycleService.instance.loadChatHistory();
      
      final messages = <ChatMessage>[];
      for (final msg in history) {
        messages.add(ChatMessage(
          text: msg['content'] ?? '',
          isUser: msg['role'] == 'user',
          timestamp: DateTime.now(),
        ));
      }
      
      // Add welcome message if no history
      if (messages.isEmpty) {
        messages.add(ChatMessage(
          text: "Hello! I'm your AI assistant powered by Cerebras. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
      
      emit(state.copyWith(
        messages: messages,
        isLoading: false,
        isConnected: _connectivityService.isConnected,
      ));
      
      // Listen to connectivity changes
      _connectivityService.connectionStream.listen((connected) {
        if (!isClosed) {
          emit(state.copyWith(isConnected: connected));
        }
      });
      
    } catch (e) {
      emit(state.copyWith(
        isLoading: false, 
        error: e.toString(),
        messages: [
          ChatMessage(
            text: "Hello! I'm your AI assistant powered by Cerebras. How can I help you today?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      ));
    }
  }
  
  Future<void> sendMessage(String message) async {
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(messages: updatedMessages));
    
    if (!state.isConnected) {
      final offlineMessage = ChatMessage(
        text: "Message saved. Will be sent when connection is restored.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(messages: [...updatedMessages, offlineMessage]));
      return;
    }
    
    // Add typing indicator
    final typingMessage = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    emit(state.copyWith(messages: [...updatedMessages, typingMessage]));
    
    try {
      final response = await _chatService.sendMessage(message);
      
      // Remove typing indicator and add actual response
      final messagesWithoutTyping = [...updatedMessages];
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      final finalMessages = [...messagesWithoutTyping, aiMessage];
      emit(state.copyWith(messages: finalMessages, isLoading: false));
      
      // Save state
      final history = await AppLifecycleService.instance.loadChatHistory();
      await AppLifecycleService.instance.saveChatHistory([
        ...history,
        {'role': 'user', 'content': message},
        {'role': 'assistant', 'content': response},
      ]);
      
    } catch (e) {
      // Remove typing indicator and add error message
      final messagesWithoutTyping = [...updatedMessages];
      final errorMessage = ChatMessage(
        text: 'Sorry, I\'m having trouble connecting to the server. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      emit(state.copyWith(
        messages: [...messagesWithoutTyping, errorMessage],
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  Future<void> clearHistory() async {
    await ChatService.instance.clearSession();
    await AppLifecycleService.instance.clearAppData();
    
    const welcomeMessage = "Hello! I'm your AI assistant powered by Cerebras. How can I help you today?";
    emit(ChatState(
      messages: [
        ChatMessage(
          text: welcomeMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isConnected: state.isConnected,
    ));
  }
}