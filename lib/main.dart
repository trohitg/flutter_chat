import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Configuration class for easy backend URL management
class AppConfig {
  static String getBackendUrl() {
    if (kIsWeb) {
      // For Flutter web
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android emulator, use 10.0.2.2 to reach host machine
      // For physical device, replace with your machine's IP address
      // Example: 'http://192.168.1.100:8000'
      return 'http://10.0.2.2:8000';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS simulator, localhost should work
      // For physical device, replace with your machine's IP address
      // Example: 'http://192.168.1.100:8000'
      return 'http://localhost:8000';
    } else {
      // For desktop platforms
      return 'http://localhost:8000';
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF002b36),
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: Color(0xFF268bd2),
          secondary: Color(0xFF2aa198),
          surface: Color(0xFF073642),
          surfaceContainerHighest: Color(0xFF073642),
          onPrimary: Color(0xFF002b36),
          onSecondary: Color(0xFF002b36),
          onSurface: Color(0xFF839496),
          onSurfaceVariant: Color(0xFF586e75),
          outline: Color(0xFF586e75),
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF073642),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF002b36),
          foregroundColor: Color(0xFF839496),
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF073642),
          hintStyle: const TextStyle(color: Color(0xFF586e75)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF586e75), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF586e75), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF268bd2), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF839496)),
          bodyMedium: TextStyle(color: Color(0xFF839496)),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _conversationHistory = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentTypingText = '';

  @override
  void initState() {
    super.initState();
    
    const welcomeMessage = "Hello! I'm your AI assistant powered by Cerebras. How can I help you today?";
    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    // Add welcome message to conversation history as system context
    _conversationHistory.add({
      'role': 'assistant',
      'content': welcomeMessage,
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _textController.clear();
    
    // Add user message to conversation history
    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });
    
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
    _generateResponse();
  }

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
      // Make HTTP request to backend with full conversation history
      final response = await _sendMessageToBackend();
      
      // Add AI response to conversation history
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
      });
      
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ));
      });

      await _typeMessage(response);
    } catch (e) {
      // Handle error case
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: 'Sorry, I\'m having trouble connecting to the server. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: false,
        ));
      });
    }
  }

  Future<String> _sendMessageToBackend() async {
    final String baseUrl = AppConfig.getBackendUrl();
    
    try {
      final requestBody = {
        'messages': _conversationHistory,
        'max_tokens': 1000,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['response'] ?? 'Sorry, I didn\'t understand that.';
      } else {
        final errorText = response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception('Server returned status code: ${response.statusCode}. Error: $errorText');
      }
    } catch (e) {
      // Enhanced error handling with debugging information
      if (kDebugMode) {
        print('Error connecting to backend at $baseUrl: $e');
      }
      
      if (e.toString().contains('XMLHttpRequest') || e.toString().contains('CORS')) {
        throw Exception('CORS error: Please enable CORS on your backend server.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Network is unreachable')) {
        throw Exception('Cannot connect to server at $baseUrl. Make sure the backend is running.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Check your internet connection and backend URL.');
      }
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<void> _typeMessage(String message) async {
    for (int i = 0; i <= message.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _currentTypingText = message.substring(0, i);
        _messages.last = ChatMessage(
          text: _currentTypingText,
          isUser: false,
          timestamp: _messages.last.timestamp,
          isTyping: i < message.length,
        );
      });

      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 30));
    }

  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surface,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Message...',
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _handleSubmitted(_textController.text),
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: message.isUser 
                          ? const Radius.circular(16) 
                          : const Radius.circular(4),
                      bottomRight: message.isUser 
                          ? const Radius.circular(4) 
                          : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      if (message.isTyping)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: const _TypingIndicator(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({super.key});
  
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF586e75).withOpacity(
                  0.3 + (_animation.value * 0.7) * 
                  (1 - (index * 0.2).clamp(0.0, 1.0))
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
