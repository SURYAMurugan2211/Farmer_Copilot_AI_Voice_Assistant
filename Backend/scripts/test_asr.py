
import os
import sys

# Add project root to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from services.asr.asr_service import transcribe

def test_asr():
    print("🎤 Farmer Copilot - ASR Test Utility")
    print("====================================")
    
    while True:
        audio_path = input("\n📝 Enter path to audio file (or 'q' to quit): ").strip()
        
        if audio_path.lower() == 'q':
            break
            
        # Remove quotes if user copied path with quotes
        audio_path = audio_path.strip('"').strip("'")
        
        # Remove quotes if user copied path with quotes
        audio_path = audio_path.strip('"').strip("'")
        
        if not os.path.exists(audio_path):
            print(f"❌ File not found: {audio_path}")
            continue
            
        lang_input = input("🌍 Enter language code (en, ta, hi, etc.) or press Enter for auto-detect: ").strip()
        lang_code = lang_input if lang_input else None
            
        print(f"\nProcessing: {audio_path} (Lang: {lang_code or 'Auto'})...")
        try:
            result = transcribe(audio_path, language=lang_code)
            print("\n---------- Result ----------")
            print(f"Text: {result.get('text')}")
            print(f"Lang: {result.get('lang')}")
            print("----------------------------")
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_asr()
