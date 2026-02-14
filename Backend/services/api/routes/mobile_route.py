"""
Mobile API Routes — Voice and Text query endpoints.
Full pipeline: ASR → Translate → NLU → RAG → LLM → Translate → TTS
Stores both user input audio and response audio with all query data.
"""

from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import Optional
import uuid
import os
import shutil
import aiofiles
import time

from services.asr.asr_service import transcribe
from services.translate.translator import translate, auto_translate_to_english
from services.nlu.nlu import detect_intent, extract_entities
from services.rag.retriever import semantic_search
from services.rag.groq_composer import compose
from services.tts.tts_service import synthesize_tts

router = APIRouter()


class MobileQuery(BaseModel):
    text: str
    lang: str = "en"
    user_id: Optional[int] = None
    phone_number: Optional[str] = None
    session_id: Optional[str] = None


class VoiceQuery(BaseModel):
    lang: str = "en"
    user_id: Optional[int] = None
    phone_number: Optional[str] = None
    session_id: Optional[str] = None


# Storage directories
TMP = os.path.abspath("storage/temp")
VOICE_INPUT_DIR = os.path.abspath("storage/voice_inputs")
os.makedirs(TMP, exist_ok=True)
os.makedirs(VOICE_INPUT_DIR, exist_ok=True)


# ─────────────────────────────────────────────
# Helper: Safe DB operations
# ─────────────────────────────────────────────

def _safe_get_user(phone_number=None, user_id=None, lang="en"):
    """Get user from DB; returns (user, user_id) or (None, user_id)."""
    try:
        from services.db.user_service import UserService
        if phone_number:
            user = UserService.create_or_get_user(phone_number=phone_number, language=lang)
            return user, user.id
        elif user_id:
            user = UserService.get_user_by_id(user_id)
            return user, user_id
    except Exception as e:
        print(f"DB user lookup skipped: {e}")
    return None, user_id


def _safe_save_query(**kwargs):
    """Save query to DB; returns saved_query or None."""
    if not kwargs.get("user_id"):
        return None
    try:
        from services.db.user_service import QueryService
        return QueryService.save_query(**kwargs)
    except Exception as e:
        print(f"DB save skipped: {e}")
        import traceback
        traceback.print_exc()
    return None


def _save_input_audio(temp_path: str) -> str:
    """
    Move user's voice recording from temp to permanent storage.
    Returns the relative URL path (e.g., /voice_inputs/abc123.wav).
    """
    try:
        filename = f"{uuid.uuid4().hex}.wav"
        permanent_path = os.path.join(VOICE_INPUT_DIR, filename)
        shutil.copy2(temp_path, permanent_path)
        return f"/voice_inputs/{filename}"
    except Exception as e:
        print(f"Could not save input audio: {e}")
        return ""


# ─────────────────────────────────────────────
# VOICE QUERY ENDPOINT
# ─────────────────────────────────────────────

@router.post("/voice-query")
async def voice_query(
    lang: str = "en",
    user_id: Optional[int] = None,
    phone_number: Optional[str] = None,
    session_id: Optional[str] = None,
    file: UploadFile = File(...)
):
    """
    Full voice-to-voice pipeline:
    Audio → ASR → Translate(user→en) → NLU → RAG → LLM → Translate(en→user) → TTS
    Both input audio and response audio are saved to DB.
    """
    start_time = time.time()

    try:
        # User lookup
        user, user_id = _safe_get_user(phone_number, user_id, lang)

        # ── Step 1: Save uploaded audio ──
        temp_path = f"{TMP}/{uuid.uuid4().hex}.wav"
        async with aiofiles.open(temp_path, "wb") as f:
            data = await file.read()
            await f.write(data)
            await f.flush()

        if not os.path.exists(temp_path) or os.path.getsize(temp_path) == 0:
            raise HTTPException(status_code=400, detail="Audio file is empty or failed to save")

        # Save a permanent copy of the user's voice input
        input_audio_url = _save_input_audio(temp_path)
        print(f"[1/7] Audio saved: {os.path.getsize(temp_path)} bytes → {input_audio_url}")

        # ── Step 2: ASR (Speech → Text) ──
        asr_result = transcribe(temp_path, language=lang if lang != "auto" else None)
        transcribed_text = asr_result["text"]
        detected_lang = asr_result.get("lang", lang)
        print(f"[2/7] ASR: '{transcribed_text[:60]}...' (lang={detected_lang})")

        # ── Step 3: Translate to English (handles mixed-language) ──
        query_en, source_lang = auto_translate_to_english(transcribed_text, hint_lang=detected_lang)
        if source_lang != "en":
            print(f"[3/7] Auto-translated ({source_lang}→en): '{query_en[:60]}...'")
        else:
            print(f"[3/7] Translate: skipped (already English)")
        detected_lang = source_lang

        # ── Step 4: NLU (Intent + Entities) ──
        intent_result = detect_intent(query_en)
        entities = extract_entities(query_en)
        print(f"[4/7] NLU: intent={intent_result['intent']}, entities={entities}")

        # ── Step 5: RAG (Retrieve + LLM) ──
        retrieved = semantic_search(query_en, k=5)
        answer_en = compose(query_en, retrieved)
        print(f"[5/7] RAG: {len(retrieved)} docs → answer={answer_en[:60]}...")

        # ── Step 6: Translate answer back ──
        if detected_lang != "en":
            answer_local = translate(answer_en, "en", detected_lang)
            print(f"[6/7] Translated (en→{detected_lang}): '{answer_local[:60]}...'")
        else:
            answer_local = answer_en
            print(f"[6/7] Translate: skipped (English user)")

        # ── Step 7: TTS (Text → Speech) ──
        tts_lang = detected_lang if detected_lang in ["en", "ta", "hi", "te", "kn", "ml"] else "en"
        response_audio_relative = synthesize_tts(answer_local, lang=tts_lang)
        response_audio_url = f"http://localhost:8000{response_audio_relative}"
        print(f"[7/7] TTS: {response_audio_url}")

        # ── Save to DB with full data ──
        processing_time = time.time() - start_time
        saved_query = _safe_save_query(
            user_id=user_id,
            original_text=transcribed_text,
            translated_text=query_en,
            intent=intent_result.get("intent", "unknown"),
            confidence=intent_result.get("confidence", 0.0),
            response_text=answer_local,
            response_text_en=answer_en,
            input_audio_url=input_audio_url,
            response_audio_url=response_audio_url,
            language=lang,
            detected_language=detected_lang,
            processing_time=processing_time,
            source_count=len(retrieved),
            query_type="voice",
        )

        print(f"Pipeline complete in {processing_time:.2f}s (query_id={saved_query.id if saved_query else 'N/A'})")

        return {
            "success": True,
            "transcribed_text": transcribed_text,
            "detected_language": detected_lang,
            "intent": intent_result,
            "entities": entities,
            "answer_text": answer_local,
            "input_audio_url": f"http://localhost:8000{input_audio_url}" if input_audio_url else None,
            "response_audio_url": response_audio_url,
            "retrieved_sources": len(retrieved),
            "session_id": session_id or str(uuid.uuid4()),
            "query_id": saved_query.id if saved_query else None,
            "user_id": user_id,
            "processing_time": round(processing_time, 2),
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"Voice query error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Voice query failed: {str(e)}")


# ─────────────────────────────────────────────
# TEXT QUERY ENDPOINT
# ─────────────────────────────────────────────

@router.post("/text-query")
async def text_query(payload: MobileQuery):
    """
    Text-based query pipeline:
    Text → Translate(user→en) → NLU → RAG → LLM → Translate(en→user) → TTS
    """
    start_time = time.time()

    try:
        # User lookup
        user, user_id = _safe_get_user(payload.phone_number, payload.user_id, payload.lang)

        # ── Step 1: Translate to English ──
        query_en, detected_lang = auto_translate_to_english(payload.text, hint_lang=payload.lang)

        # ── Step 2: NLU ──
        intent_result = detect_intent(query_en)
        entities = extract_entities(query_en)

        # ── Step 3: RAG + LLM ──
        retrieved = semantic_search(query_en, k=5)
        answer_en = compose(query_en, retrieved)

        # ── Step 4: Translate answer back ──
        response_lang = payload.lang if payload.lang != "auto" else detected_lang
        if response_lang != "en":
            answer_local = translate(answer_en, "en", response_lang)
        else:
            answer_local = answer_en

        # ── Step 5: TTS ──
        tts_lang = response_lang if response_lang in ["en", "ta", "hi", "te", "kn", "ml"] else "en"
        response_audio_relative = synthesize_tts(answer_local, lang=tts_lang)
        response_audio_url = f"http://localhost:8000{response_audio_relative}"

        # ── Save to DB with full data ──
        processing_time = time.time() - start_time
        saved_query = _safe_save_query(
            user_id=user_id,
            original_text=payload.text,
            translated_text=query_en,
            intent=intent_result.get("intent", "unknown"),
            confidence=intent_result.get("confidence", 0.0),
            response_text=answer_local,
            response_text_en=answer_en,
            input_audio_url=None,  # No audio for text queries
            response_audio_url=response_audio_url,
            language=payload.lang,
            detected_language=detected_lang,
            processing_time=processing_time,
            source_count=len(retrieved),
            query_type="text",
        )

        return {
            "success": True,
            "query": payload.text,
            "language": payload.lang,
            "detected_language": detected_lang,
            "intent": intent_result,
            "entities": entities,
            "answer_text": answer_local,
            "response_audio_url": response_audio_url,
            "sources": [
                {"text": doc["text"][:200] + "...", "source": doc.get("source", "unknown")}
                for doc in retrieved[:3]
            ],
            "session_id": payload.session_id or str(uuid.uuid4()),
            "query_id": saved_query.id if saved_query else None,
            "user_id": user_id,
            "processing_time": round(processing_time, 2),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Text query failed: {str(e)}")


# ─────────────────────────────────────────────
# CONVERSATION HISTORY ENDPOINT
# ─────────────────────────────────────────────

@router.get("/history/{user_id}")
async def get_conversation_history(user_id: int, limit: int = 20):
    """Get a user's conversation history with audio URLs."""
    try:
        from services.db.user_service import QueryService
        history = QueryService.get_conversation_history(user_id, limit=limit)
        return {"success": True, "history": history, "count": len(history)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get history: {str(e)}")


@router.get("/stats/{user_id}")
async def get_user_stats(user_id: int):
    """Get user query statistics."""
    try:
        from services.db.user_service import QueryService
        stats = QueryService.get_user_stats(user_id)
        return {"success": True, "stats": stats}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")


# ─────────────────────────────────────────────
# UTILITY ENDPOINTS
# ─────────────────────────────────────────────

@router.get("/languages")
async def get_supported_languages():
    """Get supported languages for mobile app."""
    return {
        "languages": [
            {"code": "en", "name": "English", "native": "English"},
            {"code": "ta", "name": "Tamil", "native": "தமிழ்"},
            {"code": "hi", "name": "Hindi", "native": "हिन्दी"},
            {"code": "te", "name": "Telugu", "native": "తెలుగు"},
            {"code": "kn", "name": "Kannada", "native": "ಕನ್ನಡ"},
            {"code": "ml", "name": "Malayalam", "native": "മലയாളം"},
        ]
    }


@router.get("/health-mobile")
async def mobile_health_check():
    """Mobile-specific health check."""
    from services.rag.vector_store import get_store_stats

    store_stats = get_store_stats()

    return {
        "status": "healthy",
        "services": {
            "asr": True,
            "translator": True,
            "rag": store_stats["total_documents"] > 0,
            "tts": True,
        },
        "knowledge_base": {
            "documents": store_stats["total_documents"],
        },
        "version": "2.0.0",
        "supported_features": [
            "voice_query",
            "text_query",
            "multi_language",
            "mixed_language",
            "audio_storage",
            "conversation_history",
        ],
    }