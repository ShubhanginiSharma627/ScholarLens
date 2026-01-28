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
  
  // Session configuration
  static const Duration _refreshThreshold = Duration(minutes: 5); // Refresh when 5 minutes left
  static const Duration _sessionCheckInterval = Duration(minutes: 1); // Check session every minute
  static const Duration _maxSessionDuration = Duration(hours: 24); // Maximum session duration
  
  // Session state
  bool _isSessionActive = false;
  DateTime? _lastActivity;
  String? _currentUserId;
  
  // Stream controllers for session events
  final StreamController<bool> _sessionStateController = StreamController<bool>.broadcast();
  final StreamController<AuthErrorType> _sessionErrorController = StreamController<AuthErrorType>.broadcast();

  /// Stream of session state changes
  Stream<bool> get sessionStateStream => _sessionStateController.stream;

  /// Stream of session errors
  Stream<AuthErrorType> get sessionErrorStream => _sessionErrorController.stream;

  /// Check if session is currently active
  bool get isSessionActive => _isSessionActive;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Get last activity timestamp
  DateTime? get lastActivity => _lastActivity;

  /// Initialize session manager and restore session if available
  Future<void> initialize() async {
    try {
      debugPrint('Initializing session manager');
      
      // Check if we have stored authentication data
      final hasAuth = await _secureStorage.hasAuthenticationData();
      if (!hasAuth) {
        debugPrint('No stored authentication data found');
        _updateSessionState(false);
        return;
      }

      // Check remember me preference
      final rememberMe = await _secureStorage.getRememberMe();
      if (!rememberMe) {
        debugPrint('Remember me not enabled, clearing session');
        await clearSession();
        return;
      }

      // Attempt to restore session
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

  /// Start a new session with tokens
  Future<void> startSession({
    required String accessToken,
    String? refreshToken,
    required String userId,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('Starting new session for user: $userId');

      // Store tokens and session data
      await _secureStorage.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );

      // Store remember me preference
      await _secureStorage.setRememberMe(rememberMe);

      // Update session state
      _currentUserId = userId;
      _lastActivity = DateTime.now();
      _updateSessionState(true);

      // Start monitoring
      _startSessionMonitoring();
      _startTokenRefreshTimer(accessToken);

      debugPrint('Session started successfully');
    } catch (e) {
      debugPrint('Error starting session: $e');
      _sessionErrorController.add(AuthErrorType.sessionTerminated);
      rethrow;
    }
  }

  /// End the current session
  Future<void> endSession() async {
    try {
      debugPrint('Ending current session');

      // Stop timers
      _stopTimers();

      // Clear session data but preserve remember me preference
      await _secureStorage.clearAuthenticationData();

      // Update state
      _currentUserId = null;
      _lastActivity = null;
      _updateSessionState(false);

      debugPrint('Session ended successfully');
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }

  /// Clear all session data including preferences
  Future<void> clearSession() async {
    try {
      debugPrint('Clearing all session data');

      // Stop timers
      _stopTimers();

      // Clear all stored data
      await _secureStorage.clearAll();

      // Update state
      _currentUserId = null;
      _lastActivity = null;
      _updateSessionState(false);

      debugPrint('Session cleared successfully');
    } catch (e) {
      debugPrint('Error clearing session: $e');
      rethrow;
    }
  }

  /// Update last activity timestamp
  void updateActivity() {
    _lastActivity = DateTime.now();
    debugPrint('Session activity updated');
  }

  /// Check if current session is valid
  Future<bool> isSessionValid() async {
    try {
      if (!_isSessionActive) return false;

      final token = await _secureStorage.getAccessToken();
      if (token == null) return false;

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        debugPrint('Access token expired, attempting refresh');
        return await _attemptTokenRefresh();
      }

      // Check session duration
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

  /// Get current access token, refreshing if necessary
  Future<String?> getValidAccessToken() async {
    try {
      if (!await isSessionValid()) return null;

      final token = await _secureStorage.getAccessToken();
      if (token == null) return null;

      // Check if token needs refresh
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

  /// Restore session from stored data
  Future<bool> _restoreSession() async {
    try {
      final token = await _secureStorage.getAccessToken();
      final userId = await _secureStorage.getUserId();
      
      if (token == null || userId == null) return false;

      // Check if token is still valid or can be refreshed
      if (JwtDecoder.isExpired(token)) {
        final refreshed = await _attemptTokenRefresh();
        if (!refreshed) return false;
      }

      // Restore session state
      _currentUserId = userId;
      _lastActivity = await _secureStorage.getLastLogin() ?? DateTime.now();
      _updateSessionState(true);

      return true;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      return false;
    }
  }

  /// Start session monitoring
  void _startSessionMonitoring() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(_sessionCheckInterval, (_) async {
      await _checkSessionHealth();
    });
    debugPrint('Session monitoring started');
  }

  /// Start token refresh timer
  void _startTokenRefreshTimer(String token) {
    _refreshTimer?.cancel();
    
    try {
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final refreshTime = expiryDate.subtract(_refreshThreshold);
      final delay = refreshTime.difference(DateTime.now());

      if (delay.isNegative) {
        // Token expires soon, refresh immediately
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

  /// Check session health
  Future<void> _checkSessionHealth() async {
    try {
      if (!_isSessionActive) return;

      // Check if session is still valid
      final valid = await isSessionValid();
      if (!valid) {
        debugPrint('Session health check failed');
        await _terminateSession(AuthErrorType.sessionTerminated);
      }
    } catch (e) {
      debugPrint('Session health check error: $e');
    }
  }

  /// Attempt to refresh access token
  Future<bool> _attemptTokenRefresh() async {
    try {
      debugPrint('Attempting token refresh');
      
      final authService = AuthenticationService.instance;
      final result = await authService.refreshToken();

      if (result.success && result.accessToken != null) {
        debugPrint('Token refresh successful');
        
        // Update stored token
        await _secureStorage.storeAccessToken(result.accessToken!);
        
        // Restart refresh timer with new token
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

  /// Check if token should be refreshed
  bool _shouldRefreshToken(String token) {
    try {
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final timeUntilExpiry = expiryDate.difference(DateTime.now());
      return timeUntilExpiry <= _refreshThreshold;
    } catch (e) {
      debugPrint('Error checking token refresh need: $e');
      return true; // Assume refresh needed if we can't parse
    }
  }

  /// Terminate session due to error
  Future<void> _terminateSession(AuthErrorType errorType) async {
    try {
      debugPrint('Terminating session due to: $errorType');
      
      await endSession();
      _sessionErrorController.add(errorType);
    } catch (e) {
      debugPrint('Error terminating session: $e');
    }
  }

  /// Update session state and notify listeners
  void _updateSessionState(bool active) {
    if (_isSessionActive != active) {
      _isSessionActive = active;
      _sessionStateController.add(active);
      debugPrint('Session state changed: $active');
    }
  }

  /// Stop all timers
  void _stopTimers() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    debugPrint('Session timers stopped');
  }

  /// Dispose of the session manager
  void dispose() {
    _stopTimers();
    _sessionStateController.close();
    _sessionErrorController.close();
    debugPrint('Session manager disposed');
  }
}