import 'chat_cubit.dart';

enum ChatStatus {
  initial,
  loading,
  loaded,
  sendingMessage,
  error,
}

class ChatState {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        other.messages.length == messages.length &&
        _listEquals(other.messages, messages) &&
        other.status == status &&
        other.isConnected == isConnected &&
        other.error == error;
  }

  @override
  int get hashCode {
    return messages.hashCode ^
        status.hashCode ^
        isConnected.hashCode ^
        (error?.hashCode ?? 0);
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

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