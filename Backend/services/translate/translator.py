"""
Translation Service using deep-translator (Google Translate)
Supports all Indian languages, auto-detection, and mixed-language input.
"""

from deep_translator import GoogleTranslator
from typing import Optional, Tuple

# Supported language codes
SUPPORTED_LANGUAGES = {
    "en": "english",
    "ta": "tamil",
    "hi": "hindi",
    "te": "telugu",
    "kn": "kannada",
    "ml": "malayalam",
    "mr": "marathi",
    "bn": "bengali",
    "gu": "gujarati",
    "pa": "punjabi",
    "ur": "urdu",
}


def translate(text: str, src: str, tgt: str) -> str:
    """
    Translate text between languages using Google Translate.

    Args:
        text: Text to translate
        src: Source language code (e.g. "ta", "hi", "en", or "auto")
        tgt: Target language code

    Returns:
        Translated text string
    """
    if not text or not text.strip():
        return text

    # "auto" means let Google detect the source language
    if src == "auto":
        src = "auto"

    # Skip if same language (but not if auto-detecting)
    if src == tgt and src != "auto":
        return text

    try:
        translated = GoogleTranslator(source=src, target=tgt).translate(text)
        return translated if translated else text
    except Exception as e:
        print(f"Translation error ({src}->{tgt}): {e}")
        return text


def auto_translate_to_english(text: str, hint_lang: str = None) -> Tuple[str, str]:
    """
    Auto-detect language and translate to English.
    Handles mixed-language input (e.g., Tamil+English, Hindi+English).

    Args:
        text: Input text in any language (can be mixed)
        hint_lang: Optional language hint from ASR or user selection

    Returns:
        Tuple of (english_text, detected_language_code)
    """
    if not text or not text.strip():
        return text, "en"

    # Step 1: Try to detect the language
    detected_lang = None

    # Use Google Translate's auto-detection (handles mixed-language well)
    try:
        translator = GoogleTranslator(source="auto", target="en")
        english_text = translator.translate(text)

        if english_text:
            # Detect what language the original was
            detected_lang = _detect_language(text) or hint_lang or "en"
            return english_text, detected_lang
    except Exception as e:
        print(f"Auto-translate failed: {e}")

    # Step 2: Fallback — use hint language if provided
    if hint_lang and hint_lang != "en":
        try:
            english_text = GoogleTranslator(source=hint_lang, target="en").translate(text)
            if english_text:
                return english_text, hint_lang
        except Exception as e:
            print(f"Hint-based translate failed ({hint_lang}->en): {e}")

    # Step 3: If all else fails, assume it's English
    return text, hint_lang or "en"


def _detect_language(text: str) -> Optional[str]:
    """
    Detect language using Google Translate's detection.

    Returns:
        Language code (e.g. "ta", "en") or None
    """
    try:
        detected = GoogleTranslator(source="auto", target="en")
        # The detected language is available after translation
        result = detected.translate(text)
        # Try to get source language from the translator
        # deep-translator doesn't expose detected lang directly,
        # so we use a simple heuristic
        return _heuristic_detect(text)
    except Exception:
        return None


def _heuristic_detect(text: str) -> Optional[str]:
    """
    Quick heuristic language detection based on Unicode character ranges.
    Works well for Indian languages even in mixed-language text.
    """
    # Count characters in each script
    script_counts = {
        "ta": 0,  # Tamil: U+0B80-U+0BFF
        "hi": 0,  # Devanagari (Hindi/Marathi): U+0900-U+097F
        "te": 0,  # Telugu: U+0C00-U+0C7F
        "kn": 0,  # Kannada: U+0C80-U+0CFF
        "ml": 0,  # Malayalam: U+0D00-U+0D7F
        "bn": 0,  # Bengali: U+0980-U+09FF
        "gu": 0,  # Gujarati: U+0A80-U+0AFF
        "pa": 0,  # Gurmukhi (Punjabi): U+0A00-U+0A7F
    }
    latin_count = 0
    total = 0

    for ch in text:
        cp = ord(ch)
        if ch.isalpha():
            total += 1
            if cp < 128:
                latin_count += 1
            elif 0x0B80 <= cp <= 0x0BFF:
                script_counts["ta"] += 1
            elif 0x0900 <= cp <= 0x097F:
                script_counts["hi"] += 1
            elif 0x0C00 <= cp <= 0x0C7F:
                script_counts["te"] += 1
            elif 0x0C80 <= cp <= 0x0CFF:
                script_counts["kn"] += 1
            elif 0x0D00 <= cp <= 0x0D7F:
                script_counts["ml"] += 1
            elif 0x0980 <= cp <= 0x09FF:
                script_counts["bn"] += 1
            elif 0x0A80 <= cp <= 0x0AFF:
                script_counts["gu"] += 1
            elif 0x0A00 <= cp <= 0x0A7F:
                script_counts["pa"] += 1

    if total == 0:
        return "en"

    # Find dominant non-Latin script
    max_script = max(script_counts, key=script_counts.get)
    max_count = script_counts[max_script]

    # If any Indian script has characters, that's likely the language
    if max_count > 0:
        return max_script

    # All Latin characters = English
    if latin_count == total:
        return "en"

    return "en"


def is_supported(lang_code: str) -> bool:
    """Check if a language code is supported."""
    return lang_code in SUPPORTED_LANGUAGES


def get_supported_languages() -> dict:
    """Return all supported languages."""
    return SUPPORTED_LANGUAGES.copy()