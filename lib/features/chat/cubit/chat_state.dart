import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_message.dart';

enum ChatStatus {
  initial,
  loading,
  loaded,
  sendingMessage,
  error,
}

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final ChatStatus status;
  final bool isConnected;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.initial,
    this.isConnected = true,
    this.error,
  });

  /// Performance optimized state comparison using Equatable
  @override
  List<Object?> get props => [messages, status, isConnected, error];

  /// Immutable state updates
  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    bool? isConnected,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
    );
  }

  /// Convenience getters for common state checks
  bool get isLoading => status == ChatStatus.loading;
  bool get isSendingMessage => status == ChatStatus.sendingMessage;
  bool get hasError => status == ChatStatus.error && error != null;
  bool get isInitial => status == ChatStatus.initial;
}