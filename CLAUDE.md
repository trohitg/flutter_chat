# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter chat application integrated with a modern session-based Cerebras AI backend. The app features a sophisticated chat interface with AI-powered responses, Android floating bubble overlay, state persistence, and multi-platform support (Android, Web, Windows).

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app with hot reload support
- `flutter run -d chrome` - Run in web browser (available at http://localhost:8080)
- `flutter run -d windows` - Run on Windows desktop (requires Developer Mode for symlinks)
- `flutter build apk --debug` - Build Android APK for testing
- `flutter build web` - Build for web deployment

### Code Generation
- `dart run build_runner build --delete-conflicting-outputs` - Generate model serialization code
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter analyze` - Run static analysis and linting

### Hot Reload Development
- Press `r` in terminal for hot reload during `flutter run`
- Press `R` for hot restart (full app restart)
- Press `q` to quit the running session

## Architecture

### Modern Session-Based API
The app now uses a clean session-based architecture:

**Session Management:**
- `POST /api/v1/sessions` - Create new chat session (empty body `{}`)
- `POST /api/v1/sessions/{id}/messages` - Send message to session
- `DELETE /api/v1/sessions/{id}` - Clean up session

**Key Design Principles:**
- No model parameters exposed to frontend
- Backend handles all model configuration internally
- Simple, clean API contracts
- Automatic session management with retry logic

### Service Layer Pattern
The app uses a modern service layer architecture:

- **ChatService** (`lib/services/chat_service.dart`): Session-based API client with automatic retry, error handling, and session persistence. Uses Dio/Retrofit for HTTP communication.

- **ApiService** (`lib/services/api_service.dart`): HTTP client configuration with interceptors and base URL management.

- **AppLifecycleService** (`lib/services/app_lifecycle_service.dart`): Handles state persistence and app lifecycle events with SharedPreferences.

- **ConnectivityService** (`lib/services/connectivity_service.dart`): Real-time network monitoring with stream-based updates.

- **PermissionService** (`lib/services/permission_service.dart`): Platform permission management with user-friendly dialogs.

### Data Models
Modern JSON serializable models in `lib/models/chat_models.dart`:
- `SessionRequest` - Simplified empty model
- `SessionResponse` - Session creation response  
- `MessageRequest` - Message sending payload
- `MessageResponse` - AI response with usage info
- Generated code via `json_annotation` and `build_runner`

### Main Application (`lib/main.dart`)
The main file implements:
- **ChatInterface** with session-based messaging
- Message streaming with typewriter effect animation
- Platform-specific backend URL configuration
- Solarized dark theme with modern Material Design
- Comprehensive error handling with specific error messages
- Automatic state persistence and restoration

### Android-Specific Features
- **BubbleService** (`android/.../BubbleService.kt`): Floating overlay service with draggable interface
- **MainActivity** (`android/.../MainActivity.kt`): Platform channel integration for bubble control

## Backend Integration

### Docker Development Stack
Complete Docker Compose setup with:
- **FastAPI Backend** (port 8000) - Session-based API
- **PostgreSQL Database** - Conversation persistence
- **Redis Cache** - Session and response caching
- **Nginx Reverse Proxy** (port 80) - Load balancing and rate limiting
- **Streamlit Dashboard** (port 8501) - Model management interface

### Platform-Specific URLs
- **Web**: `http://localhost:8000` 
- **Android**: `http://192.168.29.64:8000` (development network)
- **iOS/Desktop**: `http://localhost:8000`

### Modern API Specification

**Health Check:**
- `GET /api/v1/health`
- Response: `{"status": "healthy", "version": "1.0.0"}`

**Session Flow:**
1. Create session: `POST /api/v1/sessions` with `{}`
2. Send messages: `POST /api/v1/sessions/{id}/messages` with `{"message": "text"}`  
3. Cleanup: `DELETE /api/v1/sessions/{id}`

**Error Handling:**
- Network errors: "Cannot connect to server"
- Rate limiting: "Too many requests. Please slow down"  
- Server errors: "Server error. Please try again"
- Specific HTTP status code handling

### Environment Configuration
Backend requires `CEREBRAS_API_KEY` in `.env` file for AI integration.

## Dependencies

### Core Dependencies
- `dio: ^5.4.0` - Modern HTTP client with interceptors
- `retrofit: ^4.1.0` - Type-safe HTTP client generation
- `json_annotation: ^4.8.1` - JSON serialization
- `shared_preferences: ^2.3.2` - Local storage for session persistence
- `permission_handler: ^12.0.1` - Permission management
- `connectivity_plus: ^6.0.5` - Network connectivity monitoring

### Dev Dependencies
- `build_runner: ^2.4.7` - Code generation
- `retrofit_generator: ^8.1.0` - HTTP client generation
- `json_serializable: ^6.7.1` - JSON serialization generation
- `flutter_lints: ^5.0.0` - Recommended linting rules

## Testing

### Running Tests
- `flutter test` - Run all tests
- `flutter analyze` - Static analysis
- Integration tests verify full API flow with real backend

### Docker Testing
```bash
cd backend && docker-compose up -d  # Start backend stack
curl http://localhost:8000/api/v1/health  # Verify backend
```

## Key Features to Maintain

When modifying the codebase, ensure these features continue to work:

1. **Session Management**: Automatic session creation, retry logic, and cleanup
2. **Error Handling**: Specific error messages for different failure types (not generic "connection error")
3. **State Persistence**: Chat history and session IDs persist across app restarts
4. **Network Resilience**: Graceful handling of network disconnections with proper error messages
5. **Android Bubble**: Floating overlay with system integration
6. **Modern API Design**: Clean session-based architecture without model parameters
7. **Platform Support**: Multi-platform deployment (Web, Android, Desktop)

## Recent Updates

### API Modernization (Latest)
- ✅ Removed model parameters from frontend 
- ✅ Simplified API contracts (`{}` for session creation)
- ✅ Backend handles all model configuration internally
- ✅ Clean error handling without false "connection errors"
- ✅ Modern Dio/Retrofit HTTP client implementation
- ✅ Docker Compose development stack

### Architecture Improvements
- Session-based conversation management
- Automatic retry logic for expired sessions  
- Type-safe API clients with generated code
- Comprehensive error categorization
- Real-time typing indicators with batched character rendering

This architecture provides a production-ready, maintainable chat application with modern development practices.