# Flutter Chat

A Flutter chat application with AI-powered responses using Cerebras API integration.

## Features

- Cross-platform chat interface (Android, Web, Windows)
- AI-powered responses via Cerebras GPT-OSS-120B model
- Real-time conversation with full chat history
- Material Design UI components
- Hot reload development support

## Backend Integration

The app connects to a FastAPI backend server:
- **Server URL**: `http://localhost:8000`
- **Endpoint**: `POST /chat`
- **Model**: Cerebras GPT-OSS-120B
- **Timeout**: 30 seconds per request
- **Error handling**: Graceful fallback for connection issues

## Getting Started

### Prerequisites
- Flutter SDK 3.5.4 or higher
- Backend server running on `http://localhost:8000`

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Run in web browser
flutter run -d chrome

# Run on Windows desktop
flutter run -d windows
```

### Development Commands

```bash
# Static analysis and linting
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk        # Android
flutter build web        # Web deployment

# Development tools
flutter clean            # Clean build artifacts
flutter doctor          # Check Flutter installation
```

### Hot Reload
- Press `r` for hot reload during development
- Press `R` for hot restart
- Press `q` to quit

## Project Structure

- `lib/main.dart` - Main application entry point
- `test/widget_test.dart` - Widget tests
- `pubspec.yaml` - Project dependencies and configuration
- Platform-specific configurations in respective folders

## Dependencies

- `cupertino_icons` - iOS-style icons
- `flutter_lints` - Recommended linting rules
- `http` - HTTP client for backend communication
