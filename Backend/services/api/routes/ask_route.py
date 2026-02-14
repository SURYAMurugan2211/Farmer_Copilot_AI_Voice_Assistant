from fastapi import APIRouter
from pydantic import BaseModel
from services.translate.translator import translate
from services.nlu.nlu import detect_intent, extract_entities
from services.rag.retriever import semantic_search
from services.rag.groq_composer import compose
from services.tts.tts_service import synthesize_tts

router = APIRouter()

class Ask(BaseModel):
    text: str
    lang: str = "en"

@router.post("/")
async def ask(payload: Ask):
    q_en = translate(payload.text, payload.lang, "en") if payload.lang != "en" else payload.text
    retrieved = semantic_search(q_en)
    answer_en = compose(q_en, retrieved)
    answer_local = translate(answer_en, "en", payload.lang)
    # Detect language for TTS
    tts_lang = "ta" if payload.lang == "ta" else "en"
    audio_url = synthesize_tts(answer_local, lang=tts_lang)
    return {"answer_text": answer_local, "audio_url": audio_url}

@router.get("/test")
async def test_services():
    """Test endpoint to check if all services are working"""
    # Test retriever
    retrieved = semantic_search("farming")
    
    # Test composer
    test_answer = compose("What is farming?", retrieved)
    
    return {
        "retriever_working": len(retrieved) > 0,
        "retrieved_docs": len(retrieved),
        "composer_working": len(test_answer) > 0,
        "sample_retrieved": retrieved[0] if retrieved else None,
        "sample_answer": test_answer[:100] + "..." if len(test_answer) > 100 else test_answer
    }
