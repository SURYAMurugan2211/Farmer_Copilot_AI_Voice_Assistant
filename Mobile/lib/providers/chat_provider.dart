import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../providers/app_providers.dart';
import '../services/audio_service.dart';

// ─── Audio Service Provider ───
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

// ─── Chat Messages Provider ───
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(ref.read(apiServiceProvider));
});

// ─── Recording State Provider ───
final recordingStateProvider = StateProvider<RecordingState>((ref) => RecordingState.idle);

// ─── Is AI Typing Provider ───
final isAiTypingProvider = StateProvider<bool>((ref) => false);

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiService _apiService;

  ChatMessagesNotifier(this._apiService) : super([]);

  /// Add a welcome message on first load
  void addWelcome() {
    if (state.isEmpty) {
      state = [
        ChatMessage(
          text: 'Vanakkam! 🌾 I\'m your AI farming assistant. Ask me anything about crops, pests, soil, weather, or farming techniques — in any language!',
          isUser: false,
          intent: 'welcome',
        ),
      ];
    }
  }

  /// Send a text query
  Future<void> sendTextQuery({
    required String text,
    required String language,
    int? userId,
    String? sessionId,
  }) async {
    // Add user message
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      language: language,
      type: MessageType.text,
    );
    state = [...state, userMsg];

    // Add loading indicator
    final loadingMsg = ChatMessage.loading();
    state = [...state, loadingMsg];

    try {
      final response = await _apiService.sendTextQuery(
        text: text,
        language: language,
        userId: userId,
        sessionId: sessionId,
      );

      // Replace loading with actual response
      final aiMsg = ChatMessage(
        text: response.answerText,
        isUser: false,
        audioUrl: response.audioUrl,
        intent: response.intent,
        language: response.language,
        processingTime: response.processingTime,
        sources: response.sources
            ?.map((s) => {'text': s.text, 'source': s.source})
            .toList(),
        entities: response.entities,
        queryId: response.queryId,
        type: MessageType.text,
      );

      state = [...state.where((m) => m.id != loadingMsg.id), aiMsg];
    } catch (e) {
      final errorMsg = ChatMessage(
        text: 'Sorry, I couldn\'t process your question. Please try again.',
        isUser: false,
        status: MessageStatus.error,
      );
      state = [...state.where((m) => m.id != loadingMsg.id), errorMsg];
    }
  }

  /// Send a voice query
  Future<void> sendVoiceQuery({
    required String audioPath,
    required String language,
    int? userId,
    String? sessionId,
  }) async {
    // Add user message placeholder
    final userMsg = ChatMessage(
      text: '🎤 Voice message',
      isUser: true,
      language: language,
      type: MessageType.voice,
    );
    state = [...state, userMsg];

    // Add loading indicator
    final loadingMsg = ChatMessage.loading();
    state = [...state, loadingMsg];

    try {
      final response = await _apiService.sendVoiceQuery(
        audioPath: audioPath,
        language: language,
        userId: userId,
        sessionId: sessionId,
      );

      // Update user message with transcribed text
      final updatedUserMsg = userMsg.copyWith(
        text: response.transcribedText,
        transcribedText: response.transcribedText,
      );

      final aiMsg = ChatMessage(
        text: response.answerText,
        isUser: false,
        audioUrl: response.audioUrl,
        intent: response.intent,
        language: language,
        detectedLanguage: response.detectedLanguage,
        processingTime: response.processingTime,
        queryId: response.queryId,
        type: MessageType.voice,
      );

      state = [
        ...state
            .where((m) => m.id != loadingMsg.id && m.id != userMsg.id),
        updatedUserMsg,
        aiMsg,
      ];
    } catch (e) {
      final errorMsg = ChatMessage(
        text: 'Sorry, I couldn\'t process your voice message. Please try again.',
        isUser: false,
        status: MessageStatus.error,
      );
      state = [...state.where((m) => m.id != loadingMsg.id), errorMsg];
    }
  }

  /// Clear all messages
  void clearChat() {
    state = [];
    addWelcome();
  }
}
