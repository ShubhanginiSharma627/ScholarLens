import 'user_progress.dart';
import 'learning_session.dart';
import 'chat_message.dart';

/// Represents the global application state
class AppState {
  final UserProgress userProgress;
  final List<LearningSession> recentSessions;
  final bool isOfflineMode;
  final AudioState audioState;
  final VoiceInputState voiceState;
  final List<ChatMessage> chatHistory;
  final String? currentUserId;
  final String userName;
  final AppSettings settings;

  const AppState({
    required this.userProgress,
    required this.recentSessions,
    required this.isOfflineMode,
    required this.audioState,
    required this.voiceState,
    required this.chatHistory,
    this.currentUserId,
    required this.userName,
    required this.settings,
  });

  /// Creates an AppState from JSON
  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      userProgress: UserProgress.fromJson(json['user_progress'] as Map<String, dynamic>),
      recentSessions: (json['recent_sessions'] as List<dynamic>)
          .map((session) => LearningSession.fromJson(session as Map<String, dynamic>))
          .toList(),
      isOfflineMode: json['is_offline_mode'] as bool,
      audioState: AudioState.values.firstWhere(
        (e) => e.name == json['audio_state'],
        orElse: () => AudioState.idle,
      ),
      voiceState: VoiceInputState.values.firstWhere(
        (e) => e.name == json['voice_state'],
        orElse: () => VoiceInputState.idle,
      ),
      chatHistory: (json['chat_history'] as List<dynamic>)
          .map((message) => ChatMessage.fromJson(message as Map<String, dynamic>))
          .toList(),
      currentUserId: json['current_user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Scholar',
      settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  /// Converts AppState to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_progress': userProgress.toJson(),
      'recent_sessions': recentSessions.map((session) => session.toJson()).toList(),
      'is_offline_mode': isOfflineMode,
      'audio_state': audioState.name,
      'voice_state': voiceState.name,
      'chat_history': chatHistory.map((message) => message.toJson()).toList(),
      'current_user_id': currentUserId,
      'user_name': userName,
      'settings': settings.toJson(),
    };
  }

  /// Creates initial app state for new users
  factory AppState.initial() {
    return AppState(
      userProgress: UserProgress.empty(),
      recentSessions: const [],
      isOfflineMode: false,
      audioState: AudioState.idle,
      voiceState: VoiceInputState.idle,
      chatHistory: const [],
      currentUserId: null,
      userName: 'Scholar',
      settings: AppSettings.defaults(),
    );
  }

  /// Creates a copy with updated fields
  AppState copyWith({
    UserProgress? userProgress,
    List<LearningSession>? recentSessions,
    bool? isOfflineMode,
    AudioState? audioState,
    VoiceInputState? voiceState,
    List<ChatMessage>? chatHistory,
    String? currentUserId,
    String? userName,
    AppSettings? settings,
  }) {
    return AppState(
      userProgress: userProgress ?? this.userProgress,
      recentSessions: recentSessions ?? this.recentSessions,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      audioState: audioState ?? this.audioState,
      voiceState: voiceState ?? this.voiceState,
      chatHistory: chatHistory ?? this.chatHistory,
      currentUserId: currentUserId ?? this.currentUserId,
      userName: userName ?? this.userName,
      settings: settings ?? this.settings,
    );
  }

  /// Adds a new chat message
  AppState addChatMessage(ChatMessage message) {
    return copyWith(
      chatHistory: [...chatHistory, message],
    );
  }

  /// Updates a chat message
  AppState updateChatMessage(String messageId, ChatMessage updatedMessage) {
    final updatedHistory = chatHistory.map((message) {
      return message.id == messageId ? updatedMessage : message;
    }).toList();
    
    return copyWith(chatHistory: updatedHistory);
  }

  /// Adds a new learning session
  AppState addLearningSession(LearningSession session) {
    final updatedSessions = [session, ...recentSessions];
    // Keep only the last 10 sessions
    final limitedSessions = updatedSessions.take(10).toList();
    
    return copyWith(recentSessions: limitedSessions);
  }

  /// Updates user progress
  AppState updateProgress(UserProgress newProgress) {
    return copyWith(userProgress: newProgress);
  }

  /// Toggles offline mode
  AppState toggleOfflineMode() {
    return copyWith(isOfflineMode: !isOfflineMode);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.userProgress == userProgress &&
        _listEquals(other.recentSessions, recentSessions) &&
        other.isOfflineMode == isOfflineMode &&
        other.audioState == audioState &&
        other.voiceState == voiceState &&
        _listEquals(other.chatHistory, chatHistory) &&
        other.currentUserId == currentUserId &&
        other.userName == userName &&
        other.settings == settings;
  }

  @override
  int get hashCode {
    return Object.hash(
      userProgress,
      Object.hashAll(recentSessions),
      isOfflineMode,
      audioState,
      voiceState,
      Object.hashAll(chatHistory),
      currentUserId,
      userName,
      settings,
    );
  }

  @override
  String toString() {
    return 'AppState(userId: $currentUserId, offline: $isOfflineMode, audio: $audioState, voice: $voiceState, sessions: ${recentSessions.length}, messages: ${chatHistory.length})';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Audio playback states
enum AudioState {
  idle('Idle'),
  playing('Playing'),
  paused('Paused'),
  stopped('Stopped');

  const AudioState(this.displayName);
  final String displayName;
}

/// Voice input states
enum VoiceInputState {
  idle('Idle'),
  listening('Listening'),
  processing('Processing'),
  error('Error');

  const VoiceInputState(this.displayName);
  final String displayName;
}

/// Application settings
class AppSettings {
  final bool notificationsEnabled;
  final bool ttsEnabled;
  final double ttsSpeed;
  final String preferredLanguage;
  final bool darkModeEnabled;
  final bool offlineModeEnabled;

  const AppSettings({
    required this.notificationsEnabled,
    required this.ttsEnabled,
    required this.ttsSpeed,
    required this.preferredLanguage,
    required this.darkModeEnabled,
    required this.offlineModeEnabled,
  });

  /// Creates default settings
  factory AppSettings.defaults() {
    return const AppSettings(
      notificationsEnabled: true,
      ttsEnabled: true,
      ttsSpeed: 1.0,
      preferredLanguage: 'en',
      darkModeEnabled: false,
      offlineModeEnabled: true,
    );
  }

  /// Creates settings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notifications_enabled'] as bool,
      ttsEnabled: json['tts_enabled'] as bool,
      ttsSpeed: (json['tts_speed'] as num).toDouble(),
      preferredLanguage: json['preferred_language'] as String,
      darkModeEnabled: json['dark_mode_enabled'] as bool,
      offlineModeEnabled: json['offline_mode_enabled'] as bool,
    );
  }

  /// Converts settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'tts_enabled': ttsEnabled,
      'tts_speed': ttsSpeed,
      'preferred_language': preferredLanguage,
      'dark_mode_enabled': darkModeEnabled,
      'offline_mode_enabled': offlineModeEnabled,
    };
  }

  /// Creates a copy with updated fields
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? ttsEnabled,
    double? ttsSpeed,
    String? preferredLanguage,
    bool? darkModeEnabled,
    bool? offlineModeEnabled,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.notificationsEnabled == notificationsEnabled &&
        other.ttsEnabled == ttsEnabled &&
        other.ttsSpeed == ttsSpeed &&
        other.preferredLanguage == preferredLanguage &&
        other.darkModeEnabled == darkModeEnabled &&
        other.offlineModeEnabled == offlineModeEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      notificationsEnabled,
      ttsEnabled,
      ttsSpeed,
      preferredLanguage,
      darkModeEnabled,
      offlineModeEnabled,
    );
  }

  @override
  String toString() {
    return 'AppSettings(notifications: $notificationsEnabled, tts: $ttsEnabled, speed: $ttsSpeed, lang: $preferredLanguage, dark: $darkModeEnabled, offline: $offlineModeEnabled)';
  }
}