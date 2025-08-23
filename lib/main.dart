import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/app_lifecycle_service.dart';
import 'services/connectivity_service.dart';
import 'services/bubble_service.dart';
import 'screens/chat_screen.dart';
import 'core/di/service_locator.dart';

void main() async {
  // Enable performance optimization flags
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await initializeDependencies();

  // Initialize services
  await AppLifecycleService.instance.initialize();
  await ConnectivityService.instance.initialize();
  await BubbleService.initialize();

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
