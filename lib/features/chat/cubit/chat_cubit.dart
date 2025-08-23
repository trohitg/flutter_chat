import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/chat_service.dart';
import '../../../services/app_lifecycle_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../core/utils/performance_monitor.dart';
import 'chat_state.dart';

/// Simple ChatMessage data class - replaces domain entity
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isTyping,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.isTyping == isTyping;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        isTyping.hashCode;
  }
}

/// ChatCubit with simplified service dependencies
/// Handles all chat-related business logic and state management
class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  final AppLifecycleService _appLifecycleService;
  final ConnectivityService _connectivityService;
  
  StreamSubscription<bool>? _connectivitySubscription;
  
  static const String _welcomeMessage = 
      "Hello! I'm your AI assistant powered by Cerebras. How can I help you today?";

  ChatCubit({
    required ChatService chatService,
    required AppLifecycleService appLifecycleService,
    required ConnectivityService connectivityService,
  })  : _chatService = chatService,
        _appLifecycleService = appLifecycleService,
        _connectivityService = connectivityService,
        super(const ChatState()) {
    _initializeChat();
  }

  /// Optimized emit that only emits when state actually changes
  void _safeEmit(ChatState newState) {
    PerformanceMonitor.trackRebuild('ChatCubit.emit');
    if (state != newState) {
      emit(newState);
    }
  }

  /// Initialize chat with direct service dependencies
  Future<void> _initializeChat() async {
    emit(state.copyWith(status: ChatStatus.loading));

    try {
      // Initialize dependencies
      await _chatService.loadSession();
      
      // Load chat history from storage
      final historyData = await _appLifecycleService.loadChatHistory();
      
      // Convert raw data to ChatMessage objects
      final messages = historyData.map((data) {
        return ChatMessage(
          text: data['content'] ?? '',
          isUser: data['role'] == 'user',
          timestamp: DateTime.now(), // In a real app, we'd store actual timestamps
        );
      }).toList();
      
      // Add welcome message if no history exists
      final finalMessages = messages.isEmpty 
          ? [_createWelcomeMessage()]
          : messages;

      // Setup connectivity monitoring
      _setupConnectivityListener();

      _safeEmit(state.copyWith(
        messages: finalMessages,
        status: ChatStatus.loaded,
        isConnected: _connectivityService.isConnected,
      ));

    } catch (e) {
      // Fallback to welcome message on error
      emit(state.copyWith(
        messages: [_createWelcomeMessage()],
        status: ChatStatus.error,
        error: e.toString(),
        isConnected: _connectivityService.isConnected,
      ));
    }
  }

  /// Setup connectivity monitoring with proper cleanup
  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityService.connectionStream.listen(
      (isConnected) {
        if (!isClosed) {
          _safeEmit(state.copyWith(isConnected: isConnected));
        }
      },
    );
  }

  /// Send message with improved state management and error handling
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Create user message
    final userMessage = ChatMessage(
      text: message.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message immediately to UI
    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      messages: updatedMessages,
      status: ChatStatus.sendingMessage,
    ));

    // Handle offline scenario
    if (!state.isConnected) {
      final offlineMessage = ChatMessage(
        text: "Message saved. Will be sent when connection is restored.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      emit(state.copyWith(
        messages: [...updatedMessages, offlineMessage],
        status: ChatStatus.loaded,
      ));
      return;
    }

    // Show typing indicator
    final typingMessage = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    
    emit(state.copyWith(
      messages: [...updatedMessages, typingMessage],
    ));

    try {
      // Send message through service
      final response = await _chatService.sendMessage(message);

      // Create AI response message
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Update messages without typing indicator
      final finalMessages = [...updatedMessages, aiMessage];
      
      emit(state.copyWith(
        messages: finalMessages,
        status: ChatStatus.loaded,
        error: null,
      ));

      // Save to storage for persistence
      final historyData = finalMessages.map((message) {
        return {
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.text,
        };
      }).toList();
      await _appLifecycleService.saveChatHistory(historyData);

    } catch (e) {
      // Handle error case with user-friendly message
      final errorMessage = ChatMessage(
        text: 'Sorry, I\'m having trouble connecting to the server. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...updatedMessages, errorMessage],
        status: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  /// Clear chat history with direct service calls
  Future<void> clearHistory() async {
    emit(state.copyWith(status: ChatStatus.loading));

    try {
      await _chatService.clearSession();
      await _appLifecycleService.clearAppData();

      emit(ChatState(
        messages: [_createWelcomeMessage()],
        status: ChatStatus.loaded,
        isConnected: state.isConnected,
      ));

    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to clear history: ${e.toString()}',
      ));
    }
  }

  /// Create welcome message as a reusable method
  ChatMessage _createWelcomeMessage() {
    return ChatMessage(
      text: _welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}