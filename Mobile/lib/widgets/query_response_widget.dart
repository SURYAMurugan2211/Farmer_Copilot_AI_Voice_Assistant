import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/api_models.dart' as api;

class QueryResponseWidget extends ConsumerStatefulWidget {
  final AsyncValue<dynamic> queryState;

  const QueryResponseWidget({
    super.key,
    required this.queryState,
  });

  @override
  ConsumerState<QueryResponseWidget> createState() => _QueryResponseWidgetState();
}

class _QueryResponseWidgetState extends ConsumerState<QueryResponseWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      setState(() {
        _isPlayingAudio = true;
      });

      await _audioPlayer.play(UrlSource(audioUrl));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlayingAudio = false;
        });
      });
    } catch (e) {
      setState(() {
        _isPlayingAudio = false;
      });
      _showErrorDialog('Failed to play audio: $e');
    }
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
      padding: const EdgeInsets.all(16),
      child: widget.queryState.when(
        data: (data) {
          if (data == null) {
            return _buildEmptyState();
          }
          
          if (data is api.TextQueryResponse) {
            return _buildTextResponse(data);
          } else if (data is api.VoiceQueryResponse) {
            return _buildVoiceResponse(data);
          }
          
          return _buildEmptyState();
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about farming!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Use voice or text to get expert agricultural advice',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitThreeBounce(
            color: Color(0xFF2E7D32),
            size: 30.0,
          ),
          const SizedBox(height: 16),
          Text(
            'Processing your query...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextResponse(api.TextQueryResponse response) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Your Question:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.query,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Response Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.agriculture, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Farmer Copilot:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const Spacer(),
                    if (response.audioUrl != null)
                      IconButton(
                        onPressed: _isPlayingAudio
                            ? null
                            : () => _playAudio(response.audioUrl!),
                        icon: Icon(
                          _isPlayingAudio ? Icons.volume_up : Icons.volume_up_outlined,
                          color: Colors.green.shade600,
                        ),
                        tooltip: 'Play Audio Response',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.answerText,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Metadata
          _buildMetadata(
            language: response.language,
            processingTime: response.processingTime,
            intent: response.intent,
          ),
          
          // Sources
          if (response.sources != null && response.sources!.isNotEmpty)
            _buildSources(response.sources!),
        ],
      ),
    );
  }

  Widget _buildVoiceResponse(api.VoiceQueryResponse response) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transcription Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: Colors.purple.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'What you said:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.transcribedText,
                  style: TextStyle(color: Colors.purple.shade700),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Response Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.agriculture, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Farmer Copilot:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const Spacer(),
                    if (response.audioUrl != null)
                      IconButton(
                        onPressed: _isPlayingAudio
                            ? null
                            : () => _playAudio(response.audioUrl!),
                        icon: Icon(
                          _isPlayingAudio ? Icons.volume_up : Icons.volume_up_outlined,
                          color: Colors.green.shade600,
                        ),
                        tooltip: 'Play Audio Response',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  response.answerText,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Metadata
          _buildMetadata(
            language: response.detectedLanguage,
            processingTime: response.processingTime,
            intent: response.intent,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata({
    required String language,
    double? processingTime,
    String? intent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Icon(Icons.language, size: 16, color: Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                language.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (processingTime != null)
            Column(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(height: 4),
                Text(
                  '${processingTime.toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          if (intent != null)
            Column(
              children: [
                Icon(Icons.psychology, size: 16, color: Colors.grey[600]),
                const SizedBox(height: 4),
                Text(
                  intent,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSources(List<api.Source> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Sources:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sources.map((source) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.source,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                source.text,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}