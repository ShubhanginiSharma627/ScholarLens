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
  bool _isOfflineMode = false;
  User? _cachedUser;
  DateTime? _lastSyncTime;
  static const String _offlineModeKey = 'offline_mode';
  static const String _cachedUserKey = 'cached_user';
  static const String _lastSyncKey = 'last_sync_time';
  static const Duration _maxOfflineTime = Duration(days: 7);
  static const Duration _syncInterval = Duration(hours: 1);
  Future<void> initialize() async {
    try {
      debugPrint('Initializing offline auth handler');
      await _loadOfflineState();
      await _checkConnectivity();
      debugPrint('Offline auth handler initialized (offline: $_isOfflineMode)');
    } catch (e) {
      debugPrint('Offline auth handler initialization error: $e');
    }
  }
  bool get isOfflineMode => _isOfflineMode;
  User? get cachedUser => _cachedUser;
  DateTime? get lastSyncTime => _lastSyncTime;
  Future<bool> isOfflineAuthAvailable() async {
    try {
      if (_cachedUser == null) {
        return false;
      }
      if (_lastSyncTime != null) {
        final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
        if (timeSinceSync > _maxOfflineTime) {
          debugPrint('Offline auth expired (${timeSinceSync.inDays} days since last sync)');
          return false;
        }
      }
      final token = await _secureStorage.getAccessToken();
      return token != null;
    } catch (e) {
      debugPrint('Offline auth availability check error: $e');
      return false;
    }
  }
  Future<AuthResult> authenticateOffline() async {
    try {
      debugPrint('Attempting offline authentication');
      if (!await isOfflineAuthAvailable()) {
        return AuthResult.failure(
          error: 'Offline authentication not available',
          errorType: AuthErrorType.networkError,
        );
      }
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
  Future<void> cacheUserData(User user, String accessToken) async {
    try {
      debugPrint('Caching user data for offline use: ${user.email}');
      _cachedUser = user;
      _lastSyncTime = DateTime.now();
      await _secureStorage.storeString(_cachedUserKey, jsonEncode(user.toJson()));
      await _secureStorage.storeString(_lastSyncKey, _lastSyncTime!.toIso8601String());
      debugPrint('User data cached successfully');
    } catch (e) {
      debugPrint('Cache user data error: $e');
    }
  }
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
  Future<AuthResult?> syncWithServer(
    Future<AuthResult> Function() serverAuthFunction,
  ) async {
    try {
      debugPrint('Syncing with server');
      if (!await _networkService.isConnected()) {
        debugPrint('No network connection for sync');
        return null;
      }
      final result = await serverAuthFunction();
      if (result.success && result.user != null && result.accessToken != null) {
        await cacheUserData(result.user!, result.accessToken!);
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
  Future<void> onConnectivityChanged(bool isConnected) async {
    try {
      debugPrint('Connectivity changed: $isConnected');
      if (isConnected && _isOfflineMode) {
        debugPrint('Connection restored, attempting to sync');
      } else if (!isConnected && !_isOfflineMode) {
        debugPrint('Connection lost, enabling offline mode');
        await enableOfflineMode();
      }
    } catch (e) {
      debugPrint('Connectivity change handling error: $e');
    }
  }
  bool isSyncNeeded() {
    if (_lastSyncTime == null) return true;
    final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
    return timeSinceSync > _syncInterval;
  }
  Duration? getTimeUntilExpiry() {
    if (_lastSyncTime == null) return null;
    final expiryTime = _lastSyncTime!.add(_maxOfflineTime);
    final now = DateTime.now();
    if (expiryTime.isBefore(now)) return Duration.zero;
    return expiryTime.difference(now);
  }
  Future<void> _loadOfflineState() async {
    try {
      _isOfflineMode = await _secureStorage.getBool(_offlineModeKey) ?? false;
      final cachedUserJson = await _secureStorage.getString(_cachedUserKey);
      if (cachedUserJson != null) {
        final userData = jsonDecode(cachedUserJson);
        _cachedUser = User.fromJson(userData);
      }
      final lastSyncString = await _secureStorage.getString(_lastSyncKey);
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
      debugPrint('Offline state loaded: offline=$_isOfflineMode, cachedUser=${_cachedUser?.email}');
    } catch (e) {
      debugPrint('Load offline state error: $e');
      _isOfflineMode = false;
      _cachedUser = null;
      _lastSyncTime = null;
    }
  }
  Future<void> _checkConnectivity() async {
    try {
      final isConnected = await _networkService.isConnected();
      if (!isConnected && !_isOfflineMode) {
        await enableOfflineMode();
      } else if (isConnected && _isOfflineMode && isSyncNeeded()) {
        debugPrint('Network available, sync needed');
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');
    }
  }
  void dispose() {
    debugPrint('Disposing offline auth handler');
  }
}
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