import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class VoiceInputWidget extends StatefulWidget {
  final String language;
  final Function(String audioPath) onVoiceQuery;

  const VoiceInputWidget({
    super.key,
    required this.language,
    required this.onVoiceQuery,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<void> _startRecording() async {
    // On web, we don't need to request permissions the same way
    if (!kIsWeb) {
      if (!await _requestPermissions()) {
        _showPermissionDialog();
        return;
      }
    }

    try {
      // Check if recording is supported
      if (!await _audioRecorder.hasPermission()) {
        _showErrorDialog(
          'Microphone permission denied. Please allow microphone access in your browser settings.'
        );
        return;
      }

      // Start recording
      // On web, the path is not used but required by the API
      // The package will return a blob URL when we stop recording
      final fileName = kIsWeb 
          ? '' // Empty path for web - will get blob URL on stop
          : 'voice_query_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: fileName,
      );

      setState(() {
        _isRecording = true;
      });

      _animationController.repeat(reverse: true);
    } catch (e) {
      _showErrorDialog('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _animationController.stop();
      _animationController.reset();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null && path.isNotEmpty) {
        widget.onVoiceQuery(path);
      } else {
        _showErrorDialog('Recording failed. Please try again.');
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _showErrorDialog('Failed to stop recording: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission'),
        content: const Text(
          'Microphone permission is required to record voice queries. '
          'Please grant permission in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
            _isRecording
                ? 'Recording... Tap to stop'
                : _isProcessing
                    ? 'Processing...'
                    : 'Tap to start recording',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          if (_isProcessing)
            const SpinKitWave(
              color: Color(0xFF2E7D32),
              size: 50.0,
            )
          else
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _scaleAnimation.value : 1.0,
                  child: GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? Colors.red.shade400
                            : const Color(0xFF2E7D32),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? Colors.red.shade400
                                    : const Color(0xFF2E7D32))
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: _isRecording ? 10 : 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          
          const SizedBox(height: 24),
          
          Text(
            'Language: ${_getLanguageName(widget.language)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.web,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Web Voice Recording',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click the microphone and allow browser access.\n'
                    'Your browser will ask for microphone permission.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tips for better voice recognition:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Speak clearly and at normal pace\n'
                    '• Minimize background noise\n'
                    '• Hold phone close to your mouth\n'
                    '• Ask specific farming questions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ta':
        return 'Tamil';
      case 'hi':
        return 'Hindi';
      case 'te':
        return 'Telugu';
      case 'kn':
        return 'Kannada';
      case 'ml':
        return 'Malayalam';
      default:
        return code.toUpperCase();
    }
  }
}