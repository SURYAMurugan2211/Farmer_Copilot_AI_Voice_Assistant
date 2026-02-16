# 🌾 Farmer Copilot - AI Voice Assistant for Farmers

An intelligent, multilingual voice assistant designed to empower farmers with instant agricultural knowledge. Built with a modern tech stack featuring **FastAPI**, **Flutter**, and **Local AI (Groq/LLaMA 3)**.

![Status](https://img.shields.io/badge/Status-System_Ready-success)
![Python](https://img.shields.io/badge/Python-3.11-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B)
![AI Model](https://img.shields.io/badge/AI-LLaMA_3_70B-orange)

---

## 🚀 Key Features

### 🎤 Voice-First Interface

- **Speak Naturally**: Farmers can ask questions in their local language.
- **Audio Responses**: The app speaks back the answer, making it accessible for everyone.
- **Hands-Free**: Designed for use in the field.

### 🌍 Multi-Language Support

Complete support for **6 Indian Languages**:

- 🇺🇸 English
- 🇮🇳 Tamil (தமிழ்)
- 🇮🇳 Hindi (हिन्दी)
- 🇮🇳 Telugu (తెలుగు)
- 🇮🇳 Kannada (ಕನ್ನಡ)
- 🇮🇳 Malayalam (മലയാളം)

### 🧠 Advanced AI Reasoning

- **RAG (Retrieval Augmented Generation)**: Combines LLM intelligence with specific agricultural documents.
- **Groq LPU Inference**: Blazing fast responses using LLaMA 3 70B on Groq Cloud.
- **Context Awareness**: Remembers previous questions for a natural conversation flow.

### 📚 Knowledge Base

- **Vector Search**: Uses **ChromaDB** to store and retrieve relevant farming guides.
- **PDF Ingestion**: Automatically learns from uploaded agricultural PDFs.

---

## 🏗️ Technical Architecture

### Backend (Python/FastAPI)

The brain of the operation, handling all AI processing.

- **Framework**: FastAPI (High performance async framework).
- **ASR (Speech-to-Text)**: OpenAI Whisper (Local or Cloud).
- **LLM Engine**: Groq API (LLaMA 3-70B-8192) for sub-second inference.
- **Vector Database**: ChromaDB (Local persistence) with `all-MiniLM-L6-v2` embeddings.
- **TTS (Text-to-Speech)**: gTTS (Google Text-to-Speech) for natural sounding audio.

### Mobile App (Flutter)

The user interface for farmers.

- **Cross-Platform**: Runs on Android, iOS, and Web.
- **State Management**: Riverpod.
- **Audio**: Integrated audio recording and playback.

---

## 📂 Project Structure

```
Farmer_copilot/
├── Backend/                 # Python Server
│   ├── services/
│   │   ├── api/            # API Routes & App
│   │   ├── rag/            # Vector Store (ChromaDB) & Retriever
│   │   ├── asr/            # Whisper Speech Recognition
│   │   ├── tts/            # Text-to-Speech Generation
│   │   ├── translate/      # Multi-language Translation
│   │   └── nlu/            # Intent Detection
│   ├── storage/            # Local data (Audio, PDFs, ChromaDB)
│   ├── scripts/            # Utility scripts (PDF ingestion)
│   └── requirements.txt    # Dependencies
│
├── Mobile/                  # Flutter App
│   ├── lib/
│   │   ├── screens/        # UI Pages (Home, Mandi, Settings)
│   │   ├── services/       # API Integration
│   │   └── widgets/        # Reusable UI Components
│   └── pubspec.yaml        # Flutter Dependencies
```

---

## 🛠️ Installation & Setup

### Prerequisites

- **Python 3.11+**
- **Flutter SDK**
- **Groq API Key** (Get free from [console.groq.com](https://console.groq.com))

### 1. Backend Setup

```bash
cd Backend

# Create Virtual Environment
python -m venv .venv
# Activate:
# Windows: .venv\Scripts\activate
# Mac/Linux: source .venv/bin/activate

# Install Dependencies
pip install -r requirements.txt

# Configure Environment
# Copy .env.example to .env and add your GROQ_API_KEY
cp .env.example .env
```

### 2. Run the Backend

```bash
# Start the server (runs on port 8000)
uvicorn services.api.app:app --reload --host 0.0.0.0 --port 8000
```

### 3. Mobile App Setup

```bash
cd Mobile

# Install dependencies
flutter pub get

# Run on Chrome (for testing)
flutter run -d chrome

# Run on Android Device
flutter run -d <device_id>
```

---

## 🧪 Testing

### Test RAG Pipeline

You can test the retrieval system independently:

```bash
cd Backend
python scripts/test_rag.py
```

### Ingest New PDFs

To add new knowledge to the AI:

1.  Place PDFs in `Backend/storage/pdfs`
2.  Run ingestion script:
    ```bash
    python scripts/ingest_pdfs.py
    ```

---

## 🔮 Roadmap

- [ ] **Offline Mode**: Fully local LLM (Quantized LLaMA) for areas with no internet.
- [ ] **Image Diagnosis**: Detect crop diseases by taking a photo.
- [ ] **Market Prices**: Real-time integration with e-NAM mandi prices.
- [ ] **Expert Connect**: Video call feature with agri-experts.

---

**Made with ❤️ for Indian Farmers**
