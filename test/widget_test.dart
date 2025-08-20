// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_chat/main.dart';

void main() {
  testWidgets('Chat app loads with welcome message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is present
    expect(find.text('Flutter Chat'), findsOneWidget);

    // Verify that the welcome message is present
    expect(find.text("Hello! I'm your AI assistant powered by Cerebras. How can I help you today?"), findsOneWidget);

    // Verify that the message input field is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify that the send button is present
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Can send a message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Enter text in the text field
    await tester.enterText(find.byType(TextField), 'Hello, AI!');
    
    // Tap the send button
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify that the user message appears
    expect(find.text('Hello, AI!'), findsOneWidget);

    // Clear any pending timers to avoid test cleanup issues
    await tester.binding.delayed(Duration.zero);
    await tester.pumpAndSettle();
  });
}
