import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

enum RecordingState { idle, recording, processing }

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  bool get isRecording => _state == RecordingState.recording;
  bool get isProcessing => _state == RecordingState.processing;
  bool get isPlaying => _isPlaying;
  bool _isPlaying = false;

  /// Request microphone permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return await _recorder.hasPermission();
    }
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (!await requestPermissions()) {
      throw Exception('Microphone permission denied');
    }

    final fileName = kIsWeb
        ? ''
        : 'voice_query_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 128000,
        numChannels: 1,
      ),
      path: fileName,
    );

    _state = RecordingState.recording;
  }

  /// Stop recording and return the audio file path
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _state = RecordingState.processing;
    return path;
  }

  /// Set state to idle
  void setIdle() {
    _state = RecordingState.idle;
  }

  /// Play audio from URL
  Future<void> playAudio(String url) async {
    try {
      _isPlaying = true;
      await _player.play(UrlSource(url));
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
      rethrow;
    }
  }

  /// Stop playing audio
  Future<void> stopAudio() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// Get current audio amplitude (for waveform visualization)
  Future<double> getAmplitude() async {
    try {
      final amp = await _recorder.getAmplitude();
      // Normalize to 0.0 - 1.0 range
      final normalized = (amp.current + 40) / 40; // dB range roughly -40 to 0
      return normalized.clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
