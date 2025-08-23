import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'services/app_lifecycle_service.dart';
import 'services/connectivity_service.dart';
import 'screens/chat_screen.dart';

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
      return 'http://192.168.29.64:8000';
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

  // Configure system UI overlay style to follow system theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: const ChatScreen(),
    );
  }
}