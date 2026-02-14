class Language {
  final String code;
  final String name;
  final String native;

  Language({
    required this.code,
    required this.name,
    required this.native,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'],
      name: json['name'],
      native: json['native'],
    );
  }
}

class LanguagesResponse {
  final List<Language> languages;

  LanguagesResponse({required this.languages});

  factory LanguagesResponse.fromJson(Map<String, dynamic> json) {
    return LanguagesResponse(
      languages: (json['languages'] as List)
          .map((lang) => Language.fromJson(lang))
          .toList(),
    );
  }
}

class TextQueryResponse {
  final bool success;
  final String query;
  final String language;
  final String answerText;
  final String? audioUrl;
  final String? intent;
  final Map<String, dynamic>? entities;
  final List<Source>? sources;
  final String? sessionId;
  final int? queryId;
  final int? userId;
  final double? processingTime;

  TextQueryResponse({
    required this.success,
    required this.query,
    required this.language,
    required this.answerText,
    this.audioUrl,
    this.intent,
    this.entities,
    this.sources,
    this.sessionId,
    this.queryId,
    this.userId,
    this.processingTime,
  });

  factory TextQueryResponse.fromJson(Map<String, dynamic> json) {
    // Handle intent - can be string, map, or list
    String? intentValue;
    final intentData = json['intent'];
    if (intentData is String) {
      intentValue = intentData;
    } else if (intentData is Map) {
      intentValue = intentData['intent']?.toString() ?? intentData.toString();
    } else if (intentData is List && intentData.isNotEmpty) {
      intentValue = intentData[0].toString();
    }
    
    return TextQueryResponse(
      success: json['success'],
      query: json['query'],
      language: json['language'],
      answerText: json['answer_text'],
      audioUrl: json['audio_url'],
      intent: intentValue,
      entities: json['entities'],
      sources: json['sources'] != null
          ? (json['sources'] as List)
              .map((source) => Source.fromJson(source))
              .toList()
          : null,
      sessionId: json['session_id'],
      queryId: json['query_id'],
      userId: json['user_id'],
      processingTime: json['processing_time']?.toDouble(),
    );
  }
}

class VoiceQueryResponse {
  final bool success;
  final String transcribedText;
  final String detectedLanguage;
  final String answerText;
  final String? audioUrl;
  final String? intent;
  final Map<String, dynamic>? entities;
  final int? retrievedSources;
  final String? sessionId;
  final int? queryId;
  final int? userId;
  final double? processingTime;

  VoiceQueryResponse({
    required this.success,
    required this.transcribedText,
    required this.detectedLanguage,
    required this.answerText,
    this.audioUrl,
    this.intent,
    this.entities,
    this.retrievedSources,
    this.sessionId,
    this.queryId,
    this.userId,
    this.processingTime,
  });

  factory VoiceQueryResponse.fromJson(Map<String, dynamic> json) {
    // Handle intent - can be string, map, or list
    String? intentValue;
    final intentData = json['intent'];
    if (intentData is String) {
      intentValue = intentData;
    } else if (intentData is Map) {
      intentValue = intentData['intent']?.toString() ?? intentData.toString();
    } else if (intentData is List && intentData.isNotEmpty) {
      intentValue = intentData[0].toString();
    }
    
    return VoiceQueryResponse(
      success: json['success'],
      transcribedText: json['transcribed_text'],
      detectedLanguage: json['detected_language'] ?? json['language'],
      answerText: json['answer_text'],
      audioUrl: json['audio_url'],
      intent: intentValue,
      entities: json['entities'],
      retrievedSources: json['retrieved_sources'],
      sessionId: json['session_id'],
      queryId: json['query_id'],
      userId: json['user_id'],
      processingTime: json['processing_time']?.toDouble(),
    );
  }
}

class Source {
  final String text;
  final String source;

  Source({required this.text, required this.source});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      text: json['text'],
      source: json['source'],
    );
  }
}

class HealthResponse {
  final String status;
  final Map<String, dynamic> services;
  final String version;
  final List<String> supportedFeatures;

  HealthResponse({
    required this.status,
    required this.services,
    required this.version,
    required this.supportedFeatures,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'],
      services: json['services'],
      version: json['version'],
      supportedFeatures: List<String>.from(json['supported_features']),
    );
  }
}

class UserResponse {
  final bool success;
  final User user;

  UserResponse({required this.success, required this.user});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      success: json['success'],
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final int id;
  final String phoneNumber;
  final String name;
  final String language;
  final String? location;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.language,
    this.location,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'],
      name: json['name'],
      language: json['language'],
      location: json['location'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class QueryHistory {
  final int id;
  final String originalText;
  final String responseText;
  final String language;
  final String intent;
  final double processingTime;
  final DateTime createdAt;

  QueryHistory({
    required this.id,
    required this.originalText,
    required this.responseText,
    required this.language,
    required this.intent,
    required this.processingTime,
    required this.createdAt,
  });

  factory QueryHistory.fromJson(Map<String, dynamic> json) {
    return QueryHistory(
      id: json['id'],
      originalText: json['original_text'],
      responseText: json['response_text'],
      language: json['language'],
      intent: json['intent'],
      processingTime: json['processing_time']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}