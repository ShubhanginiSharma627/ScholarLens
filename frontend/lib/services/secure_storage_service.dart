import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _lastLoginKey = 'last_login';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _sessionCleanupKey = 'session_cleanup';

  // Security configuration
  static const int _keyRotationDays = 30;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  /// Store access token securely
  Future<void> storeAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      debugPrint('Access token stored securely');
    } catch (e) {
      debugPrint('Error storing access token: $e');
      rethrow;
    }
  }

  /// Retrieve access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('Error retrieving access token: $e');
      return null;
    }
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      debugPrint('Refresh token stored securely');
    } catch (e) {
      debugPrint('Error storing refresh token: $e');
      rethrow;
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Error retrieving refresh token: $e');
      return null;
    }
  }

  /// Store user ID
  Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      debugPrint('User ID stored securely');
    } catch (e) {
      debugPrint('Error storing user ID: $e');
      rethrow;
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error retrieving user ID: $e');
      return null;
    }
  }

  /// Store remember me preference
  Future<void> setRememberMe(bool remember) async {
    try {
      await _storage.write(key: _rememberMeKey, value: remember.toString());
      debugPrint('Remember me preference stored: $remember');
    } catch (e) {
      debugPrint('Error storing remember me preference: $e');
      rethrow;
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    try {
      final value = await _storage.read(key: _rememberMeKey);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error retrieving remember me preference: $e');
      return false;
    }
  }

  /// Store last login timestamp
  Future<void> storeLastLogin(DateTime timestamp) async {
    try {
      await _storage.write(key: _lastLoginKey, value: timestamp.toIso8601String());
      debugPrint('Last login timestamp stored');
    } catch (e) {
      debugPrint('Error storing last login timestamp: $e');
      rethrow;
    }
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLogin() async {
    try {
      final value = await _storage.read(key: _lastLoginKey);
      return value != null ? DateTime.parse(value) : null;
    } catch (e) {
      debugPrint('Error retrieving last login timestamp: $e');
      return null;
    }
  }

  /// Store session expiry time
  Future<void> storeSessionExpiry(DateTime expiryTime) async {
    try {
      await _storage.write(key: _sessionExpiryKey, value: expiryTime.toIso8601String());
      debugPrint('Session expiry stored: $expiryTime');
    } catch (e) {
      debugPrint('Error storing session expiry: $e');
      rethrow;
    }
  }

  /// Get session expiry time
  Future<DateTime?> getSessionExpiry() async {
    try {
      final value = await _storage.read(key: _sessionExpiryKey);
      return value != null ? DateTime.parse(value) : null;
    } catch (e) {
      debugPrint('Error retrieving session expiry: $e');
      return null;
    }
  }

  /// Check if session has expired
  Future<bool> isSessionExpired() async {
    try {
      final expiryTime = await getSessionExpiry();
      if (expiryTime == null) return true;
      
      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      debugPrint('Error checking session expiry: $e');
      return true; // Assume expired on error
    }
  }

  /// Store authentication tokens together
  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    required String userId,
    bool rememberMe = false,
  }) async {
    try {
      // Set session expiry based on remember me preference
      final expiryDuration = rememberMe 
          ? const Duration(days: 30) // Long-term session
          : const Duration(days: 1);  // Short-term session
      
      final expiryTime = DateTime.now().add(expiryDuration);

      await Future.wait([
        storeAccessToken(accessToken),
        storeUserId(userId),
        setRememberMe(rememberMe),
        storeSessionExpiry(expiryTime),
        if (refreshToken != null) storeRefreshToken(refreshToken),
        storeLastLogin(DateTime.now()),
      ]);
      
      debugPrint('All authentication tokens stored successfully (rememberMe: $rememberMe, expires: $expiryTime)');
    } catch (e) {
      debugPrint('Error storing authentication tokens: $e');
      rethrow;
    }
  }

  /// Check if access token exists
  Future<bool> hasAccessToken() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking access token existence: $e');
      return false;
    }
  }

  /// Check if refresh token exists
  Future<bool> hasRefreshToken() async {
    try {
      final token = await getRefreshToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking refresh token existence: $e');
      return false;
    }
  }

  /// Clear specific token
  Future<void> deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('Token deleted: $key');
    } catch (e) {
      debugPrint('Error deleting token $key: $e');
      rethrow;
    }
  }

  /// Clear access token
  Future<void> clearAccessToken() async {
    await deleteToken(_accessTokenKey);
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    await deleteToken(_refreshTokenKey);
  }

  /// Clear all authentication data
  Future<void> clearAll() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _rememberMeKey),
        _storage.delete(key: _sessionExpiryKey),
        _storage.delete(key: _lastLoginKey),
      ]);
      debugPrint('All authentication data cleared');
    } catch (e) {
      debugPrint('Error clearing authentication data: $e');
      rethrow;
    }
  }

  /// Clear all data except remember me preference
  Future<void> clearAuthenticationData() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _sessionExpiryKey),
        _storage.delete(key: _lastLoginKey),
      ]);
      debugPrint('Authentication data cleared (remember me preserved)');
    } catch (e) {
      debugPrint('Error clearing authentication data: $e');
      rethrow;
    }
  }

  /// Check if any authentication data exists
  Future<bool> hasAuthenticationData() async {
    try {
      final results = await Future.wait([
        hasAccessToken(),
        _storage.containsKey(key: _userIdKey),
      ]);
      return results.any((result) => result);
    } catch (e) {
      debugPrint('Error checking authentication data existence: $e');
      return false;
    }
  }

  /// Get all stored keys (for debugging)
  Future<Map<String, String>> getAllData() async {
    if (kDebugMode) {
      try {
        return await _storage.readAll();
      } catch (e) {
        debugPrint('Error reading all data: $e');
        return {};
      }
    }
    return {};
  }

  /// Check if storage contains a specific key
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('Error checking key existence: $e');
      return false;
    }
  }

  /// Store a generic string value
  Future<void> storeString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('String value stored for key: $key');
    } catch (e) {
      debugPrint('Error storing string value for key $key: $e');
      rethrow;
    }
  }

  /// Get a generic string value
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('Error retrieving string value for key $key: $e');
      return null;
    }
  }

  /// Store a boolean value
  Future<void> storeBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
      debugPrint('Boolean value stored for key: $key');
    } catch (e) {
      debugPrint('Error storing boolean value for key $key: $e');
      rethrow;
    }
  }

  /// Store a boolean value
  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error retrieving boolean value for key $key: $e');
      return null;
    }
  }

  /// Delete a specific key
  Future<void> deleteString(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('Key deleted: $key');
    } catch (e) {
      debugPrint('Error deleting key $key: $e');
      rethrow;
    }
  }

  /// Generate or retrieve encryption key for additional security
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      String? key = await _storage.read(key: _encryptionKeyKey);
      
      if (key == null) {
        // Generate new encryption key
        final bytes = utf8.encode('${DateTime.now().millisecondsSinceEpoch}${_generateRandomString(32)}');
        key = sha256.convert(bytes).toString();
        await _storage.write(key: _encryptionKeyKey, value: key);
        _secureLog('New encryption key generated');
      }
      
      return key;
    } catch (e) {
      _secureLog('Error managing encryption key', isError: true);
      rethrow;
    }
  }

  /// Generate random string for security purposes
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[(random + index) % chars.length]).join();
  }

  /// Secure logging that doesn't expose sensitive information
  void _secureLog(String message, {bool isError = false}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final logLevel = isError ? 'ERROR' : 'INFO';
      debugPrint('[$timestamp] SecureStorage $logLevel: $message');
    }
  }

  /// Enhanced token storage with additional encryption layer
  Future<void> storeTokenSecurely(String key, String token) async {
    try {
      final encryptionKey = await _getOrCreateEncryptionKey();
      final encryptedToken = _encryptToken(token, encryptionKey);
      
      await _storage.write(key: key, value: encryptedToken);
      _secureLog('Token stored securely for key: ${_sanitizeKey(key)}');
    } catch (e) {
      _secureLog('Error storing secure token for key: ${_sanitizeKey(key)}', isError: true);
      rethrow;
    }
  }

  /// Enhanced token retrieval with decryption
  Future<String?> getTokenSecurely(String key) async {
    try {
      final encryptedToken = await _storage.read(key: key);
      if (encryptedToken == null) return null;

      final encryptionKey = await _getOrCreateEncryptionKey();
      return _decryptToken(encryptedToken, encryptionKey);
    } catch (e) {
      _secureLog('Error retrieving secure token for key: ${_sanitizeKey(key)}', isError: true);
      return null;
    }
  }

  /// Simple token encryption (for demonstration - in production use proper encryption library)
  String _encryptToken(String token, String key) {
    // This is a simple XOR encryption for demonstration
    // In production, use a proper encryption library like pointycastle
    final tokenBytes = utf8.encode(token);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];
    
    for (int i = 0; i < tokenBytes.length; i++) {
      encrypted.add(tokenBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  /// Simple token decryption
  String _decryptToken(String encryptedToken, String key) {
    try {
      final encryptedBytes = base64.decode(encryptedToken);
      final keyBytes = utf8.encode(key);
      final decrypted = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      _secureLog('Token decryption failed', isError: true);
      rethrow;
    }
  }

  /// Sanitize key for logging (remove sensitive parts)
  String _sanitizeKey(String key) {
    if (key.length <= 4) return '***';
    return '${key.substring(0, 2)}***${key.substring(key.length - 2)}';
  }

  /// Schedule automatic session cleanup
  Future<void> scheduleSessionCleanup() async {
    try {
      final cleanupTime = DateTime.now().add(const Duration(hours: 24));
      await _storage.write(key: _sessionCleanupKey, value: cleanupTime.toIso8601String());
      _secureLog('Session cleanup scheduled for: $cleanupTime');
    } catch (e) {
      _secureLog('Error scheduling session cleanup', isError: true);
      rethrow;
    }
  }

  /// Check if session cleanup is due
  Future<bool> isSessionCleanupDue() async {
    try {
      final cleanupTimeStr = await _storage.read(key: _sessionCleanupKey);
      if (cleanupTimeStr == null) return false;

      final cleanupTime = DateTime.parse(cleanupTimeStr);
      return DateTime.now().isAfter(cleanupTime);
    } catch (e) {
      _secureLog('Error checking session cleanup status', isError: true);
      return true; // Assume cleanup is due on error
    }
  }

  /// Perform automatic session cleanup
  Future<void> performSessionCleanup() async {
    try {
      _secureLog('Performing automatic session cleanup');
      
      // Clear expired sessions
      final isExpired = await isSessionExpired();
      if (isExpired) {
        await clearAuthenticationData();
        _secureLog('Expired session data cleared');
      }

      // Rotate encryption key if needed
      await _rotateEncryptionKeyIfNeeded();

      // Schedule next cleanup
      await scheduleSessionCleanup();
      
      _secureLog('Session cleanup completed');
    } catch (e) {
      _secureLog('Error during session cleanup', isError: true);
      rethrow;
    }
  }

  /// Rotate encryption key if needed
  Future<void> _rotateEncryptionKeyIfNeeded() async {
    try {
      final lastLogin = await getLastLogin();
      if (lastLogin == null) return;

      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      if (daysSinceLogin >= _keyRotationDays) {
        // Re-encrypt tokens with new key
        final accessToken = await getAccessToken();
        final refreshToken = await getRefreshToken();

        // Delete old encryption key to force generation of new one
        await _storage.delete(key: _encryptionKeyKey);

        // Re-store tokens with new encryption key
        if (accessToken != null) {
          await storeTokenSecurely(_accessTokenKey, accessToken);
        }
        if (refreshToken != null) {
          await storeTokenSecurely(_refreshTokenKey, refreshToken);
        }

        _secureLog('Encryption key rotated successfully');
      }
    } catch (e) {
      _secureLog('Error rotating encryption key', isError: true);
    }
  }

  /// Secure wipe of all authentication data
  Future<void> secureWipeAll() async {
    try {
      _secureLog('Performing secure wipe of all authentication data');

      // Get all keys first
      final allData = await _storage.readAll();
      
      // Overwrite sensitive data multiple times (DoD 5220.22-M standard)
      for (final key in allData.keys) {
        if (_isSensitiveKey(key)) {
          // Overwrite with random data 3 times
          for (int i = 0; i < 3; i++) {
            await _storage.write(key: key, value: _generateRandomString(256));
          }
        }
      }

      // Finally delete all data
      await _storage.deleteAll();
      
      _secureLog('Secure wipe completed');
    } catch (e) {
      _secureLog('Error during secure wipe', isError: true);
      rethrow;
    }
  }

  /// Check if a key contains sensitive information
  bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      _accessTokenKey,
      _refreshTokenKey,
      _userIdKey,
      _encryptionKeyKey,
    ];
    return sensitiveKeys.contains(key);
  }

  /// Get security metrics for monitoring
  Future<Map<String, dynamic>> getSecurityMetrics() async {
    try {
      final hasAuth = await hasAuthenticationData();
      final isExpired = await isSessionExpired();
      final cleanupDue = await isSessionCleanupDue();
      final lastLogin = await getLastLogin();
      
      return {
        'hasAuthenticationData': hasAuth,
        'isSessionExpired': isExpired,
        'isCleanupDue': cleanupDue,
        'lastLoginAge': lastLogin != null 
            ? DateTime.now().difference(lastLogin).inHours 
            : null,
        'storageHealth': 'healthy', // Could be enhanced with more checks
      };
    } catch (e) {
      _secureLog('Error getting security metrics', isError: true);
      return {
        'error': 'Failed to retrieve security metrics',
        'storageHealth': 'error',
      };
    }
  }
}