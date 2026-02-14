import os
import whisper
from pydub import AudioSegment
import tempfile

# Add ffmpeg to PATH if it's in WinGet Links directory
ffmpeg_path = os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Microsoft', 'WinGet', 'Links')
if os.path.exists(ffmpeg_path) and ffmpeg_path not in os.environ.get('PATH', ''):
    os.environ['PATH'] = ffmpeg_path + os.pathsep + os.environ.get('PATH', '')
    print(f"✅ Added ffmpeg to PATH: {ffmpeg_path}")

# Load Whisper model (lazy loading)
model = None

def convert_audio_for_whisper(audio_path: str) -> str:
    """
    Convert audio to format that Whisper can process reliably
    Returns path to converted audio file
    """
    try:
        print(f"🔄 Converting audio format for Whisper compatibility...")
        
        # Load audio file
        audio = AudioSegment.from_file(audio_path)
        
        # Convert to mono, 16kHz, 16-bit PCM WAV (Whisper's preferred format)
        audio = audio.set_channels(1)  # Mono
        audio = audio.set_frame_rate(16000)  # 16kHz
        audio = audio.set_sample_width(2)  # 16-bit
        
        # Create a temporary file for the converted audio
        converted_path = audio_path.replace('.wav', '_converted.wav')
        audio.export(converted_path, format='wav', parameters=["-acodec", "pcm_s16le"])
        
        print(f"✅ Audio converted successfully")
        print(f"   Original: {os.path.getsize(audio_path)} bytes")
        print(f"   Converted: {os.path.getsize(converted_path)} bytes")
        print(f"   Duration: {len(audio)/1000:.2f} seconds")
        
        return converted_path
        
    except Exception as e:
        print(f"⚠️ Audio conversion failed: {e}")
        print(f"   Will try original file...")
        return audio_path

def _load_whisper():
    global model
    if model is None:
        try:
            model_size = os.getenv("WHISPER_MODEL", "base")
            print(f"⏳ Loading Whisper model ({model_size})...")
            model = whisper.load_model(model_size)
            print("✅ Whisper model loaded!")
        except Exception as e:
            print(f"Warning: Could not load Whisper model: {e}")
            return False
    return True

def transcribe(audio_path: str, language: str = None):
    if not _load_whisper():
        return {
            "text": "Audio transcription service is not available", 
            "lang": "en"
        }
    
    converted_path = None
    
    try:
        # Verify file exists before transcribing
        if not os.path.exists(audio_path):
            print(f"❌ Audio file not found: {audio_path}")
            return {
                "text": f"Audio file not found: {audio_path}", 
                "lang": "en"
            }
        
        file_size = os.path.getsize(audio_path)
        print(f"🎤 Transcribing: {audio_path} ({file_size} bytes)")
        
        # Check if file is too small (likely empty or corrupted)
        if file_size < 1000:  # Less than 1KB is suspicious
            print(f"⚠️ Warning: Audio file is very small ({file_size} bytes), may be empty")
        
        # Convert audio to Whisper-friendly format
        converted_path = convert_audio_for_whisper(audio_path)
        
        # Transcribe with verbose output for debugging
        result = model.transcribe(
            converted_path,
            language=language,  # Use provided language or auto-detect
            verbose=False,  # Disable verbose to reduce noise
            fp16=False      # Use FP32 for CPU
        )
        
        transcribed_text = result["text"].strip()
        detected_lang = result.get("language", "en")
        
        print(f"✅ Transcription successful: '{transcribed_text}'")
        print(f"🌍 Detected language: {detected_lang}")
        
        # Clean up temporary files
        try:
            # If transcription is empty, keep the file for debugging
            if not transcribed_text or len(transcribed_text) == 0:
                print(f"⚠️ EMPTY TRANSCRIPTION! Keeping files for debugging:")
                print(f"   Original: {audio_path}")
                if converted_path and converted_path != audio_path:
                    print(f"   Converted: {converted_path}")
                print(f"📊 Audio info - Size: {file_size} bytes, Detected lang: {detected_lang}")
            else:
                # Clean up temporary files only if transcription succeeded
                if os.path.exists(audio_path):
                    os.remove(audio_path)
                if converted_path and converted_path != audio_path and os.path.exists(converted_path):
                    os.remove(converted_path)
                print(f"🗑️ Cleaned up temp files")
        except Exception as cleanup_error:
            print(f"Warning: Could not delete temp files: {cleanup_error}")
        
        return {
            "text": transcribed_text,
            "lang": detected_lang
        }
    except Exception as e:
        print(f"❌ Error transcribing audio: {e}")
        import traceback
        traceback.print_exc()
        
        # Clean up on error
        try:
            if os.path.exists(audio_path):
                os.remove(audio_path)
            if converted_path and converted_path != audio_path and os.path.exists(converted_path):
                os.remove(converted_path)
        except:
            pass
            
        return {
            "text": f"Error transcribing audio: {str(e)}", 
            "lang": "en"
        }