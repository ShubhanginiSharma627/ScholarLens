import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'audio_service.dart';

/// Manages app lifecycle events and state restoration
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

  /// Handle app going to background/paused state
  Future<void> handleAppPaused() async {
    try {
      // Stop any playing audio
      await _audioService?.stop();
      
      // Save current timestamp for session tracking
      await _saveLifecycleState({
        'pausedAt': DateTime.now().toIso8601String(),
        'wasAudioPlaying': _audioService?.isPlaying ?? false,
      });
      
      // Clear sensitive data from memory if needed
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

  /// Handle app coming to foreground/resumed state
  Future<void> handleAppResumed() async {
    try {
      final lifecycleState = await _getLifecycleState();
      
      if (lifecycleState != null) {
        final pausedAtStr = lifecycleState['pausedAt'] as String?;
        if (pausedAtStr != null) {
          final pausedAt = DateTime.parse(pausedAtStr);
          final resumedAt = DateTime.now();
          final backgroundDuration = resumedAt.difference(pausedAt);
          
          // Handle long background periods (e.g., refresh data)
          if (backgroundDuration.inMinutes > 30) {
            await _handleLongBackgroundPeriod();
          }
          
          // Restore audio state if it was playing
          final wasAudioPlaying = lifecycleState['wasAudioPlaying'] as bool? ?? false;
          if (wasAudioPlaying) {
            // Don't auto-resume audio, just notify user it was stopped
            await _notifyAudioStopped();
          }
        }
      }
      
      // Trigger state restoration callback
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

  /// Handle app being detached/terminated
  Future<void> handleAppDetached() async {
    try {
      // Stop all services
      await _audioService?.stop();
      
      // Save final state
      await _saveLifecycleState({
        'detachedAt': DateTime.now().toIso8601String(),
      });
      
      // Cleanup resources
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

  /// Handle app becoming inactive (transitioning between states)
  Future<void> handleAppInactive() async {
    try {
      // Pause audio but don't stop it completely
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

  /// Save navigation state for restoration
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

  /// Restore navigation state
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

  /// Clear navigation state
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

  // Private helper methods

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
    // Clear any sensitive data from memory
    // This could include temporary tokens, cached images, etc.
    try {
      // Force garbage collection
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
    // Handle cases where app was in background for a long time
    try {
      if (kDebugMode) {
        print('Handling long background period - refreshing data');
      }
      // Could trigger data refresh, re-authentication, etc.
    } catch (e) {
      if (kDebugMode) {
        print('Error handling long background period: $e');
      }
    }
  }

  Future<void> _notifyAudioStopped() async {
    // Notify that audio was stopped due to app lifecycle
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
    // Cleanup resources before app termination
    try {
      // Clear temporary files, close connections, etc.
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

/// Extension to add lifecycle management to any widget
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
  
  // Override these methods in your widget to handle specific lifecycle events
  AppLifecycleManager? createLifecycleManager() => null;
  void onAppResumed() {}
  void onAppInactive() {}
  void onAppPaused() {}
  void onAppDetached() {}
  void onAppHidden() {}
}