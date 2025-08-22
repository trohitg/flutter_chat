import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'services/app_lifecycle_service.dart';
import 'services/permission_service.dart';
import 'services/connectivity_service.dart';

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
      return 'http://10.20.178.142:8000';
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

class BubbleService {
  static const MethodChannel _channel =
      MethodChannel('com.example.flutter_chat/bubble');

  static Future<bool> showBubble() async {
    try {
      final bool result = await _channel.invokeMethod('showBubble');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to show bubble: '${e.message}'.");
      }
      return false;
    }
  }

  static Future<bool> hideBubble() async {
    try {
      final bool result = await _channel.invokeMethod('hideBubble');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to hide bubble: '${e.message}'.");
      }
      return false;
    }
  }

  static Future<bool> canDrawOverlays() async {
    try {
      final bool result = await _channel.invokeMethod('canDrawOverlays');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to check overlay permission: '${e.message}'.");
      }
      return false;
    }
  }

  static Future<bool> requestOverlayPermission() async {
    try {
      final bool result =
          await _channel.invokeMethod('requestOverlayPermission');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to request overlay permission: '${e.message}'.");
      }
      return false;
    }
  }
}

void main() async {
  // Enable performance optimization flags
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await AppLifecycleService.instance.initialize();
  await ConnectivityService.instance.initialize();

  // Set system UI preferences
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(
      label: 'Flutter Chat',
      primaryColor: 0xFF007AFF,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF002b36),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay:
          kDebugMode ? false : false, // Set to true to show FPS overlay
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _conversationHistory = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentTypingText = '';
  bool _bubbleVisible = false;
  Timer? _typingTimer;
  late AnimationController _fadeController;
  bool _isConnected = true;
  bool _isInitialized = false;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize animation controller for smooth animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Add text controller listener for real-time send button updates
    _textController.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
    });

    // Initialize app state asynchronously
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load saved state and chat history
      await _loadAppState();

      // Setup connectivity monitoring
      _connectivitySubscription =
          ConnectivityService.instance.connectionStream.listen(
        (isConnected) {
          if (mounted) {
            setState(() {
              _isConnected = isConnected;
            });

            if (!isConnected) {
              _showNetworkError();
            }
          }
        },
      );

      // Check initial connectivity
      _isConnected = ConnectivityService.instance.isConnected;

      // Load bubble state
      _bubbleVisible = await AppLifecycleService.instance.loadBubbleState();

      setState(() {
        _isInitialized = true;
      });

      // Ensure smooth scrolling
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing app: $e');
      }
      // Show error and continue with default state
      _initializeDefaultState();
    }
  }

  void _initializeDefaultState() {
    const welcomeMessage =
        "Hello! I'm your AI assistant powered by Cerebras. How can I help you today?";

    if (_messages.isEmpty) {
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

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadAppState() async {
    // Load chat history
    final savedHistory = await AppLifecycleService.instance.loadChatHistory();
    if (savedHistory.isNotEmpty) {
      _conversationHistory.clear();
      _conversationHistory.addAll(savedHistory);

      // Convert to ChatMessage objects
      _messages.clear();
      for (final msg in savedHistory) {
        _messages.add(ChatMessage(
          text: msg['content'] ?? '',
          isUser: msg['role'] == 'user',
          timestamp: DateTime.now(), // Use current time as fallback
        ));
      }

      // Check if last message was from user but no assistant response
      // This indicates an interrupted conversation
      if (_conversationHistory.isNotEmpty &&
          _conversationHistory.last['role'] == 'user') {
        if (kDebugMode) {
          print(
              'Detected interrupted conversation - user message without AI response');
        }
        // The user's message is already loaded, no need to resend
        // The UI will show the incomplete conversation state
      }
    } else {
      // Initialize with welcome message if no history
      _initializeDefaultState();
    }

    // Ensure text controller is cleared on app resume
    _textController.clear();
  }

  Future<void> _saveAppState() async {
    // Save chat history
    await AppLifecycleService.instance.saveChatHistory(_conversationHistory);

    // Save bubble state
    await AppLifecycleService.instance.saveBubbleState(_bubbleVisible);

    // Save other app state
    await AppLifecycleService.instance.saveAppState({
      'lastUsed': DateTime.now().toIso8601String(),
      'messageCount': _messages.length,
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _fadeController.dispose();
    _textController.dispose();
    _scrollController.dispose();

    // Save state before disposal
    _saveAppState();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - refresh connectivity and restore state
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App paused - save state
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        // App inactive - prepare for possible backgrounding
        break;
      case AppLifecycleState.detached:
        // App detached - final cleanup
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        // App hidden - minimize resource usage
        break;
    }
  }

  void _onAppResumed() {
    if (kDebugMode) {
      print('App resumed');
    }

    // Refresh connectivity status
    _isConnected = ConnectivityService.instance.isConnected;

    // Clear text controller to prevent duplicate inputs
    _textController.clear();

    if (mounted) {
      setState(() {});
    }
  }

  void _onAppPaused() {
    if (kDebugMode) {
      print('App paused - saving state');
    }

    // Save current state
    _saveAppState();
  }

  void _onAppDetached() {
    if (kDebugMode) {
      print('App detached - final cleanup');
    }

    // Final state save
    _saveAppState();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _textController.clear();

    // Add user message to UI immediately
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    // Add user message to conversation history
    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });

    // Save state immediately after user message to prevent loss
    _saveAppState();

    // Scroll to bottom after adding message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Check connectivity before sending to backend
    if (!_isConnected) {
      // Show offline message but keep the user message visible
      setState(() {
        _messages.add(ChatMessage(
          text: "Message saved. Will be sent when connection is restored.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      _saveAppState(); // Persist offline messages
      return;
    }

    // If connected, generate AI response
    _generateResponse();
  }

  void _showNetworkError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('No internet connection. Please check your network.'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _isConnected = ConnectivityService.instance.isConnected;
            setState(() {});
          },
        ),
      ),
    );
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

      // Save state immediately after receiving response
      await _saveAppState();

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

      // Save state again after typing is complete
      await _saveAppState();
    } catch (e) {
      // Handle error case
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text:
              'Sorry, I\'m having trouble connecting to the server. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: false,
        ));
      });

      // Save state even on error to persist the error message
      await _saveAppState();
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['response'] ?? 'Sorry, I didn\'t understand that.';
      } else {
        final errorText =
            response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception(
            'Server returned status code: ${response.statusCode}. Error: $errorText');
      }
    } catch (e) {
      // Enhanced error handling with debugging information
      if (kDebugMode) {
        print('Error connecting to backend at $baseUrl: $e');
      }

      if (e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('CORS')) {
        throw Exception(
            'CORS error: Please enable CORS on your backend server.');
      } else if (e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
            'Cannot connect to server at $baseUrl. Make sure the backend is running.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
            'Network error: Check your internet connection and backend URL.');
      }
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<void> _typeMessage(String message) async {
    _typingTimer?.cancel();

    const int batchSize =
        3; // Type multiple characters at once for better performance

    for (int i = 0; i <= message.length; i += batchSize) {
      if (!mounted) return;

      final endIndex = (i + batchSize).clamp(0, message.length);

      setState(() {
        _currentTypingText = message.substring(0, endIndex);
        _messages.last = ChatMessage(
          text: _currentTypingText,
          isUser: false,
          timestamp: _messages.last.timestamp,
          isTyping: endIndex < message.length,
        );
      });

      _scrollToBottom();

      // Use timer for better performance control
      if (endIndex < message.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _toggleBubble() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bubble feature is only available on Android')),
      );
      return;
    }

    if (_bubbleVisible) {
      final success = await BubbleService.hideBubble();
      if (success) {
        setState(() {
          _bubbleVisible = false;
        });
        await AppLifecycleService.instance.saveBubbleState(false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat bubble hidden')),
          );
        }
      }
    } else {
      // Use proper permission service
      final hasPermission =
          await PermissionService.instance.requestOverlayPermission(context);

      if (!hasPermission) {
        return; // Permission denied or user cancelled
      }

      final success = await BubbleService.showBubble();
      if (success) {
        setState(() {
          _bubbleVisible = true;
        });
        await AppLifecycleService.instance.saveBubbleState(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat bubble is now visible')),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'clear_history':
        await _showClearHistoryDialog();
        break;
      case 'permissions':
        await _showPermissionsDialog();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all chat messages? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _messages.clear();
        _conversationHistory.clear();
      });

      // Clear saved history
      await AppLifecycleService.instance.clearAppData();

      // Add welcome message back
      _initializeDefaultState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history cleared')),
        );
      }
    }
  }

  Future<void> _showPermissionsDialog() async {
    final permissions =
        await PermissionService.instance.getDetailedPermissionStatus();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Permissions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionRow(
                'Overlay Permission',
                permissions['overlay']['granted'] ?? false,
                'Required for chat bubble feature',
              ),
              const SizedBox(height: 8),
              _buildPermissionRow(
                'Notifications',
                permissions['notification']['granted'] ?? false,
                'For important app updates',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!permissions['overlay']['granted'] ||
                !permissions['notification']['granted'])
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _requestPermissions();
                },
                child: const Text('Grant Permissions'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionRow(String name, bool granted, String description) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermissions() async {
    if (mounted) {
      await PermissionService.instance.requestOverlayPermission(context);
      if (mounted) {
        await PermissionService.instance.requestNotificationPermission(context);
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter Chat',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          ),
        ),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('AI-powered chat application with floating bubble support.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Real-time AI chat responses'),
        const Text('• Floating chat bubble'),
        const Text('• Automatic state preservation'),
        const Text('• Network connectivity handling'),
        const Text('• Accessibility support'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initializing...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Save state when user navigates back
          _saveAppState();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Flutter Chat'),
              if (!_isConnected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.wifi_off,
                  color: Colors.red,
                  size: 20,
                  semanticLabel: 'No internet connection',
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _bubbleVisible
                    ? Icons.bubble_chart
                    : Icons.bubble_chart_outlined,
                semanticLabel:
                    _bubbleVisible ? 'Hide chat bubble' : 'Show chat bubble',
              ),
              onPressed: _toggleBubble,
              tooltip: _bubbleVisible ? 'Hide Chat Bubble' : 'Show Chat Bubble',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: _handleMenuAction,
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'clear_history',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Clear Chat History'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'permissions',
                  child: ListTile(
                    leading: Icon(Icons.security),
                    title: Text('Permissions'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('About'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
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
                cacheExtent: 1000.0, // Cache more items for smoother scrolling
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                addSemanticIndexes: false,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: _ChatBubble(
                      key: ValueKey(
                          _messages[index].timestamp.millisecondsSinceEpoch),
                      message: _messages[index],
                    ),
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
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
            child: Semantics(
              label: 'Message input field',
              hint: 'Type your message here',
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isConnected
                      ? 'Message...'
                      : 'No connection - message will be sent when online',
                  suffixIcon: !_isConnected
                      ? Icon(Icons.wifi_off, color: Colors.red)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _handleSubmitted(text);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Send message',
            hint: 'Send your message to the AI assistant',
            child: IconButton(
              onPressed: _textController.text.trim().isNotEmpty
                  ? () => _handleSubmitted(_textController.text)
                  : null,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: _isConnected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final messageTime =
        TimeOfDay.fromDateTime(message.timestamp).format(context);

    return Semantics(
      label:
          '${message.isUser ? "Your message" : "AI response"}: ${message.text}',
      hint: 'Sent at $messageTime',
      child: Padding(
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
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
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
                            child: RepaintBoundary(
                              child: const _TypingIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
                color: const Color(0xFF586e75).withOpacity(0.3 +
                    (_animation.value * 0.7) *
                        (1 - (index * 0.2).clamp(0.0, 1.0))),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
