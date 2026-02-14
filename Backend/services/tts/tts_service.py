"""
Text-to-Speech Service using gTTS (Google Text-to-Speech).
Generates MP3 audio files with caching to avoid redundant synthesis.
"""

from gtts import gTTS
import hashlib
import os

DIR = os.path.abspath("storage/audio")
os.makedirs(DIR, exist_ok=True)

# gTTS supported language codes
GTTS_LANGUAGES = {"en", "ta", "hi", "te", "kn", "ml", "mr", "bn", "gu", "pa", "ur"}


def synthesize_tts(text: str, lang: str = "en") -> str:
    """
    Convert text to speech audio file.

    Args:
        text: Text to convert
        lang: Language code (en, ta, hi, etc.)

    Returns:
        Relative URL path to the generated MP3 file
    """
    if not text or not text.strip():
        return ""

    # Fallback to English if language not supported by gTTS
    tts_lang = lang if lang in GTTS_LANGUAGES else "en"

    # Truncate very long text to avoid slow TTS
    if len(text) > 2000:
        text = text[:2000] + "..."

    # Cache key based on text + language
    key = hashlib.sha256(f"{text}_{tts_lang}".encode()).hexdigest()
    path = os.path.join(DIR, f"{key}.mp3")

    if not os.path.exists(path):
        try:
            tts = gTTS(text=text, lang=tts_lang, slow=False)
            tts.save(path)
        except Exception as e:
            print(f"TTS error ({tts_lang}): {e}")
            # Fallback: try English if original language failed
            if tts_lang != "en":
                try:
                    tts = gTTS(text=text, lang="en", slow=False)
                    tts.save(path)
                except Exception as e2:
                    print(f"TTS fallback also failed: {e2}")
                    return ""
            else:
                return ""

    return f"/audio/{key}.mp3"
