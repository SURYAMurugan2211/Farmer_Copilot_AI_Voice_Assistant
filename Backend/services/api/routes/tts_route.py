from fastapi import APIRouter
from pydantic import BaseModel
from services.tts.tts_service import synthesize_tts

router = APIRouter()

class TTSRequest(BaseModel):
    text: str
    lang: str = "en"  # Language code: en, ta, hi, etc.

@router.post("/")
async def text_to_speech(request: TTSRequest):
    """
    Convert text to speech
    Returns URL to generated audio file
    """
    try:
        audio_url = synthesize_tts(request.text, lang=request.lang)
        return {
            "success": True,
            "audio_url": audio_url,
            "text": request.text,
            "language": request.lang
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

@router.get("/languages")
async def get_supported_languages():
    """Get list of supported TTS languages"""
    return {
        "languages": [
            {"code": "en", "name": "English"},
            {"code": "ta", "name": "Tamil"},
            {"code": "hi", "name": "Hindi"},
            {"code": "te", "name": "Telugu"},
            {"code": "kn", "name": "Kannada"},
            {"code": "ml", "name": "Malayalam"}
        ]
    }