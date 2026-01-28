import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _sessionExpiryKey = 'session_expiry';
  static const String _lastLoginKey = 'last_login';

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

  /// Get a boolean value
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
}