import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'secure_storage_service.dart';
import 'network_service.dart';

class OfflineAuthHandler {
  static OfflineAuthHandler? _instance;
  static OfflineAuthHandler get instance => _instance ??= OfflineAuthHandler._();

  OfflineAuthHandler._();

  final SecureStorageService _secureStorage = SecureStorageService();
  final NetworkService _networkService = NetworkService.instance;

  // Offline state
  bool _isOfflineMode = false;
  User? _cachedUser;
  DateTime? _lastSyncTime;

  // Storage keys
  static const String _offlineModeKey = 'offline_mode';
  static const String _cachedUserKey = 'cached_user';
  static const String _lastSyncKey = 'last_sync_time';

  // Configuration
  static const Duration _maxOfflineTime = Duration(days: 7);
  static const Duration _syncInterval = Duration(hours: 1);

  /// Initialize offline handler
  Future<void> initialize() async {
    try {
      debugPrint('Initializing offline auth handler');

      // Load offline state
      await _loadOfflineState();

      // Check network connectivity
      await _checkConnectivity();

      debugPrint('Offline auth handler initialized (offline: $_isOfflineMode)');
    } catch (e) {
      debugPrint('Offline auth handler initialization error: $e');
    }
  }

  /// Check if currently in offline mode
  bool get isOfflineMode => _isOfflineMode;

  /// Get cached user (if available)
  User? get cachedUser => _cachedUser;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if offline authentication is available
  Future<bool> isOfflineAuthAvailable() async {
    try {
      // Check if we have cached user data
      if (_cachedUser == null) {
        return false;
      }

      // Check if offline period hasn't exceeded maximum
      if (_lastSyncTime != null) {
        final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
        if (timeSinceSync > _maxOfflineTime) {
          debugPrint('Offline auth expired (${timeSinceSync.inDays} days since last sync)');
          return false;
        }
      }

      // Check if we have valid cached tokens
      final token = await _secureStorage.getAccessToken();
      return token != null;
    } catch (e) {
      debugPrint('Offline auth availability check error: $e');
      return false;
    }
  }

  /// Authenticate using cached credentials (offline mode)
  Future<AuthResult> authenticateOffline() async {
    try {
      debugPrint('Attempting offline authentication');

      // Check if offline auth is available
      if (!await isOfflineAuthAvailable()) {
        return AuthResult.failure(
          error: 'Offline authentication not available',
          errorType: AuthErrorType.networkError,
        );
      }

      // Get cached user and token
      final token = await _secureStorage.getAccessToken();
      if (_cachedUser == null || token == null) {
        return AuthResult.failure(
          error: 'No cached authentication data',
          errorType: AuthErrorType.tokenInvalid,
        );
      }

      debugPrint('Offline authentication successful for user: ${_cachedUser!.email}');
      
      return AuthResult.success(
        user: _cachedUser!,
        accessToken: token,
      );
    } catch (e) {
      debugPrint('Offline authentication error: $e');
      return AuthResult.failure(
        error: 'Offline authentication failed',
        errorType: AuthErrorType.unknown,
      );
    }
  }

  /// Cache user data for offline use
  Future<void> cacheUserData(User user, String accessToken) async {
    try {
      debugPrint('Caching user data for offline use: ${user.email}');

      _cachedUser = user;
      _lastSyncTime = DateTime.now();

      // Store in secure storage
      await _secureStorage.storeString(_cachedUserKey, jsonEncode(user.toJson()));
      await _secureStorage.storeString(_lastSyncKey, _lastSyncTime!.toIso8601String());

      debugPrint('User data cached successfully');
    } catch (e) {
      debugPrint('Cache user data error: $e');
    }
  }

  /// Clear cached user data
  Future<void> clearCachedData() async {
    try {
      debugPrint('Clearing cached user data');

      _cachedUser = null;
      _lastSyncTime = null;

      await _secureStorage.deleteString(_cachedUserKey);
      await _secureStorage.deleteString(_lastSyncKey);

      debugPrint('Cached user data cleared');
    } catch (e) {
      debugPrint('Clear cached data error: $e');
    }
  }

  /// Enable offline mode
  Future<void> enableOfflineMode() async {
    try {
      debugPrint('Enabling offline mode');

      _isOfflineMode = true;
      await _secureStorage.storeBool(_offlineModeKey, true);

      debugPrint('Offline mode enabled');
    } catch (e) {
      debugPrint('Enable offline mode error: $e');
    }
  }

  /// Disable offline mode
  Future<void> disableOfflineMode() async {
    try {
      debugPrint('Disabling offline mode');

      _isOfflineMode = false;
      await _secureStorage.storeBool(_offlineModeKey, false);

      debugPrint('Offline mode disabled');
    } catch (e) {
      debugPrint('Disable offline mode error: $e');
    }
  }

  /// Sync with server when connection is restored
  Future<AuthResult?> syncWithServer(
    Future<AuthResult> Function() serverAuthFunction,
  ) async {
    try {
      debugPrint('Syncing with server');

      // Check network connectivity
      if (!await _networkService.isConnected()) {
        debugPrint('No network connection for sync');
        return null;
      }

      // Attempt server authentication
      final result = await serverAuthFunction();

      if (result.success && result.user != null && result.accessToken != null) {
        // Update cached data
        await cacheUserData(result.user!, result.accessToken!);
        
        // Disable offline mode
        await disableOfflineMode();

        debugPrint('Server sync successful');
        return result;
      } else {
        debugPrint('Server sync failed: ${result.error}');
        return result;
      }
    } catch (e) {
      debugPrint('Server sync error: $e');
      return AuthResult.failure(
        error: 'Sync with server failed',
        errorType: AuthErrorType.networkError,
      );
    }
  }

  /// Get offline mode status information
  Map<String, dynamic> getOfflineStatus() {
    return {
      'isOfflineMode': _isOfflineMode,
      'hasCachedUser': _cachedUser != null,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isOfflineAuthAvailable': _cachedUser != null && _lastSyncTime != null,
      'daysSinceLastSync': _lastSyncTime != null
          ? DateTime.now().difference(_lastSyncTime!).inDays
          : null,
      'maxOfflineDays': _maxOfflineTime.inDays,
    };
  }

  /// Handle network connectivity changes
  Future<void> onConnectivityChanged(bool isConnected) async {
    try {
      debugPrint('Connectivity changed: $isConnected');

      if (isConnected && _isOfflineMode) {
        debugPrint('Connection restored, attempting to sync');
        // Note: Actual sync should be triggered by the calling code
        // This just updates the offline mode state
      } else if (!isConnected && !_isOfflineMode) {
        debugPrint('Connection lost, enabling offline mode');
        await enableOfflineMode();
      }
    } catch (e) {
      debugPrint('Connectivity change handling error: $e');
    }
  }

  /// Check if sync is needed
  bool isSyncNeeded() {
    if (_lastSyncTime == null) return true;
    
    final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceSync > _syncInterval;
  }

  /// Get time until offline auth expires
  Duration? getTimeUntilExpiry() {
    if (_lastSyncTime == null) return null;
    
    final expiryTime = _lastSyncTime!.add(_maxOfflineTime);
    final now = DateTime.now();
    
    if (expiryTime.isBefore(now)) return Duration.zero;
    
    return expiryTime.difference(now);
  }

  /// Load offline state from storage
  Future<void> _loadOfflineState() async {
    try {
      // Load offline mode flag
      _isOfflineMode = await _secureStorage.getBool(_offlineModeKey) ?? false;

      // Load cached user
      final cachedUserJson = await _secureStorage.getString(_cachedUserKey);
      if (cachedUserJson != null) {
        final userData = jsonDecode(cachedUserJson);
        _cachedUser = User.fromJson(userData);
      }

      // Load last sync time
      final lastSyncString = await _secureStorage.getString(_lastSyncKey);
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }

      debugPrint('Offline state loaded: offline=$_isOfflineMode, cachedUser=${_cachedUser?.email}');
    } catch (e) {
      debugPrint('Load offline state error: $e');
      // Reset state on error
      _isOfflineMode = false;
      _cachedUser = null;
      _lastSyncTime = null;
    }
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    try {
      final isConnected = await _networkService.isConnected();
      
      if (!isConnected && !_isOfflineMode) {
        await enableOfflineMode();
      } else if (isConnected && _isOfflineMode && isSyncNeeded()) {
        // Don't automatically disable offline mode, let the sync process handle it
        debugPrint('Network available, sync needed');
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('Disposing offline auth handler');
  }
}

/// Offline authentication configuration
class OfflineAuthConfig {
  final Duration maxOfflineTime;
  final Duration syncInterval;
  final bool enableOfflineAuth;
  final bool autoSync;

  const OfflineAuthConfig({
    this.maxOfflineTime = const Duration(days: 7),
    this.syncInterval = const Duration(hours: 1),
    this.enableOfflineAuth = true,
    this.autoSync = true,
  });

  @override
  String toString() {
    return 'OfflineAuthConfig(maxOfflineTime: $maxOfflineTime, syncInterval: $syncInterval, enableOfflineAuth: $enableOfflineAuth, autoSync: $autoSync)';
  }
}