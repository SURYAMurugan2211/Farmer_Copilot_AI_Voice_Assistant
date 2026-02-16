// import 'dart:io'; // Unused import removed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Shared Preferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Current User Provider
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<User?>>((ref) {
  return CurrentUserNotifier(ref.read(apiServiceProvider));
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;

  CurrentUserNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> registerUser({
    required String phoneNumber,
    required String name,
    required String language,
    String? location,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.registerUser(
        phoneNumber: phoneNumber,
        name: name,
        language: language,
        location: location,
      );
      state = AsyncValue.data(response.user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadUser(int userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.getUserProfile(userId);
      state = AsyncValue.data(response.user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }


  Future<void> loginAsGuest() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        deviceId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_id', deviceId);
      }
      
      // Auto-register guest
      // Using the device ID as phone number for uniqueness
      final response = await _apiService.registerUser(
        phoneNumber: deviceId,
        name: 'Guest Farmer',
        language: 'en',
      );
      state = AsyncValue.data(response.user);
    } catch (e) {
      print('Guest login failed: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

// Selected Language Provider
final selectedLanguageProvider = StateNotifierProvider<SelectedLanguageNotifier, String>((ref) {
  return SelectedLanguageNotifier();
});

class SelectedLanguageNotifier extends StateNotifier<String> {
  SelectedLanguageNotifier() : super('en'); // Default to English

  void setLanguage(String languageCode) {
    state = languageCode;
  }
}

// Supported Languages Provider with Fallback
final supportedLanguagesProvider = FutureProvider<List<Language>>((ref) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.getSupportedLanguages();
    return response.languages;
  } catch (e) {
    // Fallback if API fails (e.g. valid when offline or starting up)
    return [
      Language(code: 'en', name: 'English', native: 'English'),
      Language(code: 'ta', name: 'Tamil', native: 'தமிழ்'),
      Language(code: 'hi', name: 'Hindi', native: 'हिन्दी'),
      Language(code: 'te', name: 'Telugu', native: 'తెలుగు'),
      Language(code: 'kn', name: 'Kannada', native: 'ಕನ್ನಡ'),
      Language(code: 'ml', name: 'Malayalam', native: 'മലയാളം'),
    ];
  }
});

// Query History Provider
final queryHistoryProvider = StateNotifierProvider<QueryHistoryNotifier, List<QueryHistory>>((ref) {
  return QueryHistoryNotifier();
});

class QueryHistoryNotifier extends StateNotifier<List<QueryHistory>> {
  QueryHistoryNotifier() : super([]);

  void addQuery(QueryHistory query) {
    state = [query, ...state];
  }

  void clearHistory() {
    state = [];
  }
}

// Connection Status Provider
final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, bool>((ref) {
  return ConnectionStatusNotifier(ref.read(apiServiceProvider));
});

class ConnectionStatusNotifier extends StateNotifier<bool> {
  final ApiService _apiService;

  ConnectionStatusNotifier(this._apiService) : super(true) {
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      await _apiService.getMobileHealth();
      state = true;
    } catch (e) {
      state = false;
    }
  }

  Future<void> checkConnection() async {
    await _checkConnection();
  }
}

// Current Query Provider
final currentQueryProvider = StateNotifierProvider<CurrentQueryNotifier, AsyncValue<dynamic>>((ref) {
  return CurrentQueryNotifier(ref.read(apiServiceProvider));
});

class CurrentQueryNotifier extends StateNotifier<AsyncValue<dynamic>> {
  final ApiService _apiService;

  CurrentQueryNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> sendTextQuery({
    required String text,
    required String language,
    int? userId,
    String? sessionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.sendTextQuery(
        text: text,
        language: language,
        userId: userId,
        sessionId: sessionId,
      );
      state = AsyncValue.data(response);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendVoiceQuery({
    required String audioPath,
    required String language,
    int? userId,
    String? sessionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.sendVoiceQuery(
        audioPath: audioPath,
        language: language,
        userId: userId,
        sessionId: sessionId,
      );
      state = AsyncValue.data(response);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clearQuery() {
    state = const AsyncValue.data(null);
  }
}