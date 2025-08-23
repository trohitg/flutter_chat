import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat/main.dart';
import 'package:flutter_chat/core/di/service_locator.dart';
import 'package:flutter_chat/services/bubble_service.dart';
import 'package:flutter_chat/core/config/app_config.dart';

void main() {
  setUp(() async {
    // Reset and initialize dependencies for each test
    await resetDependencies();
    await initializeDependencies();
  });

  testWidgets('App starts and shows basic UI', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app creates a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Give it a moment to render
    await tester.pump();
    
    // Should have the main scaffold structure
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('App has correct theme configuration', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify MaterialApp properties
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('Ask Genie'));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('BubbleService static methods exist', (WidgetTester tester) async {
    // Test that BubbleService methods are callable (they may fail, but shouldn't crash)
    expect(() => BubbleService.canDrawOverlays(), returnsNormally);
    expect(() => BubbleService.showBubble(), returnsNormally);
    expect(() => BubbleService.hideBubble(), returnsNormally);
    expect(() => BubbleService.requestOverlayPermission(), returnsNormally);
  });

  testWidgets('AppConfig provides backend URLs', (WidgetTester tester) async {
    // Test that AppConfig methods work
    expect(() => AppConfig.getBackendUrl(), returnsNormally);
    expect(AppConfig.getBackendUrl(), isA<String>());
    expect(AppConfig.getBackendUrl().contains('http'), isTrue);
  });
}