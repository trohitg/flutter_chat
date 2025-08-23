# Migration Guide: Modernizing Flutter Chat API

## Overview
This guide shows how to migrate from the current simple HTTP implementation to the modern Dio + Retrofit architecture.

## Steps to Implement

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Update main.dart

Replace the current `_sendMessageToBackend()` method with:

```dart
import 'repositories/chat_repository.dart';

class _ChatInterfaceState extends State<ChatInterface> {
  final ChatRepository _chatRepository = ChatRepository.instance;
  
  // Replace _sendMessageToBackend with:
  Future<String> _sendMessageToBackend() async {
    try {
      // Use streaming for better UX
      final buffer = StringBuffer();
      
      await for (final chunk in _chatRepository.sendMessageStream(
        _conversationHistory.last['content'],
      )) {
        buffer.write(chunk);
      }
      
      return buffer.toString();
    } on ChatException catch (e) {
      // Handle specific chat errors
      if (kDebugMode) {
        print('Chat error: $e');
      }
      
      // Show user-friendly error message
      throw Exception(e.userMessage);
    }
  }
  
  // Alternative: Non-streaming version
  Future<String> _sendMessageNonStreaming() async {
    try {
      final response = await _chatRepository.sendMessage(
        _conversationHistory.last['content'],
      );
      
      return response.content;
    } on ChatException catch (e) {
      throw Exception(e.userMessage);
    }
  }
}
```

### 4. Enhanced Streaming with Real-time Updates

For true streaming experience with character-by-character display:

```dart
void _generateResponse() async {
  setState(() {
    _currentTypingText = '';
    _messages.add(ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    ));
  });

  _scrollToBottom();

  try {
    final buffer = StringBuffer();
    
    // Stream response chunks
    await for (final chunk in _chatRepository.sendMessageStream(
      _conversationHistory.last['content'],
    )) {
      buffer.write(chunk);
      
      // Update UI with each chunk
      if (mounted) {
        setState(() {
          _currentTypingText = buffer.toString();
          _messages.last = ChatMessage(
            text: _currentTypingText,
            isUser: false,
            timestamp: _messages.last.timestamp,
            isTyping: true,
          );
        });
        
        _scrollToBottom();
      }
    }
    
    // Mark as complete
    if (mounted) {
      setState(() {
        _messages.last = ChatMessage(
          text: buffer.toString(),
          isUser: false,
          timestamp: _messages.last.timestamp,
          isTyping: false,
        );
      });
    }
    
    // Save state
    await _saveAppState();
    
  } on ChatException catch (e) {
    // Handle error
    setState(() {
      _messages.removeLast();
      _messages.add(ChatMessage(
        text: e.userMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isTyping: false,
      ));
    });
    
    await _saveAppState();
  }
}
```

### 5. Session Management

Add session lifecycle management:

```dart
@override
void initState() {
  super.initState();
  _initializeChat();
}

Future<void> _initializeChat() async {
  // Check for existing session
  if (_chatRepository.hasActiveSession) {
    try {
      // Load conversation history
      final history = await _chatRepository.getSessionHistory();
      setState(() {
        _messages = history.map((m) => ChatMessage(
          text: m.content,
          isUser: m.role == 'user',
          timestamp: m.timestamp,
        )).toList();
      });
    } catch (e) {
      // Session invalid, will create new one on first message
      if (kDebugMode) {
        print('Failed to load session: $e');
      }
    }
  }
}

// Clear session when clearing history
Future<void> _clearHistory() async {
  await _chatRepository.clearSession();
  setState(() {
    _messages.clear();
    _conversationHistory.clear();
  });
}
```

### 6. Error Handling with Retry

The new architecture includes automatic retry with exponential backoff. You can also manually retry:

```dart
Future<void> _retryLastMessage() async {
  final lastUserMessage = _conversationHistory
    .lastWhere((m) => m['role'] == 'user')['content'];
  
  // Remove error message
  setState(() {
    _messages.removeLast();
  });
  
  // Retry sending
  _handleSubmitted(lastUserMessage);
}
```

### 7. Rate Limit Display

Show rate limit information to users:

```dart
Future<void> _showApiStatus() async {
  try {
    final status = await _chatRepository.getApiStatus();
    final rateLimit = status['rate_limit'];
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Requests remaining: ${rateLimit['requests_remaining']}'),
              Text('Daily tokens used: ${status['usage']['total_tokens_today']}'),
              Text('Daily limit: ${status['usage']['daily_limit']}'),
            ],
          ),
        ),
      );
    }
  } catch (e) {
    // Handle error
  }
}
```

## Benefits of Migration

### 1. **Performance**
- Automatic caching reduces redundant API calls
- Connection pooling for better resource usage
- Streaming responses for real-time UX

### 2. **Reliability**
- Automatic retry with exponential backoff
- Better error handling with specific error codes
- Session management prevents conversation loss

### 3. **Developer Experience**
- Type-safe API calls with code generation
- Centralized configuration
- Better debugging with request/response logging

### 4. **Scalability**
- Rate limiting awareness
- Request queuing
- Efficient session-based conversations

### 5. **Security**
- Token-based authentication ready
- Request signing support
- SSL pinning capability

## Testing

After migration, test these scenarios:

1. **Network interruption**: Messages should queue and retry
2. **Session expiry**: Should create new session automatically
3. **Rate limiting**: Should show appropriate message
4. **Streaming**: Characters should appear smoothly
5. **Error recovery**: Should handle and display errors gracefully

## Rollback Plan

If issues occur, keep the old implementation as fallback:

```dart
// In AppConfig or environment variable
static const bool USE_LEGACY_API = false;

// In service layer
if (USE_LEGACY_API) {
  return _sendMessageToBackendLegacy();
} else {
  return _sendMessageToBackendModern();
}
```

## Next Steps

1. Implement WebSocket support for real-time bidirectional communication
2. Add offline message queue with SQLite
3. Implement message encryption for sensitive conversations
4. Add analytics and monitoring
5. Implement push notifications for background messages