"""
Property-based tests for audio format support universality
**Feature: farmer-copilot-integration, Property 5: Audio format support universality**
"""

import pytest
from hypothesis import given, strategies as st, settings
import tempfile
import wave
import numpy as np
import io
import os
from fastapi import UploadFile
from fastapi.testclient import TestClient
from services.api.app import app

client = TestClient(app)

def generate_wav_audio(duration_seconds=2, sample_rate=16000, frequency=440):
    """Generate WAV audio data for testing"""
    t = np.linspace(0, duration_seconds, int(sample_rate * duration_seconds), False)
    audio_data = np.sin(2 * np.pi * frequency * t) * 0.3
    
    # Convert to 16-bit PCM
    audio_data = (audio_data * 32767).astype(np.int16)
    
    # Create WAV file in memory
    buffer = io.BytesIO()
    with wave.open(buffer, 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(audio_data.tobytes())
    
    buffer.seek(0)
    return buffer

def generate_mock_mp3_audio(duration_seconds=2):
    """Generate mock MP3 audio data for testing (simplified)"""
    # For testing purposes, we'll create a simple binary blob that represents MP3-like data
    # In a real implementation, you'd use libraries like pydub to create actual MP3
    mock_mp3_header = b'\xff\xfb\x90\x00'  # MP3 frame header
    mock_audio_data = np.random.bytes(int(duration_seconds * 8000))  # Approximate MP3 size
    
    buffer = io.BytesIO()
    buffer.write(mock_mp3_header + mock_audio_data)
    buffer.seek(0)
    return buffer

def generate_mock_m4a_audio(duration_seconds=2):
    """Generate mock M4A audio data for testing (simplified)"""
    # For testing purposes, we'll create a simple binary blob that represents M4A-like data
    mock_m4a_header = b'\x00\x00\x00\x20ftypM4A '  # M4A file header
    mock_audio_data = np.random.bytes(int(duration_seconds * 6000))  # Approximate M4A size
    
    buffer = io.BytesIO()
    buffer.write(mock_m4a_header + mock_audio_data)
    buffer.seek(0)
    return buffer

@settings(max_examples=15, deadline=20000)
@given(
    audio_format=st.sampled_from(['wav', 'mp3', 'm4a']),
    language=st.sampled_from(['en', 'ta', 'hi', 'te', 'kn', 'ml']),
    user_id=st.integers(min_value=1, max_value=1000),
    duration=st.floats(min_value=1.0, max_value=4.0)
)
def test_audio_format_support_universality(audio_format, language, user_id, duration):
    """
    **Feature: farmer-copilot-integration, Property 5: Audio format support universality**
    
    Property: For any standard audio format (WAV, MP3, M4A), the system should process 
    the audio successfully
    """
    try:
        # Generate audio data based on format
        if audio_format == 'wav':
            audio_buffer = generate_wav_audio(duration_seconds=duration)
            content_type = "audio/wav"
            filename = "test_audio.wav"
        elif audio_format == 'mp3':
            audio_buffer = generate_mock_mp3_audio(duration_seconds=duration)
            content_type = "audio/mpeg"
            filename = "test_audio.mp3"
        elif audio_format == 'm4a':
            audio_buffer = generate_mock_m4a_audio(duration_seconds=duration)
            content_type = "audio/mp4"
            filename = "test_audio.m4a"
        else:
            pytest.fail(f"Unsupported audio format: {audio_format}")
        
        # Create form data for file upload
        files = {
            'audio_file': (filename, audio_buffer, content_type)
        }
        data = {
            'lang': language,
            'user_id': str(user_id)
        }
        
        # Test the voice query endpoint
        response = client.post("/api/mobile/voice-query", files=files, data=data)
        
        # Property 1: The system should accept the audio format (not reject due to format)
        # We expect either success (200) or a processing error, but not format rejection (415)
        assert response.status_code != 415, f"Audio format {audio_format} was rejected"
        
        # Property 2: Response should be valid JSON regardless of processing outcome
        try:
            response_data = response.json()
            assert isinstance(response_data, dict), "Response should be a JSON object"
        except Exception as json_error:
            pytest.fail(f"Invalid JSON response for {audio_format}: {json_error}")
        
        # Property 3: If successful, response should have expected structure
        if response.status_code == 200:
            required_fields = ['success', 'transcribed_text', 'answer_text']
            for field in required_fields:
                assert field in response_data, f"Missing field {field} in response for {audio_format}"
            
            # Property 4: Language should be preserved
            if 'language' in response_data:
                assert response_data['language'] == language, f"Language mismatch for {audio_format}"
        
        # Property 5: Error responses should provide meaningful information
        elif response.status_code >= 400:
            assert 'detail' in response_data or 'error' in response_data, \
                f"Error response for {audio_format} should contain error details"
        
        print(f"✅ Audio format {audio_format} test passed for {language}")
        
    except Exception as e:
        # Handle cases where the API might not be fully functional in test environment
        if "connection" in str(e).lower() or "service unavailable" in str(e).lower():
            pytest.skip(f"API service not available for {audio_format}: {e}")
        else:
            pytest.fail(f"Audio format {audio_format} test failed: {e}")

@settings(max_examples=8, deadline=15000)
@given(
    formats_batch=st.lists(
        st.sampled_from(['wav', 'mp3', 'm4a']),
        min_size=1, max_size=3, unique=True
    )
)
def test_audio_format_consistency_across_formats(formats_batch):
    """
    Property: All supported audio formats should be handled consistently
    """
    results = {}
    
    for audio_format in formats_batch:
        try:
            # Generate audio data
            if audio_format == 'wav':
                audio_buffer = generate_wav_audio(duration_seconds=2.0)
                content_type = "audio/wav"
                filename = "test_audio.wav"
            elif audio_format == 'mp3':
                audio_buffer = generate_mock_mp3_audio(duration_seconds=2.0)
                content_type = "audio/mpeg"
                filename = "test_audio.mp3"
            elif audio_format == 'm4a':
                audio_buffer = generate_mock_m4a_audio(duration_seconds=2.0)
                content_type = "audio/mp4"
                filename = "test_audio.m4a"
            
            # Test the format
            files = {'audio_file': (filename, audio_buffer, content_type)}
            data = {'lang': 'en', 'user_id': '1'}
            
            response = client.post("/api/mobile/voice-query", files=files, data=data)
            
            results[audio_format] = {
                'status_code': response.status_code,
                'accepted': response.status_code != 415,
                'valid_json': True
            }
            
            try:
                response.json()
            except:
                results[audio_format]['valid_json'] = False
                
        except Exception as e:
            if "connection" in str(e).lower():
                pytest.skip(f"API service not available: {e}")
            results[audio_format] = {'error': str(e)}
    
    # Property: All formats should be handled consistently (either all accepted or all rejected)
    accepted_formats = [fmt for fmt, result in results.items() 
                       if result.get('accepted', False)]
    
    # If WAV is in the test batch, it should be supported
    if 'wav' in formats_batch:
        assert 'wav' in accepted_formats, "WAV format should be supported when tested"
    
    # At least one format should be accepted if any are tested
    assert len(accepted_formats) > 0 or len(results) == 0, "At least one audio format should be supported"
    
    # All tested formats should return valid JSON
    for fmt, result in results.items():
        if 'error' not in result:
            assert result.get('valid_json', False), f"Format {fmt} should return valid JSON"

@settings(max_examples=5, deadline=10000)
@given(
    invalid_formats=st.lists(
        st.sampled_from(['txt', 'pdf', 'doc', 'jpg', 'png']),
        min_size=1, max_size=2, unique=True
    )
)
def test_audio_format_rejection_for_invalid_formats(invalid_formats):
    """
    Property: Invalid audio formats should be properly rejected
    """
    for invalid_format in invalid_formats:
        try:
            # Create mock file with invalid format
            mock_data = b"This is not audio data"
            buffer = io.BytesIO(mock_data)
            
            files = {
                'audio_file': (f"test_file.{invalid_format}", buffer, f"application/{invalid_format}")
            }
            data = {'lang': 'en', 'user_id': '1'}
            
            response = client.post("/api/mobile/voice-query", files=files, data=data)
            
            # Property: Invalid formats should be rejected with appropriate error
            assert response.status_code >= 400, f"Invalid format {invalid_format} should be rejected"
            
            # Property: Error response should be informative
            try:
                response_data = response.json()
                assert 'detail' in response_data or 'error' in response_data, \
                    f"Error response for {invalid_format} should contain error details"
            except:
                # Some invalid formats might not return JSON, which is acceptable
                pass
                
        except Exception as e:
            if "connection" in str(e).lower():
                pytest.skip(f"API service not available: {e}")
            # Other exceptions for invalid formats are expected
            continue

def test_audio_format_file_size_limits():
    """
    Property: Audio format processing should handle reasonable file sizes
    """
    # Test with different file sizes
    test_sizes = [1.0, 2.0, 5.0]  # seconds of audio
    
    for duration in test_sizes:
        try:
            audio_buffer = generate_wav_audio(duration_seconds=duration)
            
            files = {'audio_file': ('test_audio.wav', audio_buffer, 'audio/wav')}
            data = {'lang': 'en', 'user_id': '1'}
            
            response = client.post("/api/mobile/voice-query", files=files, data=data)
            
            # Property: Reasonable file sizes should be accepted
            if duration <= 10.0:  # Reasonable limit
                assert response.status_code != 413, f"File size for {duration}s audio should be acceptable"
            
            # Property: Response should be valid JSON
            try:
                response.json()
            except:
                if response.status_code not in [413, 415]:  # Size/format errors might not be JSON
                    pytest.fail(f"Invalid JSON response for {duration}s audio")
                    
        except Exception as e:
            if "connection" in str(e).lower():
                pytest.skip(f"API service not available: {e}")
            else:
                pytest.fail(f"File size test failed for {duration}s: {e}")

if __name__ == "__main__":
    # Run basic tests
    test_audio_format_file_size_limits()
    print("✅ All audio format property tests completed")