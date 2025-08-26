# Ask Genie - Smart Chat App 🧞‍♂️

A simple chat app that talks to AI. Works on phones, computers, and web browsers.

## What you can do

- **Chat with AI** - Ask questions, get smart answers
- **Send pictures** - Upload photos and ask AI about them
- **Add money** - Put money in your wallet and make payments
- **Chat anywhere** - Use the floating bubble on Android
- **Works offline** - Your messages are saved even without internet

## Quick start

1. Install Flutter on your computer
2. Download this code
3. Type these commands:
   ```bash
   flutter pub get
   dart run build_runner build
   flutter run
   ```

That's it! The app will start.

## Run on different devices

- **Web browser**: `flutter run -d chrome`
- **Android phone**: `flutter run -d android`
- **Windows computer**: `flutter run -d windows`

## Main features

### 💬 Chat Features
- Ask AI anything you want
- Send photos and get explanations
- Your chat history is saved automatically
- See when AI is typing

### 💰 Money Features
- Add money to your wallet
- Make secure payments with Razorpay
- View your balance and transaction history
- Works on both mobile and web

### 📱 Android Features
- Floating chat bubble that stays on screen
- Chat even when app is closed
- Easy permission setup

### 👨‍💻 Developer Features
- Code updates instantly (hot reload)
- Clean, easy-to-read code
- Simple to modify and extend

## How the code is organized

```
lib/
├── main.dart                 # App starts here
├── screens/                  # All the app screens
│   ├── chat_screen.dart      # Main chat screen
│   └── money_screen.dart     # Wallet and payments
├── services/                 # Talks to servers
│   ├── chat_service.dart     # Handles AI chat
│   ├── money_service.dart    # Handles payments
│   └── image_chat_service.dart # Handles pictures
├── models/                   # Data structures
└── widgets/                  # UI components
```

## Important files

- `lib/main.dart` - The app starts here
- `lib/screens/chat_screen.dart` - Where you chat with AI
- `lib/screens/money_screen.dart` - Your wallet and payments
- `lib/services/chat_service.dart` - Connects to AI
- `lib/services/money_service.dart` - Handles money stuff
- `pubspec.yaml` - Lists what the app needs to work

## Setting up the server

The app needs a backend server:
- For testing: `http://localhost:8000`
- For Android: `http://192.168.29.64:8000`

## Build for real use

- **Android app**: `flutter build apk`
- **Website**: `flutter build web`
- **Windows app**: `flutter build windows`

## Test everything works

Run `flutter test` to check if everything is working properly.

## Recent updates

- ✅ Added wallet and payment features
- ✅ Fixed app freezing issues on Android
- ✅ Improved image upload system
- ✅ Better error messages
- ✅ Cleaner code structure
- ✅ All tests pass

## If something breaks

Try these steps:
1. Run `flutter clean && flutter pub get`
2. Make sure the backend server is running
3. Update Flutter: `flutter upgrade`
4. Check system: `flutter doctor`

## Project structure explained

This app uses clean architecture:
- **Screens**: What users see
- **Services**: How app talks to servers
- **Models**: How data is structured
- **Widgets**: Reusable UI pieces

## License

This project is licensed under **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)**.

### What this means:
- ✅ **You can**: Use, modify, and share this code
- ✅ **You must**: Give credit to the original creator
- ✅ **You must**: Use the same license for your version
- ❌ **You cannot**: Use this for commercial purposes (making money)

### Full license text:
https://creativecommons.org/licenses/by-nc-sa/4.0/

### Simple explanation:
Feel free to learn from this code, make it better, and share your improvements. Just don't sell it or use it in a business without permission.

---

**That's it!** A simple AI chat app with payments that just works. 🚀