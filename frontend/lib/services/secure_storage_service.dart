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
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _lastLoginKey = 'last_login';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _sessionCleanupKey = 'session_cleanup';
  static const int _keyRotationDays = 30;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  Future<void> storeAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      debugPrint('Access token stored securely');
    } catch (e) {
      debugPrint('Error storing access token: $e');
      rethrow;
    }
  }
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('Error retrieving access token: $e');
      return null;
    }
  }
  Future<void> storeRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      debugPrint('Refresh token stored securely');
    } catch (e) {
      debugPrint('Error storing refresh token: $e');
      rethrow;
    }
  }
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Error retrieving refresh token: $e');
      return null;
    }
  }
  Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      debugPrint('User ID stored securely');
    } catch (e) {
      debugPrint('Error storing user ID: $e');
      rethrow;
    }
  }
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error retrieving user ID: $e');
      return null;
    }
  }
  Future<void> setRememberMe(bool remember) async {
    try {
      await _storage.write(key: _rememberMeKey, value: remember.toString());
      debugPrint('Remember me preference stored: $remember');
    } catch (e) {
      debugPrint('Error storing remember me preference: $e');
      rethrow;
    }
  }
  Future<bool> getRememberMe() async {
    try {
      final value = await _storage.read(key: _rememberMeKey);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error retrieving remember me preference: $e');
      return false;
    }
  }
  Future<void> storeLastLogin(DateTime timestamp) async {
    try {
      await _storage.write(key: _lastLoginKey, value: timestamp.toIso8601String());
      debugPrint('Last login timestamp stored');
    } catch (e) {
      debugPrint('Error storing last login timestamp: $e');
      rethrow;
    }
  }
  Future<DateTime?> getLastLogin() async {
    try {
      final value = await _storage.read(key: _lastLoginKey);
      return value != null ? DateTime.parse(value) : null;
    } catch (e) {
      debugPrint('Error retrieving last login timestamp: $e');
      return null;
    }
  }
  Future<void> storeSessionExpiry(DateTime expiryTime) async {
    try {
      await _storage.write(key: _sessionExpiryKey, value: expiryTime.toIso8601String());
      debugPrint('Session expiry stored: $expiryTime');
    } catch (e) {
      debugPrint('Error storing session expiry: $e');
      rethrow;
    }
  }
  Future<DateTime?> getSessionExpiry() async {
    try {
      final value = await _storage.read(key: _sessionExpiryKey);
      return value != null ? DateTime.parse(value) : null;
    } catch (e) {
      debugPrint('Error retrieving session expiry: $e');
      return null;
    }
  }
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
  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    required String userId,
    bool rememberMe = false,
  }) async {
    try {
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
  Future<bool> hasAccessToken() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking access token existence: $e');
      return false;
    }
  }
  Future<bool> hasRefreshToken() async {
    try {
      final token = await getRefreshToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking refresh token existence: $e');
      return false;
    }
  }
  Future<void> deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('Token deleted: $key');
    } catch (e) {
      debugPrint('Error deleting token $key: $e');
      rethrow;
    }
  }
  Future<void> clearAccessToken() async {
    await deleteToken(_accessTokenKey);
  }
  Future<void> clearRefreshToken() async {
    await deleteToken(_refreshTokenKey);
  }
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
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('Error checking key existence: $e');
      return false;
    }
  }
  Future<void> storeString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('String value stored for key: $key');
    } catch (e) {
      debugPrint('Error storing string value for key $key: $e');
      rethrow;
    }
  }
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('Error retrieving string value for key $key: $e');
      return null;
    }
  }
  Future<void> storeBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
      debugPrint('Boolean value stored for key: $key');
    } catch (e) {
      debugPrint('Error storing boolean value for key $key: $e');
      rethrow;
    }
  }
  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value?.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error retrieving boolean value for key $key: $e');
      return null;
    }
  }
  Future<void> deleteString(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('Key deleted: $key');
    } catch (e) {
      debugPrint('Error deleting key $key: $e');
      rethrow;
    }
  }
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      String? key = await _storage.read(key: _encryptionKeyKey);
      if (key == null) {
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
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[(random + index) % chars.length]).join();
  }
  void _secureLog(String message, {bool isError = false}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final logLevel = isError ? 'ERROR' : 'INFO';
      debugPrint('[$timestamp] SecureStorage $logLevel: $message');
    }
  }
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
  String _encryptToken(String token, String key) {
    final tokenBytes = utf8.encode(token);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];
    for (int i = 0; i < tokenBytes.length; i++) {
      encrypted.add(tokenBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return base64.encode(encrypted);
  }
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
  String _sanitizeKey(String key) {
    if (key.length <= 4) return '***';
    return '${key.substring(0, 2)}***${key.substring(key.length - 2)}';
  }
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
  Future<void> performSessionCleanup() async {
    try {
      _secureLog('Performing automatic session cleanup');
      final isExpired = await isSessionExpired();
      if (isExpired) {
        await clearAuthenticationData();
        _secureLog('Expired session data cleared');
      }
      await _rotateEncryptionKeyIfNeeded();
      await scheduleSessionCleanup();
      _secureLog('Session cleanup completed');
    } catch (e) {
      _secureLog('Error during session cleanup', isError: true);
      rethrow;
    }
  }
  Future<void> _rotateEncryptionKeyIfNeeded() async {
    try {
      final lastLogin = await getLastLogin();
      if (lastLogin == null) return;
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      if (daysSinceLogin >= _keyRotationDays) {
        final accessToken = await getAccessToken();
        final refreshToken = await getRefreshToken();
        await _storage.delete(key: _encryptionKeyKey);
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
  Future<void> secureWipeAll() async {
    try {
      _secureLog('Performing secure wipe of all authentication data');
      final allData = await _storage.readAll();
      for (final key in allData.keys) {
        if (_isSensitiveKey(key)) {
          for (int i = 0; i < 3; i++) {
            await _storage.write(key: key, value: _generateRandomString(256));
          }
        }
      }
      await _storage.deleteAll();
      _secureLog('Secure wipe completed');
    } catch (e) {
      _secureLog('Error during secure wipe', isError: true);
      rethrow;
    }
  }
  bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      _accessTokenKey,
      _refreshTokenKey,
      _userIdKey,
      _encryptionKeyKey,
    ];
    return sensitiveKeys.contains(key);
  }
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