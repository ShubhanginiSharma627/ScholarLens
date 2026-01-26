import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/models.dart';
import '../services/audio_service.dart';

/// Global app state provider using ChangeNotifier
class AppStateProvider extends ChangeNotifier {
  AppState _state = AppState.initial();
  bool _isLoading = false;
  String? _error;
  AudioService? _audioService;
  int? _savedNavigationIndex;

  // Getters
  AppState get state => _state;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AudioService? get audioService => _audioService;
  
  // Convenience getters
  UserProgress get userProgress => _state.userProgress;
  List<LearningSession> get recentSessions => _state.recentSessions;
  bool get isOfflineMode => _state.isOfflineMode;
  AudioState get audioState => _state.audioState;
  VoiceInputState get voiceState => _state.voiceState;
  List<ChatMessage> get chatHistory => _state.chatHistory;
  String? get currentUserId => _state.currentUserId;
  String get userName => _state.userName;
  AppSettings get settings => _state.settings;

  /// Initialize the app state from persistent storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('app_state');
      
      if (stateJson != null) {
        final stateMap = json.decode(stateJson) as Map<String, dynamic>;
        _state = AppState.fromJson(stateMap);
      } else {
        _state = AppState.initial();
      }
      
      // Initialize audio service
      _audioService = FlutterAudioService();
      
      _clearError();
    } catch (e) {
      _setError('Failed to load app state: $e');
      _state = AppState.initial();
    } finally {
      _setLoading(false);
    }
  }

  /// Save the current state to persistent storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = json.encode(_state.toJson());
      await prefs.setString('app_state', stateJson);
    } catch (e) {
      _setError('Failed to save app state: $e');
    }
  }

  /// Update the entire app state
  Future<void> updateState(AppState newState) async {
    _state = newState;
    notifyListeners();
    await _saveState();
  }

  /// Update user progress
  Future<void> updateUserProgress(UserProgress progress) async {
    _state = _state.copyWith(userProgress: progress);
    notifyListeners();
    await _saveState();
  }

  /// Add a new learning session
  Future<void> addLearningSession(LearningSession session) async {
    _state = _state.addLearningSession(session);
    notifyListeners();
    await _saveState();
  }

  /// Add a chat message
  Future<void> addChatMessage(ChatMessage message) async {
    _state = _state.addChatMessage(message);
    notifyListeners();
    await _saveState();
  }

  /// Update a chat message
  Future<void> updateChatMessage(String messageId, ChatMessage updatedMessage) async {
    _state = _state.updateChatMessage(messageId, updatedMessage);
    notifyListeners();
    await _saveState();
  }

  /// Set offline mode
  Future<void> setOfflineMode(bool isOffline) async {
    _state = _state.copyWith(isOfflineMode: isOffline);
    notifyListeners();
    await _saveState();
  }

  /// Update audio state
  void updateAudioState(AudioState audioState) {
    _state = _state.copyWith(audioState: audioState);
    notifyListeners();
    // Don't save audio state as it's transient
  }

  /// Update voice input state
  void updateVoiceState(VoiceInputState voiceState) {
    _state = _state.copyWith(voiceState: voiceState);
    notifyListeners();
    // Don't save voice state as it's transient
  }

  /// Update app settings
  Future<void> updateSettings(AppSettings settings) async {
    _state = _state.copyWith(settings: settings);
    notifyListeners();
    await _saveState();
  }

  /// Set current user ID
  Future<void> setCurrentUser(String userId) async {
    _state = _state.copyWith(currentUserId: userId);
    notifyListeners();
    await _saveState();
  }

  /// Set user name
  Future<void> setUserName(String name) async {
    _state = _state.copyWith(userName: name);
    notifyListeners();
    await _saveState();
  }

  /// Set audio service instance
  void setAudioService(AudioService audioService) {
    _audioService = audioService;
  }

  /// Save navigation state for restoration
  void saveNavigationState(int index) {
    _savedNavigationIndex = index;
  }

  /// Get saved navigation index
  int? getSavedNavigationIndex() {
    return _savedNavigationIndex;
  }

  /// Clear all data (logout)
  Future<void> clearData() async {
    _state = AppState.initial();
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('app_state');
    } catch (e) {
      _setError('Failed to clear app data: $e');
    }
  }

  /// Reset to initial state
  Future<void> reset() async {
    _state = AppState.initial();
    notifyListeners();
    await _saveState();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}