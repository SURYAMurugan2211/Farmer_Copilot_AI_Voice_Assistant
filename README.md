# 🌾 Farmer Copilot - AI Voice Assistant for Farmers

An intelligent, multilingual voice assistant designed to help farmers access agricultural information through natural voice conversations. Built with Python (FastAPI), Flutter, and powered by local AI models.

![Version](https://img.shields.io/badge/version-2.0.0-green)
![Python](https://img.shields.io/badge/python-3.8+-blue)
![Flutter](https://img.shields.io/badge/flutter-3.0+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🎯 Features

### Core Capabilities
- 🎤 **Voice-to-Voice Interaction** - Speak naturally, get audio responses
- 🌍 **Multi-Language Support** - English, Tamil, Hindi, Telugu, Kannada, Malayalam
- 🤖 **Local AI Processing** - Privacy-first with on-device LLM (LLaMA)
- 🔍 **Semantic Search** - RAG-based knowledge retrieval
- 💬 **Conversation Context** - Remembers previous interactions
- 📊 **Smart Caching** - Fast responses with intelligent caching
- 📱 **Cross-Platform** - Web, Android, iOS, Windows support

### Technical Features
- **ASR (Automatic Speech Recognition)** - Whisper model
- **TTS (Text-to-Speech)** - Multi-language voice synthesis
- **NLU (Natural Language Understanding)** - Intent detection & entity extraction
- **RAG Pipeline** - Retrieval-Augmented Generation
- **User Management** - Query history, feedback system
- **Analytics** - Usage tracking and performance monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                       │
│  (Voice Input → API → Audio Response + Text Display)        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   ASR    │→ │   NLU    │→ │   RAG    │→ │   TTS    │   │
│  │ (Whisper)│  │(Intent)  │  │ (LLaMA)  │  │ (gTTS)   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│         ↓            ↓             ↓             ↓          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Database (SQLite/PostgreSQL)                 │  │
│  │  Users | Queries | Feedback | Documents             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
Farmer_copilot/
├── Backend/                    # Python FastAPI Backend
│   ├── services/
│   │   ├── api/               # API routes and app
│   │   ├── asr/               # Speech recognition
│   │   ├── tts/               # Text-to-speech
│   │   ├── nlu/               # Natural language understanding
│   │   ├── rag/               # RAG pipeline (retriever + LLM)
│   │   ├── translate/         # Multi-language translation
│   │   ├── db/                # Database models and services
│   │   ├── ai/                # Conversation context & caching
│   │   └── analytics/         # Usage analytics
│   ├── storage/               # Audio, cache, documents
│   ├── tests/                 # Property-based tests
│   └── requirements.txt       # Python dependencies
│
├── Mobile/                     # Flutter Mobile App
│   ├── lib/
│   │   ├── screens/           # UI screens
│   │   ├── widgets/           # Reusable widgets
│   │   ├── services/          # API service
│   │   ├── models/            # Data models
│   │   └── providers/         # State management
│   └── pubspec.yaml           # Flutter dependencies
│
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

**Backend:**
- Python 3.8+
- FFmpeg (for audio processing)
- 8GB+ RAM (for LLaMA model)

**Mobile:**
- Flutter 3.0+
- Chrome (for web testing)

### Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/SURYAMurugan2211/Final-Year-Project.git
cd Final-Year-Project/Farmer_copilot
```

#### 2. Setup Backend
```bash
cd Backend

# Create virtual environment
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Create .env file
copy .env.example .env

# Start server
python -m uvicorn services.api.app:app --reload --host 0.0.0.0 --port 8000
```

#### 3. Setup Mobile App
```bash
cd Mobile

# Get dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Or run on Android/iOS
flutter run
```

### Access the Application

- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Mobile App**: Opens automatically in Chrome

## 🎮 Usage

### Voice Query Flow

1. **Open the app** - Flutter app launches in browser/mobile
2. **Select language** - Choose your preferred language
3. **Tap microphone** - Start recording your question
4. **Speak naturally** - Ask about farming, crops, weather, etc.
5. **Get response** - Receive both text and audio response

### Example Queries

- "What is the best fertilizer for rice?"
- "How do I control pests in tomato plants?"
- "When should I plant wheat?"
- "What are the symptoms of leaf blight?"

## 🔧 Configuration

### Backend Configuration (.env)

```env
# Database
DATABASE_URL=sqlite:///./farmer_copilot.db

# Weaviate (Vector DB)
WEAVIATE_URL=http://localhost:8080

# Models
WHISPER_MODEL=base
LLAMA_MODEL_PATH=models/llama-2-7b

# API
API_HOST=0.0.0.0
API_PORT=8000
```

### Mobile Configuration

Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8000';
```

## 🧪 Testing

### Backend Tests
```bash
cd Backend

# Run all tests
pytest

# Run specific test
pytest tests/test_property_voice_pipeline.py

# Run with coverage
pytest --cov=services tests/
```

### Mobile Tests
```bash
cd Mobile

# Run tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📊 API Endpoints

### Mobile API
- `POST /api/mobile/voice-query` - Voice-to-voice query
- `POST /api/mobile/text-query` - Text-based query
- `GET /api/mobile/languages` - Get supported languages
- `GET /api/mobile/health-mobile` - Health check

### User Management
- `GET /api/users/{user_id}` - Get user details
- `GET /api/users/{user_id}/queries` - Get query history
- `POST /api/users/{user_id}/feedback` - Submit feedback

### Analytics
- `GET /api/analytics/usage` - Usage statistics
- `GET /api/analytics/performance` - Performance metrics

## 🛠️ Development

### Adding New Languages

1. Update `mobile_route.py`:
```python
supported_languages = ["en", "ta", "hi", "te", "kn", "ml", "new_lang"]
```

2. Update Flutter `api_service.dart`:
```dart
final languages = await getLanguages();
```

### Adding New Intents

Edit `Backend/services/nlu/entity_rules.json`:
```json
{
  "new_intent": {
    "keywords": ["keyword1", "keyword2"],
    "entities": ["entity_type"]
  }
}
```

## 📈 Performance

- **Voice Query Latency**: ~3-5 seconds
- **Text Query Latency**: ~1-2 seconds
- **Concurrent Users**: 50+ (with caching)
- **Model Size**: ~4GB (LLaMA-2-7B)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **SURYA Murugan** - Lead Developer
- Final Year Project - [Your University Name]

## 🙏 Acknowledgments

- **Whisper** - OpenAI's speech recognition model
- **LLaMA** - Meta's language model
- **Flutter** - Google's UI framework
- **FastAPI** - Modern Python web framework
- **Weaviate** - Vector database for semantic search

## 📞 Support

For issues and questions:
- 📧 Email: suryamurugan2211@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/SURYAMurugan2211/Final-Year-Project/issues)

## 🗺️ Roadmap

- [ ] Add more Indian languages (Bengali, Marathi, Gujarati)
- [ ] Implement offline mode
- [ ] Add image recognition for crop diseases
- [ ] Weather integration
- [ ] Market price information
- [ ] Community forum
- [ ] Expert consultation booking

---

**Made with ❤️ for Farmers**
