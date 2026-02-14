# 🌾 Farmer Copilot Mobile App

A Flutter mobile application that connects to the Farmer Copilot AI backend to provide voice-first agricultural assistance in multiple languages.

## 🚀 Features

- **Voice-to-Voice Interaction**: Record questions and get audio responses
- **Multi-Language Support**: English, Tamil, Hindi, Telugu, Kannada, Malayalam
- **Text Queries**: Type questions when voice isn't convenient
- **Real-time Responses**: Get instant AI-powered farming advice
- **Query History**: Track all your farming questions and answers
- **Offline Indicators**: Know when you're connected to the server
- **User Profiles**: Register and manage your farming profile

## 📱 Screenshots

The app features:
- Clean, farmer-friendly interface
- Large voice recording button for field use
- Language selector for native language support
- Response cards with audio playback
- History tracking with expandable cards
- Settings for user management

## 🛠 Setup Instructions

### Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **Android Studio** or **VS Code** with Flutter extensions
3. **Farmer Copilot Backend** running on your server

### Installation

1. **Clone and Navigate**
   ```bash
   cd Farmer_copilot/Mobile
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Backend URL**
   
   Edit `lib/services/api_service.dart` and update the base URL:
   ```dart
   static const String baseUrl = 'http://YOUR_SERVER_IP:8000';
   ```
   
   For local testing:
   - Android Emulator: `http://10.0.2.2:8000`
   - Physical Device: `http://YOUR_COMPUTER_IP:8000`

4. **Run the App**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Backend Connection

Update the API service configuration in `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Change this
  // ... rest of the configuration
}
```

### Permissions

The app requires these permissions (already configured):
- **Microphone**: For voice recording
- **Internet**: For API communication
- **Storage**: For temporary audio files

## 📋 Usage Guide

### 1. First Launch
- Select your preferred language
- Optionally register with your name and phone number
- Start asking farming questions!

### 2. Voice Queries
- Tap the microphone button
- Speak your farming question clearly
- Wait for the AI response with audio playback

### 3. Text Queries
- Switch to the "Text" tab
- Type your question
- Get written responses with optional audio

### 4. View History
- Tap the history icon in the app bar
- Expand any previous query to see the full response
- Clear history from settings if needed

## 🌐 Supported Languages

| Language | Code | Native Name |
|----------|------|-------------|
| English | `en` | English |
| Tamil | `ta` | தமிழ் |
| Hindi | `hi` | हिन्दी |
| Telugu | `te` | తెలుగు |
| Kannada | `kn` | ಕನ್ನಡ |
| Malayalam | `ml` | മലയാളം |

## 🏗 Architecture

### State Management
- **Riverpod** for reactive state management
- **Providers** for API services and user state
- **AsyncValue** for handling loading/error states

### Key Components
- **ApiService**: HTTP client for backend communication
- **Providers**: State management for user, language, queries
- **Widgets**: Reusable UI components
- **Screens**: Main app screens (Home, Settings, History)

### File Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── api_models.dart      # Data models
├── providers/
│   └── app_providers.dart   # State management
├── screens/
│   ├── home_screen.dart     # Main interface
│   ├── settings_screen.dart # User settings
│   └── history_screen.dart  # Query history
├── services/
│   └── api_service.dart     # Backend communication
└── widgets/
    ├── voice_input_widget.dart
    ├── text_input_widget.dart
    ├── query_response_widget.dart
    ├── language_selector.dart
    └── connection_status_widget.dart
```

## 🔍 Troubleshooting

### Common Issues

1. **Connection Failed**
   - Check if backend server is running
   - Verify the IP address in `api_service.dart`
   - Ensure phone and server are on same network

2. **Voice Recording Not Working**
   - Grant microphone permissions
   - Check device microphone functionality
   - Try restarting the app

3. **Audio Playback Issues**
   - Check device volume settings
   - Ensure internet connection for audio URLs
   - Try using headphones

### Debug Mode

Run in debug mode to see detailed logs:
```bash
flutter run --debug
```

## 🚀 Building for Release

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

The built files will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

## 🔮 Future Enhancements

- **Offline Mode**: Cache responses for offline use
- **Push Notifications**: Farming tips and reminders
- **Image Upload**: Photo-based crop disease detection
- **Weather Integration**: Local weather information
- **Market Prices**: Real-time commodity pricing
- **Community Features**: Connect with other farmers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Farmer Copilot Backend Team** for the AI services
- **Flutter Community** for excellent packages
- **Farmers** who provided feedback and requirements

---

**🌾 Happy Farming with AI! 👨‍🌾📱**