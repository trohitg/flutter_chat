# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called `flutter_chat` - currently a basic counter app template that serves as a starting point for Flutter development. The project uses Flutter SDK 3.5.4+ and follows standard Flutter project structure.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app on connected device/emulator with hot reload support
- `flutter run -d chrome` - Run in web browser
- `flutter run -d windows` - Run on Windows desktop
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS)
- `flutter build web` - Build for web deployment

### Development Tools
- `flutter analyze` - Run static analysis and linting (uses flutter_lints package)
- `flutter test` - Run widget and unit tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter pub upgrade` - Upgrade dependencies to latest versions
- `flutter pub outdated` - Check for newer dependency versions
- `flutter clean` - Clean build artifacts
- `flutter doctor` - Check Flutter installation and dependencies

### Hot Reload Development
- Press `r` in terminal for hot reload during `flutter run`
- Press `R` for hot restart (full app restart)
- Press `q` to quit the running session

## Project Structure

The app follows standard Flutter architecture:

- `lib/main.dart` - Entry point with `MyApp` (MaterialApp root) and `MyHomePage` (StatefulWidget with counter functionality)
- `test/widget_test.dart` - Widget tests using flutter_test framework
- `pubspec.yaml` - Project configuration and dependencies
- `analysis_options.yaml` - Linting rules using flutter_lints package
- Platform-specific folders: `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`

## Testing

Tests use the `flutter_test` framework. The existing test demonstrates:
- Widget testing with `WidgetTester`
- Finding widgets by text and icon
- Simulating user interactions (taps)
- Verifying UI state changes

Run tests before committing changes to ensure functionality remains intact.

## Dependencies

- `cupertino_icons` - iOS-style icons
- `flutter_lints` - Recommended linting rules for Flutter projects
- Core Flutter SDK provides Material Design components and state management

The project is configured for multi-platform deployment (Android, iOS, Web, Windows, Linux, macOS) with platform-specific build configurations already in place.