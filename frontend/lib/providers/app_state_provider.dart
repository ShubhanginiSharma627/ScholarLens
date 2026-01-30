import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/audio_service.dart';
class AppStateProvider extends ChangeNotifier {
  AppState _state = AppState.initial();
  bool _isLoading = false;
  String? _error;
  AudioService? _audioService;
  int? _savedNavigationIndex;
  AppState get state => _state;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AudioService? get audioService => _audioService;
  UserProgress get userProgress => _state.userProgress;
  List<LearningSession> get recentSessions => _state.recentSessions;
  bool get isOfflineMode => _state.isOfflineMode;
  AudioState get audioState => _state.audioState;
  VoiceInputState get voiceState => _state.voiceState;
  List<ChatMessage> get chatHistory => _state.chatHistory;
  String? get currentUserId => _state.currentUserId;
  String get userName => _state.userName;
  AppSettings get settings => _state.settings;
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
      _audioService = FlutterAudioService();
      _clearError();
    } catch (e) {
      _setError('Failed to load app state: $e');
      _state = AppState.initial();
    } finally {
      _setLoading(false);
    }
  }
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = json.encode(_state.toJson());
      await prefs.setString('app_state', stateJson);
    } catch (e) {
      _setError('Failed to save app state: $e');
    }
  }
  Future<void> updateState(AppState newState) async {
    _state = newState;
    notifyListeners();
    await _saveState();
  }
  Future<void> updateUserProgress(UserProgress progress) async {
    _state = _state.copyWith(userProgress: progress);
    notifyListeners();
    await _saveState();
  }
  Future<void> addLearningSession(LearningSession session) async {
    _state = _state.addLearningSession(session);
    notifyListeners();
    await _saveState();
  }
  Future<void> addChatMessage(ChatMessage message) async {
    _state = _state.addChatMessage(message);
    notifyListeners();
    await _saveState();
  }
  Future<void> updateChatMessage(String messageId, ChatMessage updatedMessage) async {
    _state = _state.updateChatMessage(messageId, updatedMessage);
    notifyListeners();
    await _saveState();
  }
  Future<void> setOfflineMode(bool isOffline) async {
    _state = _state.copyWith(isOfflineMode: isOffline);
    notifyListeners();
    await _saveState();
  }
  void updateAudioState(AudioState audioState) {
    _state = _state.copyWith(audioState: audioState);
    notifyListeners();
  }
  void updateVoiceState(VoiceInputState voiceState) {
    _state = _state.copyWith(voiceState: voiceState);
    notifyListeners();
  }
  Future<void> updateSettings(AppSettings settings) async {
    _state = _state.copyWith(settings: settings);
    notifyListeners();
    await _saveState();
  }
  Future<void> setCurrentUser(String userId) async {
    _state = _state.copyWith(currentUserId: userId);
    notifyListeners();
    await _saveState();
  }
  Future<void> setUserName(String name) async {
    _state = _state.copyWith(userName: name);
    notifyListeners();
    await _saveState();
  }
  void setAudioService(AudioService audioService) {
    _audioService = audioService;
  }
  void saveNavigationState(int index) {
    _savedNavigationIndex = index;
  }
  int? getSavedNavigationIndex() {
    return _savedNavigationIndex;
  }
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
  Future<void> reset() async {
    _state = AppState.initial();
    notifyListeners();
    await _saveState();
  }
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