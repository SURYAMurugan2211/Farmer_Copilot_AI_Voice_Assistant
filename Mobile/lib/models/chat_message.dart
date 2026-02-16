import 'package:uuid/uuid.dart';

enum MessageType { text, voice }
enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? audioUrl;
  final String? inputAudioUrl;
  final String? intent;
  final String? language;
  final String? detectedLanguage;
  final double? processingTime;
  final bool isLoading;
  final String? transcribedText;
  final MessageType type;
  final MessageStatus status;
  final List<Map<String, String>>? sources;
  final Map<String, dynamic>? entities;
  final int? queryId;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.audioUrl,
    this.inputAudioUrl,
    this.intent,
    this.language,
    this.detectedLanguage,
    this.processingTime,
    this.isLoading = false,
    this.transcribedText,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.sources,
    this.entities,
    this.queryId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? audioUrl,
    String? inputAudioUrl,
    String? intent,
    String? language,
    String? detectedLanguage,
    double? processingTime,
    bool? isLoading,
    String? transcribedText,
    MessageType? type,
    MessageStatus? status,
    List<Map<String, String>>? sources,
    Map<String, dynamic>? entities,
    int? queryId,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp,
      audioUrl: audioUrl ?? this.audioUrl,
      inputAudioUrl: inputAudioUrl ?? this.inputAudioUrl,
      intent: intent ?? this.intent,
      language: language ?? this.language,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      processingTime: processingTime ?? this.processingTime,
      isLoading: isLoading ?? this.isLoading,
      transcribedText: transcribedText ?? this.transcribedText,
      type: type ?? this.type,
      status: status ?? this.status,
      sources: sources ?? this.sources,
      entities: entities ?? this.entities,
      queryId: queryId ?? this.queryId,
    );
  }

  /// Create a loading placeholder message
  static ChatMessage loading() {
    return ChatMessage(
      text: '',
      isUser: false,
      isLoading: true,
    );
  }

  /// Format processing time nicely
  String get formattedProcessingTime {
    if (processingTime == null) return '';
    if (processingTime! < 1) return '${(processingTime! * 1000).toInt()}ms';
    return '${processingTime!.toStringAsFixed(1)}s';
  }
}
