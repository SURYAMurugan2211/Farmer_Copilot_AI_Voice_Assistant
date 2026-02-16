# 🌾 Farmer Copilot - AI-Powered Agricultural Assistant (Backend)

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.124.0-green.svg)](https://fastapi.tiangolo.com)
[![AI](https://img.shields.io/badge/AI-Groq_LPU-orange.svg)](https://groq.com)
[![Database](https://img.shields.io/badge/DB-SQLite%20%7C%20ChromaDB-blue.svg)](#)

> **The intelligent brain behind Farmer Copilot: Fast, accurate, and multi-lingual.**

This backend powers the Farmer Copilot mobile app, handling voice processing, RAG (Retrieval Augmented Generation), and multi-language translation.

---

## 🏗️ **Architecture & Tech Stack**

### 🧠 **AI Core (The Brain)**

- **LLM Inference**: **Groq API** (running LLaMA 3-70B). Why? It's lightning fast (sub-second responses) compared to running local models.
- **Vector Store**: **ChromaDB**. Stores embeddings of agricultural PDFs locally for semantic search.
- **Embeddings**: `sentence-transformers/all-MiniLM-L6-v2`. Lightweight and effective for English/translated text.

### 🗣️ **Voice & Language**

- **ASR (Ears)**: **OpenAI Whisper**. Converts farmer's voice (in any language) to text.
- **TTS (Mouth)**: **gTTS**. Converts AI text responses back to speech.
- **Translation**: `deep-translator`. Bridges the gap between English AI models and 6 Indian languages.

### ⚙️ **Infrastructure**

- **Framework**: **FastAPI**. High-performance async Python web framework.
- **Database**: **SQLite**. Stores user profiles, query history, and feedback. Simple and file-based.
- **Storage**: Local file system for PDFs, Audio cache, and Vector DB integrity.

---

## 🚀 **Quick Start**

### 1. **Prerequisites**

- Python 3.11+
- A **Groq API Key** (Get it free at [console.groq.com](https://console.groq.com))
- FFmpeg (for audio processing)

### 2. **Installation**

```bash
# Navigate to Backend folder
cd Backend

# Create Virtual Environment
python -m venv .venv
# Activate:
#   Windows: .venv\Scripts\activate
#   Mac/Linux: source .venv/bin/activate

# Install Dependencies
pip install -r requirements.txt
```

### 3. **Configuration**

Create a `.env` file in the `Backend/` directory:

```env
# AI Configuration
GROQ_API_KEY=gsk_your_key_here_xxxxxxxxxx
EMBEDDING_MODEL=all-MiniLM-L6-v2

# Database
DATABASE_URL=sqlite:///./farmer_copilot.db

# Server
HOST=0.0.0.0
PORT=8000
```

### 4. **Run the Server**

```bash
uvicorn services.api.app:app --reload --host 0.0.0.0 --port 8000
```

Open interactve docs at: `http://localhost:8000/docs`

---

## 🔮 **Key Systems Explained**

### **1. RAG Pipeline (Retrieval Augmented Generation)**

When a farmer asks _"How to grow rice?"_:

1.  **Retriever**: Searches `ChromaDB` for relevant chunks from uploaded PDFs.
2.  **Composer**: Sends the question + retrieved chunks to **Groq**.
3.  **Generator**: Groq (LLaMA 3) writes a precise answer based _only_ on the provided facts.

### **2. Multi-Language Voice Loop**

1.  **Input**: User speaks in **Tamil**.
2.  **ASR**: Whisper transcribes audio -> Tamil Text.
3.  **Translate**: Tamil Text -> English Text.
4.  **Process**: RAG Pipeline generates English Answer.
5.  **Translate**: English Answer -> Tamil Answer.
6.  **TTS**: Tamil Text -> Tamil Audio.
7.  **Output**: App plays Tamil Audio.

---

## 📂 **Directory Structure**

- `services/` - Core logic
  - `api/` - FastAPI routes
  - `rag/` - ChromaDB & Groq logic
  - `asr/` - Whisper logic
  - `tts/` - gTTS logic
  - `nlu/` - Intent classification
- `storage/` - Data persistence
  - `chroma_db/` - Vector database files
  - `pdfs/` - Raw knowledge base documents
  - `sqlite/` - User database
- `scripts/` - Utility scripts
  - `ingest_pdfs.py` - Add new documents to AI

---

## 🧪 **Testing**

Run the included tests to verify your setup:

```bash
# Test the RAG pipeline primarily
python scripts/test_rag.py

# Run full test suite
pytest
```

---

**Made with ❤️ for Indian Farmers**
