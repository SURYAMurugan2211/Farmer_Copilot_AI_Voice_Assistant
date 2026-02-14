"""
Full Pipeline + DB Storage Test — verifies all data is saved correctly.
"""
import os, sys, warnings
warnings.filterwarnings("ignore")
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from dotenv import load_dotenv
load_dotenv()

output_path = os.path.join(os.path.dirname(__file__), "pipeline_results.txt")

import io
out = io.StringIO()

def log(msg):
    out.write(msg + "\n")
    print(msg)

log("=" * 60)
log("FARMER COPILOT - FULL PIPELINE + DB STORAGE TEST")
log("=" * 60)

# ── Test 1: DB Connection ──
log("\n[TEST 1] DATABASE CONNECTION")
log("-" * 40)
try:
    from services.db.user_service import UserService, QueryService
    from services.db.session import engine
    from sqlalchemy import inspect

    inspector = inspect(engine)
    tables = inspector.get_table_names()
    log(f"  Tables: {tables}")

    query_cols = [c["name"] for c in inspector.get_columns("queries")]
    log(f"  Query columns: {query_cols}")

    assert "input_audio_url" in query_cols, "Missing input_audio_url!"
    assert "response_audio_url" in query_cols, "Missing response_audio_url!"
    assert "query_type" in query_cols, "Missing query_type!"
    log("  RESULT: PASS")
except Exception as e:
    log(f"  RESULT: FAIL - {e}")

# ── Test 2: Create User + Text Query → Save to DB ──
log("\n[TEST 2] TEXT QUERY → DB STORAGE")
log("-" * 40)
try:
    from services.translate.translator import translate, auto_translate_to_english
    from services.nlu.nlu import detect_intent, extract_entities
    from services.rag.retriever import semantic_search
    from services.rag.groq_composer import compose
    from services.tts.tts_service import synthesize_tts

    # Create test user
    user = UserService.create_or_get_user(
        phone_number="9876543210",
        name="Test Farmer",
        language="ta",
        location="Tamil Nadu"
    )
    log(f"  User: id={user.id}, name={user.name}, lang={user.language}")

    # Simulate text query pipeline
    user_text = "நெல் பயிரில் பூச்சி கட்டுப்பாடு எப்படி?"
    log(f"  Input: {user_text}")

    query_en, detected = auto_translate_to_english(user_text, hint_lang="ta")
    log(f"  Translated: {query_en} (lang={detected})")

    intent = detect_intent(query_en)
    entities = extract_entities(query_en)

    retrieved = semantic_search(query_en, k=3)
    answer_en = compose(query_en, retrieved)

    answer_ta = translate(answer_en, "en", "ta")
    audio_url = synthesize_tts(answer_ta, lang="ta")
    response_audio_url = f"http://localhost:8000{audio_url}"

    # Save to DB with ALL fields
    saved = QueryService.save_query(
        user_id=user.id,
        original_text=user_text,
        translated_text=query_en,
        intent=intent.get("intent", "unknown"),
        confidence=intent.get("confidence", 0.0),
        response_text=answer_ta,
        response_text_en=answer_en,
        input_audio_url=None,  # Text query, no audio input
        response_audio_url=response_audio_url,
        language="ta",
        detected_language=detected,
        processing_time=3.5,
        source_count=len(retrieved),
        query_type="text",
    )
    log(f"  Saved query: id={saved.id}")
    log(f"    query_type={saved.query_type}")
    log(f"    detected_language={saved.detected_language}")
    log(f"    source_count={saved.source_count}")
    log(f"    response_audio_url={saved.response_audio_url}")
    log(f"    response_text (first 80): {saved.response_text[:80]}...")
    log(f"    response_text_en (first 80): {saved.response_text_en[:80]}...")
    log("  RESULT: PASS")
except Exception as e:
    log(f"  RESULT: FAIL - {e}")
    import traceback
    traceback.print_exc()

# ── Test 3: Simulate Voice Query → DB Storage ──
log("\n[TEST 3] VOICE QUERY SIMULATION → DB STORAGE")
log("-" * 40)
try:
    import hashlib
    # Create a fake audio file to simulate voice input
    fake_audio_dir = os.path.abspath("storage/voice_inputs")
    os.makedirs(fake_audio_dir, exist_ok=True)
    fake_audio_path = f"/voice_inputs/test_{hashlib.md5(b'test').hexdigest()}.wav"
    # Write a dummy file
    full_path = os.path.join(os.path.abspath("storage"), fake_audio_path.lstrip("/"))
    with open(full_path, "wb") as f:
        f.write(b"RIFF" + b"\x00" * 100)  # Fake WAV header

    # Simulate voice query
    user_text_hi = "मेरे गेहूं में बीमारी आ गई है कैसे पहचानें?"
    query_en, detected = auto_translate_to_english(user_text_hi, hint_lang="hi")
    intent = detect_intent(query_en)
    retrieved = semantic_search(query_en, k=3)
    answer_en = compose(query_en, retrieved)
    answer_hi = translate(answer_en, "en", "hi")
    tts_url = synthesize_tts(answer_hi, lang="hi")
    response_audio_url = f"http://localhost:8000{tts_url}"

    saved = QueryService.save_query(
        user_id=user.id,
        original_text=user_text_hi,
        translated_text=query_en,
        intent=intent.get("intent", "unknown"),
        confidence=intent.get("confidence", 0.0),
        response_text=answer_hi,
        response_text_en=answer_en,
        input_audio_url=fake_audio_path,
        response_audio_url=response_audio_url,
        language="hi",
        detected_language=detected,
        processing_time=5.2,
        source_count=len(retrieved),
        query_type="voice",
    )
    log(f"  Saved voice query: id={saved.id}")
    log(f"    query_type={saved.query_type}")
    log(f"    input_audio_url={saved.input_audio_url}")
    log(f"    response_audio_url={saved.response_audio_url}")
    log(f"    detected_language={saved.detected_language}")
    log("  RESULT: PASS")
except Exception as e:
    log(f"  RESULT: FAIL - {e}")
    import traceback
    traceback.print_exc()

# ── Test 4: Conversation History ──
log("\n[TEST 4] CONVERSATION HISTORY")
log("-" * 40)
try:
    history = QueryService.get_conversation_history(user.id, limit=10)
    log(f"  History entries: {len(history)}")
    for entry in history[-3:]:
        log(f"    [{entry['query_type']}] {entry['original_text'][:50]}...")
        log(f"      audio_in={entry.get('input_audio_url', 'N/A')}")
        log(f"      audio_out={entry.get('response_audio_url', 'N/A')[:60]}...")
    log("  RESULT: PASS")
except Exception as e:
    log(f"  RESULT: FAIL - {e}")

# ── Test 5: User Stats ──
log("\n[TEST 5] USER STATS")
log("-" * 40)
try:
    stats = QueryService.get_user_stats(user.id)
    log(f"  {stats}")
    log("  RESULT: PASS")
except Exception as e:
    log(f"  RESULT: FAIL - {e}")

log("\n" + "=" * 60)
log("ALL TESTS COMPLETE")
log("=" * 60)

with open(output_path, "w", encoding="utf-8") as f:
    f.write(out.getvalue())

print(f"\nResults saved to: {output_path}")
