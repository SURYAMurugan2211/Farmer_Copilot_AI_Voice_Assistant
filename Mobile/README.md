# 🌾 Farmer Copilot - Mobile App

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Riverpod-purple.svg)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green.svg)](#)

A beautiful, voice-first mobile application connecting farmers to AI. Built with **Flutter** for cross-platform performance and **Riverpod** for robust state management.

---

## 📱 **Key Features**

- **🎙️ Voice-To-Voice**: One-tap recording creates a natural conversation with the AI.
- **🌍 6-Language UI**: App interface adapts to English, Tamil, Hindi, Telugu, Kannada, or Malayalam.
- **💬 Chat History**: Automatically saves and displays past interactions.
- **🔊 Audio Playback**: High-quality text-to-speech responses.
- **✨ Animations**: "Voice Orb" visualisation that pulses when you speak.

---

## 🛠️ **Tech Stack**

- **Framework**: Flutter (Dart)
- **State Management**: `flutter_riverpod` (Modern, compile-safe state)
- **Networking**: `dio` (Powerful HTTP client)
- **Audio**: `just_audio` & `record`
- **UI/UX**: `google_fonts`, `animate_do` (Fade/Slide animations)
- **Icons**: `lucide_icons`

---

## 📂 **Project Structure (`lib/`)**

We use a feature-first architecture to keep things organized.

| Directory                     | Purpose                                                         |
| :---------------------------- | :-------------------------------------------------------------- |
| **`main.dart`**               | App entry point. Sets up Riverpod (`ProviderScope`) and Themes. |
| **`screens/`**                | **The Pages you see.**                                          |
| ├── `home_screen.dart`        | Main dashboard with the big Mic button.                         |
| ├── `history_screen.dart`     | List of past questions & answers.                               |
| ├── `settings_screen.dart`    | Change language, clear history.                                 |
| ├── `splash_screen.dart`      | Animated logo on startup.                                       |
| **`services/`**               | **Talking to the Backend.**                                     |
| ├── `api_service.dart`        | Sends voice/text to FastAPI (`localhost:8000`).                 |
| ├── `audio_service.dart`      | Manages playing AI audio responses.                             |
| **`providers/`**              | **State Management (Riverpod).**                                |
| ├── `app_providers.dart`      | Global state (Current Language, Loading Status).                |
| ├── `chat_provider.dart`      | Chat history state (User messages vs AI messages).              |
| **`widgets/`**                | **Reusable UI Components.**                                     |
| ├── `voice_orb_widget.dart`   | The glowing animation when recording.                           |
| ├── `chat_bubble_widget.dart` | Green/White chat bubbles.                                       |
| ├── `language_selector.dart`  | Dropdown to pick languages.                                     |
| **`models/`**                 | **Data Structures.**                                            |
| ├── `api_models.dart`         | Defines `VoiceQueryResponse` format.                            |
| ├── `chat_message.dart`       | Defines what a "Message" looks like.                            |
| **`config/`**                 | **Theme & Constants.**                                          |
| ├── `theme.dart`              | App colors (Farmer Green), text styles.                         |

---

## 🚀 **How to Run**

### **1. Prerequisites**

- Flutter SDK installed.
- **Backend Server Running** (on `http://localhost:8000`).

### **2. Setup**

```bash
cd Mobile
flutter pub get
```

### **3. Run on Web (Chrome)** - _Recommended for testing_

```bash
flutter run -d chrome
# Runs on localhost:some_port
```

### **4. Run on Android**

1.  Connect your Android phone via USB (Debugging ON).
2.  Update `lib/services/api_service.dart`:
    ```dart
    // Change 'localhost' to your PC's IP address (e.g., 192.168.1.5)
    static const String baseUrl = 'http://192.168.1.5:8000';
    ```
3.  Run:
    ```bash
    flutter run
    ```

---

## 🔧 **Configuration**

### **API Connection**

Edit `lib/services/api_service.dart` to point to your backend:

```dart
class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/iOS Simulator
  static const String baseUrl = 'http://localhost:8000';
}
```

---

## 🐛 **Troubleshooting**

- **App stuck on "Connecting..."?**
  - Make sure the Backend (`uvicorn`) is running.
  - If on Android, ensure you are using your PC's IP, not `localhost`.
- **"Microphone permission denied"?**
  - Check your browser/phone settings and allow microphone access.

---

**Happy Coding! 🚜**
