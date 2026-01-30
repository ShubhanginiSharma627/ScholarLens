import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/models.dart';
import 'authentication_service.dart';
import 'secure_storage_service.dart';
class SessionManager {
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager._();
  SessionManager._();
  final SecureStorageService _secureStorage = SecureStorageService();
  Timer? _refreshTimer;
  Timer? _sessionCheckTimer;
  static const Duration _refreshThreshold = Duration(minutes: 5);
  static const Duration _sessionCheckInterval = Duration(minutes: 1);
  static const Duration _maxSessionDuration = Duration(hours: 24);
  bool _isSessionActive = false;
  DateTime? _lastActivity;
  String? _currentUserId;
  final StreamController<bool> _sessionStateController = StreamController<bool>.broadcast();
  final StreamController<AuthErrorType> _sessionErrorController = StreamController<AuthErrorType>.broadcast();
  Stream<bool> get sessionStateStream => _sessionStateController.stream;
  Stream<AuthErrorType> get sessionErrorStream => _sessionErrorController.stream;
  bool get isSessionActive => _isSessionActive;
  String? get currentUserId => _currentUserId;
  DateTime? get lastActivity => _lastActivity;
  Future<void> initialize() async {
    try {
      debugPrint('Initializing session manager');
      if (await _secureStorage.isSessionCleanupDue()) {
        await _secureStorage.performSessionCleanup();
      }
      final hasAuth = await _secureStorage.hasAuthenticationData();
      if (!hasAuth) {
        debugPrint('No stored authentication data found');
        _updateSessionState(false);
        return;
      }
      final rememberMe = await _secureStorage.getRememberMe();
      if (!rememberMe) {
        debugPrint('Remember me not enabled, clearing session');
        await clearSession();
        return;
      }
      final restored = await _restoreSession();
      if (restored) {
        debugPrint('Session restored successfully');
        _startSessionMonitoring();
      } else {
        debugPrint('Failed to restore session');
        await clearSession();
      }
    } catch (e) {
      debugPrint('Session initialization error: $e');
      await clearSession();
    }
  }
  Future<void> startSession({
    required String accessToken,
    String? refreshToken,
    required String userId,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('Starting new session for user: $userId (rememberMe: $rememberMe)');
      await _secureStorage.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        rememberMe: rememberMe,
      );
      _currentUserId = userId;
      _lastActivity = DateTime.now();
      _updateSessionState(true);
      _startSessionMonitoring();
      _startTokenRefreshTimer(accessToken);
      debugPrint('Session started successfully with ${rememberMe ? "long-term" : "short-term"} expiry');
    } catch (e) {
      debugPrint('Error starting session: $e');
      _sessionErrorController.add(AuthErrorType.sessionTerminated);
      rethrow;
    }
  }
  Future<void> endSession() async {
    try {
      debugPrint('Ending current session');
      _stopTimers();
      await _secureStorage.clearAuthenticationData();
      _currentUserId = null;
      _lastActivity = null;
      _updateSessionState(false);
      debugPrint('Session ended successfully');
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }
  Future<void> clearSession() async {
    try {
      debugPrint('Clearing all session data');
      _stopTimers();
      await _secureStorage.secureWipeAll();
      _currentUserId = null;
      _lastActivity = null;
      _updateSessionState(false);
      debugPrint('Session cleared successfully');
    } catch (e) {
      debugPrint('Error clearing session: $e');
      rethrow;
    }
  }
  void updateActivity() {
    _lastActivity = DateTime.now();
    debugPrint('Session activity updated');
  }
  Future<bool> isSessionValid() async {
    try {
      if (!_isSessionActive) return false;
      final token = await _secureStorage.getAccessToken();
      if (token == null) return false;
      final isExpired = await _secureStorage.isSessionExpired();
      if (isExpired) {
        debugPrint('Session expired based on stored expiry time');
        await _terminateSession(AuthErrorType.sessionTerminated);
        return false;
      }
      if (JwtDecoder.isExpired(token)) {
        debugPrint('Access token expired, attempting refresh');
        return await _attemptTokenRefresh();
      }
      final lastLogin = await _secureStorage.getLastLogin();
      if (lastLogin != null) {
        final sessionAge = DateTime.now().difference(lastLogin);
        if (sessionAge > _maxSessionDuration) {
          debugPrint('Session exceeded maximum duration');
          await _terminateSession(AuthErrorType.sessionTerminated);
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }
  Future<String?> getValidAccessToken() async {
    try {
      if (!await isSessionValid()) return null;
      final token = await _secureStorage.getAccessToken();
      if (token == null) return null;
      if (_shouldRefreshToken(token)) {
        debugPrint('Token needs refresh');
        final refreshed = await _attemptTokenRefresh();
        if (!refreshed) return null;
        return await _secureStorage.getAccessToken();
      }
      return token;
    } catch (e) {
      debugPrint('Error getting valid access token: $e');
      return null;
    }
  }
  Future<bool> _restoreSession() async {
    try {
      final token = await _secureStorage.getAccessToken();
      final userId = await _secureStorage.getUserId();
      if (token == null || userId == null) return false;
      final rememberMe = await _secureStorage.getRememberMe();
      if (!rememberMe) {
        debugPrint('Remember me not enabled, cannot restore session');
        return false;
      }
      final isExpired = await _secureStorage.isSessionExpired();
      if (isExpired) {
        debugPrint('Stored session has expired');
        return false;
      }
      if (JwtDecoder.isExpired(token)) {
        final refreshed = await _attemptTokenRefresh();
        if (!refreshed) return false;
      }
      _currentUserId = userId;
      _lastActivity = await _secureStorage.getLastLogin() ?? DateTime.now();
      _updateSessionState(true);
      debugPrint('Session restored successfully for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      return false;
    }
  }
  void _startSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(_sessionCheckInterval, (_) async {
      await _checkSessionHealth();
    });
    debugPrint('Session monitoring started');
  }
  void _startTokenRefreshTimer(String token) {
    _refreshTimer?.cancel();
    try {
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final refreshTime = expiryDate.subtract(_refreshThreshold);
      final delay = refreshTime.difference(DateTime.now());
      if (delay.isNegative) {
        _attemptTokenRefresh();
      } else {
        _refreshTimer = Timer(delay, () async {
          await _attemptTokenRefresh();
        });
        debugPrint('Token refresh scheduled for: $refreshTime');
      }
    } catch (e) {
      debugPrint('Error scheduling token refresh: $e');
    }
  }
  Future<void> _checkSessionHealth() async {
    try {
      if (!_isSessionActive) return;
      final valid = await isSessionValid();
      if (!valid) {
        debugPrint('Session health check failed');
        await _terminateSession(AuthErrorType.sessionTerminated);
      }
    } catch (e) {
      debugPrint('Session health check error: $e');
    }
  }
  Future<bool> _attemptTokenRefresh() async {
    try {
      debugPrint('Attempting token refresh');
      final authService = AuthenticationService.instance;
      final result = await authService.refreshToken();
      if (result.success && result.accessToken != null) {
        debugPrint('Token refresh successful');
        await _secureStorage.storeAccessToken(result.accessToken!);
        _startTokenRefreshTimer(result.accessToken!);
        return true;
      } else {
        debugPrint('Token refresh failed: ${result.error}');
        await _terminateSession(result.errorType ?? AuthErrorType.tokenExpired);
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await _terminateSession(AuthErrorType.tokenExpired);
      return false;
    }
  }
  bool _shouldRefreshToken(String token) {
    try {
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final timeUntilExpiry = expiryDate.difference(DateTime.now());
      return timeUntilExpiry <= _refreshThreshold;
    } catch (e) {
      debugPrint('Error checking token refresh need: $e');
      return true;
    }
  }
  Future<void> _terminateSession(AuthErrorType errorType) async {
    try {
      debugPrint('Terminating session due to: $errorType');
      await endSession();
      _sessionErrorController.add(errorType);
    } catch (e) {
      debugPrint('Error terminating session: $e');
    }
  }
  void _updateSessionState(bool active) {
    if (_isSessionActive != active) {
      _isSessionActive = active;
      _sessionStateController.add(active);
      debugPrint('Session state changed: $active');
    }
  }
  void _stopTimers() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    debugPrint('Session timers stopped');
  }
  void dispose() {
    _stopTimers();
    _sessionStateController.close();
    _sessionErrorController.close();
    debugPrint('Session manager disposed');
  }
  Future<Map<String, dynamic>> getSecurityMetrics() async {
    try {
      final storageMetrics = await _secureStorage.getSecurityMetrics();
      return {
        ...storageMetrics,
        'sessionActive': _isSessionActive,
        'currentUserId': _currentUserId != null ? 'present' : 'none',
        'lastActivity': _lastActivity?.toIso8601String(),
        'sessionAge': _lastActivity != null 
            ? DateTime.now().difference(_lastActivity!).inMinutes 
            : null,
      };
    } catch (e) {
      debugPrint('Error getting session security metrics: $e');
      return {
        'error': 'Failed to retrieve session metrics',
        'sessionHealth': 'error',
      };
    }
  }
}