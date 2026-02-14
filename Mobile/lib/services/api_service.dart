import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/api_models.dart';

class ApiService {
  // Use localhost for web/desktop, 10.0.2.2 for Android emulator
  static final String baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
  static const String mobileApiPath = '/api/mobile';
  
  final Dio _dio = Dio();
  
  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 120);
    
    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('API: $obj'),
    ));
  }

  // Get supported languages
  Future<LanguagesResponse> getSupportedLanguages() async {
    try {
      final response = await _dio.get('$mobileApiPath/languages');
      return LanguagesResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to get languages: $e');
    }
  }

  // Send text query
  Future<TextQueryResponse> sendTextQuery({
    required String text,
    required String language,
    int? userId,
    String? sessionId,
  }) async {
    try {
      final data = {
        'text': text,
        'lang': language,
        if (userId != null) 'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
      };

      final response = await _dio.post(
        '$mobileApiPath/text-query',
        data: data,
      );

      return TextQueryResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to send text query: $e');
    }
  }

  // Send voice query
  Future<VoiceQueryResponse> sendVoiceQuery({
    required String audioPath,
    required String language,
    int? userId,
    String? sessionId,
  }) async {
    try {
      MultipartFile audioFile;
      
      // On web, audioPath is a blob URL, we need to fetch it as bytes
      if (kIsWeb) {
        // Create a separate Dio instance without base URL for blob fetching
        final blobDio = Dio();
        
        // Fetch the blob from the URL
        final audioResponse = await blobDio.get(
          audioPath,
          options: Options(responseType: ResponseType.bytes),
        );
        
        audioFile = MultipartFile.fromBytes(
          audioResponse.data,
          filename: 'audio.wav',
        );
      } else {
        // On mobile, use fromFile
        audioFile = await MultipartFile.fromFile(
          audioPath,
          filename: 'audio.wav',
        );
      }

      final formData = FormData.fromMap({
        'file': audioFile,
        'lang': language,
        if (userId != null) 'user_id': userId,
        if (sessionId != null) 'session_id': sessionId,
      });

      final response = await _dio.post(
        '$mobileApiPath/voice-query',
        data: formData,
      );

      return VoiceQueryResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to send voice query: $e');
    }
  }

  // Get mobile health status
  Future<HealthResponse> getMobileHealth() async {
    try {
      final response = await _dio.get('$mobileApiPath/health-mobile');
      return HealthResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to get health status: $e');
    }
  }

  // Register user
  Future<UserResponse> registerUser({
    required String phoneNumber,
    required String name,
    required String language,
    String? location,
  }) async {
    try {
      final data = {
        'phone_number': phoneNumber,
        'name': name,
        'language': language,
        if (location != null) 'location': location,
      };

      final response = await _dio.post('/api/users/register', data: data);
      return UserResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to register user: $e');
    }
  }

  // Get user profile
  Future<UserResponse> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('/api/users/profile/$userId');
      return UserResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to get user profile: $e');
    }
  }

  // Submit feedback
  Future<void> submitFeedback({
    required int queryId,
    required int userId,
    required int rating,
    required bool helpful,
    String? comment,
  }) async {
    try {
      final data = {
        'query_id': queryId,
        'user_id': userId,
        'rating': rating,
        'helpful': helpful,
        if (comment != null) 'comment': comment,
      };

      await _dio.post('/api/users/feedback', data: data);
    } catch (e) {
      throw ApiException('Failed to submit feedback: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}