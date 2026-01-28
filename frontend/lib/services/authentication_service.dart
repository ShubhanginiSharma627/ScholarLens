import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/models.dart';
import 'network_service.dart';
import 'secure_storage_service.dart';

class AuthenticationService {
  static AuthenticationService? _instance;
  static AuthenticationService get instance => _instance ??= AuthenticationService._();

  AuthenticationService._();

  final SecureStorageService _secureStorage = SecureStorageService();
  final NetworkService _networkService = NetworkService.instance;

  // Backend API configuration
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  static const String _registerEndpoint = '/auth/register';
  static const String _loginEndpoint = '/auth/login';
  static const String _logoutEndpoint = '/auth/logout';
  static const String _profileEndpoint = '/auth/profile';
  static const String _refreshEndpoint = '/auth/refresh';
  static const String _passwordResetEndpoint = '/auth/password-reset';

  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('Attempting to register user with email: $email');

      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_registerEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
            'name': name,
          }),
        ).timeout(_requestTimeout);
      });

      return await _handleAuthResponse(response, 'Registration');
    } catch (e) {
      debugPrint('Registration error: $e');
      return _handleAuthError(e);
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to sign in user with email: $email');

      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_loginEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        ).timeout(_requestTimeout);
      });

      return await _handleAuthResponse(response, 'Login');
    } catch (e) {
      debugPrint('Login error: $e');
      return _handleAuthError(e);
    }
  }

  /// Sign out the current user
  Future<AuthResult> signOut() async {
    try {
      debugPrint('Attempting to sign out user');

      // Get current token for logout request
      final token = await _secureStorage.getAccessToken();
      
      if (token != null) {
        try {
          // Attempt to notify backend of logout
          await _networkService.retryOperation(() async {
            return await http.post(
              Uri.parse('$_baseUrl$_logoutEndpoint'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ).timeout(_requestTimeout);
          });
        } catch (e) {
          // Don't fail logout if backend request fails
          debugPrint('Backend logout request failed: $e');
        }
      }

      // Always clear local storage regardless of backend response
      await _secureStorage.clearAuthenticationData();
      debugPrint('User signed out successfully');

      return AuthResult.success(
        user: User(
          id: '',
          email: '',
          name: '',
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: false,
        ),
        accessToken: '',
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      return _handleAuthError(e);
    }
  }

  /// Get current user profile
  Future<AuthResult> getCurrentUser() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null) {
        return AuthResult.failure(
          error: 'No authentication token found',
          errorType: AuthErrorType.tokenInvalid,
        );
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        debugPrint('Access token expired, attempting refresh');
        final refreshResult = await refreshToken();
        if (!refreshResult.success) {
          return refreshResult;
        }
        // Use the new token
        final newToken = refreshResult.accessToken!;
        
        return await _fetchUserProfile(newToken);
      }

      return await _fetchUserProfile(token);
    } catch (e) {
      debugPrint('Get current user error: $e');
      return _handleAuthError(e);
    }
  }

  /// Refresh the access token
  Future<AuthResult> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure(
          error: 'No refresh token found',
          errorType: AuthErrorType.refreshTokenExpired,
        );
      }

      debugPrint('Attempting to refresh access token');

      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_refreshEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        ).timeout(_requestTimeout);
      });

      return await _handleAuthResponse(response, 'Token refresh');
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return _handleAuthError(e);
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null) return false;

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        // Try to refresh token
        final refreshResult = await refreshToken();
        return refreshResult.success;
      }

      return true;
    } catch (e) {
      debugPrint('Authentication check error: $e');
      return false;
    }
  }

  /// Request password reset
  Future<AuthResult> requestPasswordReset(String email) async {
    try {
      debugPrint('Requesting password reset for email: $email');

      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_passwordResetEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
          }),
        ).timeout(_requestTimeout);
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('Password reset request successful for: $email');
          return AuthResult.success(
            user: User(
              id: '',
              email: email,
              name: '',
              provider: AuthProvider.email,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              isEmailVerified: false,
            ),
            accessToken: '',
          );
        } else {
          return AuthResult.failure(
            error: data['error'] ?? 'Password reset request failed',
            errorType: _mapErrorType(data['error']),
          );
        }
      } else {
        return _handleHttpError(response, 'Password reset request');
      }
    } catch (e) {
      debugPrint('Password reset request error: $e');
      return _handleAuthError(e);
    }
  }

  /// Get stored authentication token
  Future<String?> getStoredToken() async {
    return await _secureStorage.getAccessToken();
  }

  /// Fetch user profile from backend
  Future<AuthResult> _fetchUserProfile(String token) async {
    try {
      final response = await _networkService.retryOperation(() async {
        return await http.get(
          Uri.parse('$_baseUrl$_profileEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(_requestTimeout);
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final user = User.fromJson(data['data']);
          return AuthResult.success(user: user, accessToken: token);
        } else {
          return AuthResult.failure(
            error: data['error'] ?? 'Failed to fetch user profile',
            errorType: AuthErrorType.serverError,
          );
        }
      } else {
        return _handleHttpError(response, 'Profile fetch');
      }
    } catch (e) {
      debugPrint('Fetch user profile error: $e');
      return _handleAuthError(e);
    }
  }

  /// Handle authentication response from backend
  Future<AuthResult> _handleAuthResponse(http.Response response, String operation) async {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true && data['data'] != null) {
          final userData = data['data'];
          final user = User.fromJson(userData);
          final token = userData['token'] as String;

          // Store authentication data
          await _secureStorage.storeTokens(
            accessToken: token,
            userId: user.id,
          );

          debugPrint('$operation successful for user: ${user.email}');
          return AuthResult.success(user: user, accessToken: token);
        } else {
          return AuthResult.failure(
            error: data['error'] ?? '$operation failed',
            errorType: _mapErrorType(data['error']),
          );
        }
      } else {
        return _handleHttpError(response, operation);
      }
    } catch (e) {
      debugPrint('$operation response parsing error: $e');
      return AuthResult.failure(
        error: 'Failed to process server response',
        errorType: AuthErrorType.serverError,
      );
    }
  }

  /// Handle HTTP error responses
  AuthResult _handleHttpError(http.Response response, String operation) {
    try {
      final data = jsonDecode(response.body);
      final errorMessage = data['error'] ?? 'Unknown server error';
      
      AuthErrorType errorType;
      switch (response.statusCode) {
        case 400:
          errorType = _mapErrorType(errorMessage);
          break;
        case 401:
          errorType = AuthErrorType.invalidCredentials;
          break;
        case 404:
          errorType = AuthErrorType.userNotFound;
          break;
        case 409:
          errorType = AuthErrorType.emailAlreadyExists;
          break;
        case 500:
        default:
          errorType = AuthErrorType.serverError;
          break;
      }

      debugPrint('$operation HTTP error ${response.statusCode}: $errorMessage');
      return AuthResult.failure(error: errorMessage, errorType: errorType);
    } catch (e) {
      debugPrint('$operation HTTP error parsing failed: $e');
      return AuthResult.failure(
        error: 'Server error (${response.statusCode})',
        errorType: AuthErrorType.serverError,
      );
    }
  }

  /// Handle authentication errors
  AuthResult _handleAuthError(dynamic error) {
    final networkError = _networkService.detectNetworkError(error);
    
    AuthErrorType errorType;
    String errorMessage;

    switch (networkError.type) {
      case NetworkErrorType.timeout:
        errorType = AuthErrorType.networkError;
        errorMessage = 'Request timed out. Please try again.';
        break;
      case NetworkErrorType.noConnection:
        errorType = AuthErrorType.networkError;
        errorMessage = 'No internet connection. Please check your network.';
        break;
      case NetworkErrorType.serverError:
        errorType = AuthErrorType.serverError;
        errorMessage = 'Server error. Please try again later.';
        break;
      default:
        errorType = AuthErrorType.unknown;
        errorMessage = 'An unexpected error occurred. Please try again.';
        break;
    }

    return AuthResult.failure(error: errorMessage, errorType: errorType);
  }

  /// Map backend error messages to error types
  AuthErrorType _mapErrorType(String? errorMessage) {
    if (errorMessage == null) return AuthErrorType.unknown;

    final message = errorMessage.toLowerCase();
    
    if (message.contains('already exists') || message.contains('duplicate')) {
      return AuthErrorType.emailAlreadyExists;
    } else if (message.contains('invalid') && message.contains('password')) {
      return AuthErrorType.invalidCredentials;
    } else if (message.contains('invalid') && message.contains('email')) {
      return AuthErrorType.invalidEmail;
    } else if (message.contains('weak') && message.contains('password')) {
      return AuthErrorType.weakPassword;
    } else if (message.contains('not found')) {
      return AuthErrorType.userNotFound;
    } else if (message.contains('required')) {
      return AuthErrorType.validationError;
    } else {
      return AuthErrorType.unknown;
    }
  }
}