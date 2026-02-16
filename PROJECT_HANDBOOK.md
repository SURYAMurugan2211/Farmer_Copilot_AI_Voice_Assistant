# 📖 Farmer Copilot - Project Handbook

This document explains **every single file and folder** in your project. Use this as your map to understand what everything does and why it exists.

---

## 🏗️ Root Directory (`Farmer_copilot/`)

| File / Folder         | Status       | Explanation                                                                    |
| :-------------------- | :----------- | :----------------------------------------------------------------------------- |
| **`Backend/`**        | **Critical** | The "Brain" of your project. Runs the Python server, handles AI, and database. |
| **`Mobile/`**         | **Critical** | The "Face" of your project. The Flutter app that farmers will use.             |
| **`README.md`**       | **Keep**     | The main overview of the project. Good for Github.                             |
| **`ROADMAP.md`**      | **Keep**     | Your plan for future features (like "Offline Mode" or "Mandi Prices").         |
| **`.gitignore`**      | **Keep**     | Tells Git which files to ignore (like large PDFs or passwords).                |
| **`SYSTEM_READY.md`** | **Optional** | A report confirming the system is working. You can delete this if you want.    |

---

## 🧠 Backend Structure (`Backend/`)

The server that processes voice, searches PDFs, and talks to Groq AI.

### 📂 `services/` (The Logic)

This is where the actual code lives.

| File / Folder                   | Explanation                                                                       | Why is it here?                                                                      |
| :------------------------------ | :-------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------- |
| **`api/app.py`**                | **The Web Server.**                                                               | It receives requests from the mobile app (e.g., "Here is audio, give me an answer"). |
| **`rag/`**                      | **Retrieval Augmented Generation.**                                               |
| ├── `vector_store.py`           | **The Database Manager.** Talks to ChromaDB to save/find PDF chunks.              |
| ├── `retriever.py`              | **The Search Engine.** Finds the best PDF page to answer a user's question.       |
| ├── `groq_composer.py`          | **The AI Writer.** Sends the question + PDF page to Groq API to write the answer. |
| **`asr/whisper_service.py`**    | **The Ears.**                                                                     | OpenAI Whisper. Converts voice (Audio) -> Text.                                      |
| **`tts/tts_service.py`**        | **The Mouth.**                                                                    | Google TTS. Converts answer (Text) -> Voice (Audio).                                 |
| **`translate/translator.py`**   | **The Translator.**                                                               | Converts Tamil/Hindi <-> English so the AI understands.                              |
| **`nlu/nlu.py`**                | **The Brain.**                                                                    | Decides if a user is saying "Hello" or asking a farming question.                    |
| **`ingestion/pdf_ingester.py`** | **The Reader.**                                                                   | Reads PDF files, breaks them into small text chunks for the database.                |

### 📂 `storage/` (The Data)

Where files are saved.

| Folder           | Explanation                                                              | Status          |
| :--------------- | :----------------------------------------------------------------------- | :-------------- |
| **`chroma_db/`** | **AI Memory.** Stores the "vectors" (mathematical meaning) of your PDFs. | **CRITICAL**    |
| **`pdfs/`**      | **Source Knowledge.** Put your farming guidelines/PDFs here.             | **Keep**        |
| **`sqlite/`**    | **User Info.** Stores user profiles and chat history.                    | **Critical**    |
| **`audio/`**     | **Temp Audio.** Stores generated MP3s.                                   | _Safe to clear_ |

### 📂 `scripts/` (Tools)

Helper programs to run manually.

| File                 | Explanation                                                                   | When to use?                  |
| :------------------- | :---------------------------------------------------------------------------- | :---------------------------- |
| **`ingest_pdfs.py`** | **Feeds the AI.** Reads all PDFs in `storage/pdfs` and adds them to ChromaDB. | Run when adding new PDFs.     |
| **`test_rag.py`**    | **Tests the AI.** Asks a test question to see if the AI answers correctly.    | Run to check if AI is broken. |
| **`setup.sh`**       | **Installer.** Helps install dependencies.                                    | Run once at setup.            |

---

## 📱 Mobile Structure (`Mobile/`)

The Flutter app that runs on Android/Web.

### 📂 `lib/` (The Code)

All your Dart code is here.

#### 1. Configuration (`lib/config/`)

| File             | Explanation                                                                   |
| :--------------- | :---------------------------------------------------------------------------- |
| **`theme.dart`** | **Styles.** Defines "Farmer Green" colors, font sizes, and app look-and-feel. |

#### 2. Models (`lib/models/`)

| File                    | Explanation                                                                                |
| :---------------------- | :----------------------------------------------------------------------------------------- |
| **`api_models.dart`**   | **Blueprints.** Defines what data from the server looks like (e.g., `VoiceQueryResponse`). |
| **`chat_message.dart`** | **Data Structure.** Defines a single chat bubble (text, isUser, timestamp).                |

#### 3. Providers (`lib/providers/`)

| File                     | Explanation                                                           |
| :----------------------- | :-------------------------------------------------------------------- |
| **`app_providers.dart`** | **Global State.** Remembers "Current Language" and "Is App Loading?". |
| **`chat_provider.dart`** | **Chat Logic.** Adds new messages to the list, clears history.        |

#### 4. Screens (`lib/screens/`)

| File                       | Explanation                                                  |
| :------------------------- | :----------------------------------------------------------- |
| **`splash_screen.dart`**   | **Loading Screen.** The logo you see when opening the app.   |
| **`home_screen.dart`**     | **Main Page.** The big microphone button and chat interface. |
| **`history_screen.dart`**  | **History Page.** Use this to see old questions.             |
| **`settings_screen.dart`** | **Settings Page.** Change language, clear data.              |

#### 5. Services (`lib/services/`)

| File                     | Explanation                                                                                   |
| :----------------------- | :-------------------------------------------------------------------------------------------- |
| **`api_service.dart`**   | **The Messenger.** Sends your voice file to `http://localhost:8000` and gets the JSON result. |
| **`audio_service.dart`** | **The Player.** Plays the MP3 response from the AI.                                           |

#### 6. Widgets (`lib/widgets/`)

| File                          | Explanation                                                   |
| :---------------------------- | :------------------------------------------------------------ |
| **`voice_orb_widget.dart`**   | **Animation.** The glowing circle that pulses when you speak. |
| **`chat_bubble_widget.dart`** | **UI.** The green/white message boxes.                        |
| **`language_selector.dart`**  | **UI.** The dropdown menu to pick Tamil/Hindi.                |
| **`voice_input_widget.dart`** | **UI.** The big microphone button logic.                      |

### 📂 Other Mobile Folders

| Folder             | Explanation                                                       | Status           |
| :----------------- | :---------------------------------------------------------------- | :--------------- |
| **`android/`**     | **Native Android.** Used to build `.apk` files.                   | **CRITICAL**     |
| **`web/`**         | **Web App.** Used to run in Chrome.                               | **CRITICAL**     |
| **`pubspec.yaml`** | **Dependency List.** Lists `riverpod`, `dio`, `google_fonts` etc. | **CRITICAL**     |
| **`assets/`**      | **Images.** Stores icons and images.                              | **Keep**         |
| **`build/`**       | **Trash.** Temporary compiled files.                              | _Safe to delete_ |

---

## 🛠Summary Checklist

1.  **To Add Knowledge:** Put PDF in `Backend/storage/pdfs` -> Run `python scripts/ingest_pdfs.py`.
2.  **To Fix AI:** Check `Backend/services/rag/groq_composer.py`.
3.  **To Change Colors:** Edit `Mobile/lib/config/theme.dart`.
4.  **To Change API URL:** Edit `Mobile/lib/services/api_service.dart`.
