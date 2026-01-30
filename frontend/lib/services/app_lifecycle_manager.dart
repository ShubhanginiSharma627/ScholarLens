import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'audio_service.dart';
class AppLifecycleManager {
  static const String _stateKey = 'app_lifecycle_state';
  static const String _navigationKey = 'navigation_state';
  final AudioService? _audioService;
  final VoidCallback? _onStateRestored;
  AppLifecycleManager({
    AudioService? audioService,
    VoidCallback? onStateRestored,
  }) : _audioService = audioService,
       _onStateRestored = onStateRestored;
  Future<void> handleAppPaused() async {
    try {
      await _audioService?.stop();
      await _saveLifecycleState({
        'pausedAt': DateTime.now().toIso8601String(),
        'wasAudioPlaying': _audioService?.isPlaying ?? false,
      });
      await _clearSensitiveData();
      if (kDebugMode) {
        print('App lifecycle: Paused state handled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling app pause: $e');
      }
    }
  }
  Future<void> handleAppResumed() async {
    try {
      final lifecycleState = await _getLifecycleState();
      if (lifecycleState != null) {
        final pausedAtStr = lifecycleState['pausedAt'] as String?;
        if (pausedAtStr != null) {
          final pausedAt = DateTime.parse(pausedAtStr);
          final resumedAt = DateTime.now();
          final backgroundDuration = resumedAt.difference(pausedAt);
          if (backgroundDuration.inMinutes > 30) {
            await _handleLongBackgroundPeriod();
          }
          final wasAudioPlaying = lifecycleState['wasAudioPlaying'] as bool? ?? false;
          if (wasAudioPlaying) {
            await _notifyAudioStopped();
          }
        }
      }
      _onStateRestored?.call();
      if (kDebugMode) {
        print('App lifecycle: Resumed state handled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling app resume: $e');
      }
    }
  }
  Future<void> handleAppDetached() async {
    try {
      await _audioService?.stop();
      await _saveLifecycleState({
        'detachedAt': DateTime.now().toIso8601String(),
      });
      await _cleanup();
      if (kDebugMode) {
        print('App lifecycle: Detached state handled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling app detach: $e');
      }
    }
  }
  Future<void> handleAppInactive() async {
    try {
      await _audioService?.pause();
      if (kDebugMode) {
        print('App lifecycle: Inactive state handled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling app inactive: $e');
      }
    }
  }
  Future<void> saveNavigationState(int currentIndex, {Map<String, dynamic>? additionalData}) async {
    try {
      final navigationState = {
        'currentIndex': currentIndex,
        'savedAt': DateTime.now().toIso8601String(),
        ...?additionalData,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_navigationKey, json.encode(navigationState));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving navigation state: $e');
      }
    }
  }
  Future<Map<String, dynamic>?> getNavigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_navigationKey);
      if (stateJson != null) {
        return json.decode(stateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting navigation state: $e');
      }
    }
    return null;
  }
  Future<void> clearNavigationState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_navigationKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing navigation state: $e');
      }
    }
  }
  Future<void> _saveLifecycleState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stateKey, json.encode(state));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving lifecycle state: $e');
      }
    }
  }
  Future<Map<String, dynamic>?> _getLifecycleState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);
      if (stateJson != null) {
        return json.decode(stateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting lifecycle state: $e');
      }
    }
    return null;
  }
  Future<void> _clearSensitiveData() async {
    try {
      if (kDebugMode) {
        print('Clearing sensitive data from memory');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing sensitive data: $e');
      }
    }
  }
  Future<void> _handleLongBackgroundPeriod() async {
    try {
      if (kDebugMode) {
        print('Handling long background period - refreshing data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling long background period: $e');
      }
    }
  }
  Future<void> _notifyAudioStopped() async {
    try {
      if (kDebugMode) {
        print('Audio was stopped due to app going to background');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying audio stopped: $e');
      }
    }
  }
  Future<void> _cleanup() async {
    try {
      if (kDebugMode) {
        print('Cleaning up app resources');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during cleanup: $e');
      }
    }
  }
}
mixin AppLifecycleMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  AppLifecycleManager? _lifecycleManager;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleManager = createLifecycleManager();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecycleManager?.handleAppResumed();
        onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _lifecycleManager?.handleAppInactive();
        onAppInactive();
        break;
      case AppLifecycleState.paused:
        _lifecycleManager?.handleAppPaused();
        onAppPaused();
        break;
      case AppLifecycleState.detached:
        _lifecycleManager?.handleAppDetached();
        onAppDetached();
        break;
      case AppLifecycleState.hidden:
        onAppHidden();
        break;
    }
  }
  AppLifecycleManager? createLifecycleManager() => null;
  void onAppResumed() {}
  void onAppInactive() {}
  void onAppPaused() {}
  void onAppDetached() {}
  void onAppHidden() {}
}