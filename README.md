# Flutter Chat

A modern Flutter chat application with AI-powered responses using session-based Cerebras API integration. Built with Clean Architecture principles, BLoC state management, and optimized for performance.

## ✨ Features

### Core Functionality
- **Cross-platform support** - Android, Web, Windows with platform-specific optimizations
- **AI-powered conversations** - Cerebras GPT integration with intelligent responses
- **Session-based chat** - Persistent conversation history with automatic session management
- **Real-time typing indicators** - Smooth character-by-character response streaming
- **Offline resilience** - Graceful handling of network interruptions with retry logic

### Android-Specific Features  
- **Floating chat bubble** - System overlay for quick access
- **Permission management** - Streamlined overlay permission handling
- **Background persistence** - Maintain state across app lifecycle

### Developer Experience
- **Hot reload support** - Fast development iteration
- **Modern architecture** - Clean Architecture with dependency injection
- **Comprehensive error handling** - User-friendly error messages
- **Performance monitoring** - Built-in rebuild tracking (development mode)

## 🏗️ Architecture

### Modern Session-Based API
- **Session Management**: `POST /api/v1/sessions` → `POST /api/v1/sessions/{id}/messages`
- **Automatic Retry Logic**: Handles expired sessions transparently
- **Error Classification**: Network, server, and session errors with specific handling
- **Request/Response Caching**: Optimized with Dio interceptors

### Clean Architecture Pattern
```
Presentation (BLoC) → Domain (Entities/Repositories) → Data (Services)
     ↓                        ↓                           ↓
  ChatCubit              ChatRepository                ChatService
 ChatScreen            ChatMessage                  ApiService
```

### State Management
- **BLoC/Cubit pattern** - Predictable state updates
- **Dependency Injection** - GetIt service locator
- **Stream-based connectivity** - Real-time network status
- **Persistent storage** - SharedPreferences for session data

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.5.4 or higher
- **Backend server** running on:
  - Development: `http://localhost:8000` (Desktop/Web)  
  - Android Dev: `http://192.168.29.64:8000`
  - Production: Configured via AppConfig

### Installation

1. **Clone the repository**
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Generate code** (for model serialization):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Running the App

```bash
# Development with hot reload
flutter run                    # Auto-detects platform
flutter run -d chrome          # Web browser (localhost:8080)  
flutter run -d windows         # Windows desktop
flutter run -d android         # Android device/emulator

# Production builds
flutter build apk --debug      # Android APK
flutter build web              # Web deployment  
flutter build windows          # Windows executable
```

### Development Commands

```bash
# Code quality
flutter analyze                           # Static analysis
flutter test                             # Run widget tests

# Code generation  
dart run build_runner build              # Generate models
dart run build_runner watch              # Watch mode

# Debugging
flutter logs                             # View device logs
flutter devices                         # List available devices
```

### Hot Reload Development
- **`r`** - Hot reload (preserve state)
- **`R`** - Hot restart (full restart)  
- **`q`** - Quit development session

## 📁 Project Structure

### Core Application
```
lib/
├── main.dart                    # App entry point with DI setup
├── screens/chat_screen.dart     # Main chat interface
└── widgets/                     # Reusable UI components
    ├── chat_bubble.dart
    ├── chat_message_list.dart
    └── message_input.dart
```

### Architecture Layers
```  
lib/
├── features/chat/               # BLoC state management
│   └── cubit/
│       ├── chat_cubit.dart     # Business logic
│       └── chat_state.dart     # State definitions
├── services/                   # Data layer services
│   ├── chat_service.dart       # Session-based API client
│   ├── api_service.dart        # HTTP client configuration
│   ├── bubble_service.dart     # Android overlay management
│   ├── connectivity_service.dart # Network monitoring
│   ├── permission_service.dart  # Permission handling
│   └── app_lifecycle_service.dart # State persistence
└── core/                       # Shared utilities
    ├── config/app_config.dart   # Environment configuration
    ├── di/service_locator.dart  # Dependency injection
    └── utils/
        ├── error_handler.dart    # Centralized error handling
        └── performance_monitor.dart # Dev performance tracking
```

### API Layer
```
lib/
├── api/
│   ├── chat_api.dart           # Retrofit API definitions
│   └── chat_api.g.dart         # Generated HTTP client
└── models/
    ├── chat_models.dart        # Request/response models
    └── chat_models.g.dart      # JSON serialization
```

## 📦 Dependencies

### Production Dependencies
- **HTTP & API**: `dio ^5.4.0`, `retrofit ^4.1.0`
- **State Management**: `flutter_bloc ^9.1.1`, `get_it ^8.0.2`
- **JSON Handling**: `json_annotation ^4.8.1`
- **Storage**: `shared_preferences ^2.3.2`
- **Permissions**: `permission_handler ^12.0.1`, `connectivity_plus ^6.0.5`

### Development Dependencies
- **Code Generation**: `build_runner ^2.4.8`, `retrofit_generator ^8.1.0`
- **Testing**: `flutter_test`, `flutter_lints ^5.0.0`
- **Serialization**: `json_serializable ^6.7.1`

## 🔧 Configuration

### Environment Setup
Backend URLs are automatically configured based on platform:
- **Web/Desktop**: `http://localhost:8000`
- **Android Development**: `http://192.168.29.64:8000`  
- **Production**: Set in `AppConfig.getBackendUrl()`

### Performance Settings
Configurable via `AppConfig.getPerformanceSetting()`:
- Message pagination (50-100 per page)
- Cache limits (500-1000 messages)
- Performance logging (dev only)

## 🧹 Recent Improvements

### Code Cleanup (Latest)
- **Removed 600+ lines** of unused documentation and scaffolding
- **Eliminated empty directories** (`lib/shared/widgets/`, `lib/core/constants/`)
- **Streamlined project structure** - removed deprecated migration guides
- **Maintained 100% functionality** - all tests pass, app builds successfully

### Architecture Modernization  
- **Session-based API** - replaced simple HTTP with robust session management
- **Centralized error handling** - `ErrorHandler` utility for consistent UX
- **Optimized configurations** - simplified `AppConfig` with platform-specific URLs
- **Performance monitoring** - development-only rebuild tracking

## 🧪 Testing

```bash
# Run all tests
flutter test

# Test coverage (if configured)  
flutter test --coverage

# Integration testing
flutter drive --target=test_driver/app.dart
```

### Test Coverage
- ✅ **Widget tests**: App startup, theme, service initialization
- ✅ **Static analysis**: Code quality and lint rules  
- ✅ **Build verification**: APK generation across platforms

## 🚀 Deployment

### Android
```bash
flutter build apk --release          # Release APK
flutter build appbundle --release    # Google Play Bundle
```

### Web
```bash  
flutter build web --release          # Production web build
flutter build web --web-renderer canvaskit  # Advanced graphics
```

### Desktop
```bash
flutter build windows --release      # Windows executable
flutter build linux --release        # Linux binary (if supported)
```

## 🔍 Troubleshooting

### Common Issues
- **Network errors**: Check backend server status and URL configuration
- **Build failures**: Run `flutter clean && flutter pub get`  
- **Android permissions**: Ensure overlay permissions granted for bubble feature
- **Session expired**: App handles automatically with retry logic

### Debug Commands
```bash
flutter doctor -v                    # Detailed system info
flutter logs                        # Real-time device logs
flutter analyze --verbose           # Detailed static analysis
```
