# Ask Genie - AI Chat App

A simple chat app powered by AI that works on Android, Web, and Windows.

## What it does

- Chat with AI using Cerebras technology
- Send images and get AI analysis  
- Works offline (saves messages for later)
- Android floating bubble for quick access
- Dark theme that looks good

## How to run

1. Make sure you have Flutter installed
2. Clone this project
3. Run these commands:
   ```bash
   flutter pub get
   dart run build_runner build
   flutter run
   ```

## Platform-specific commands

- **Web**: `flutter run -d chrome`
- **Android**: `flutter run -d android`  
- **Windows**: `flutter run -d windows`

## Main features

### Chat Features
- Send text messages to AI
- Upload images and ask questions about them
- Chat history saves automatically
- Typing indicators show when AI is responding

### Android Features
- Floating chat bubble overlay
- Works even when app is closed
- Asks for permissions nicely

### Developer Features
- Hot reload for fast development
- Clean code structure
- Easy to understand and modify

## Project structure

```
lib/
├── main.dart                 # App starts here
├── screens/                  # App screens
├── widgets/                  # UI pieces
├── services/                 # Backend communication
├── features/chat/            # Chat logic
└── models/                   # Data structures
```

## Important files

- `lib/main.dart` - Main app file
- `lib/screens/chat_screen.dart` - Main chat screen
- `lib/services/chat_service.dart` - Talks to AI backend
- `lib/services/image_chat_service.dart` - Handles image uploads
- `pubspec.yaml` - App dependencies

## Backend setup

The app needs a backend server running:
- Local development: `http://localhost:8000`
- Android development: `http://192.168.29.64:8000`

## Build for production

- **Android**: `flutter build apk`
- **Web**: `flutter build web`
- **Windows**: `flutter build windows`

## Testing

Run `flutter test` to make sure everything works.

## Recent updates

- Changed app name from "Flutter Chat" to "Ask Genie"
- Fixed image uploads on web
- Added validation for image-only uploads
- Cleaned up unused code and files
- All tests pass, zero warnings

## Troubleshooting

If something doesn't work:
1. Run `flutter clean && flutter pub get`
2. Check if the backend server is running
3. Make sure you have the latest Flutter version
4. Check `flutter doctor` for system issues

That's it! Simple AI chat app that just works.