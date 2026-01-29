import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'network_service.dart';
import 'secure_storage_service.dart';

class GoogleSignInService {
  static GoogleSignInService? _instance;
  static GoogleSignInService get instance => _instance ??= GoogleSignInService._();

  GoogleSignInService._();

  final SecureStorageService _secureStorage = SecureStorageService();
  final NetworkService _networkService = NetworkService.instance;

  // Google Sign-In configuration
  late final GoogleSignIn _googleSignIn;
  
  // Backend API configuration
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://scholarlens-afvx.onrender.com/api',
  );
  static const String _googleAuthEndpoint = '/auth/google';
  static const String _linkAccountEndpoint = '/auth/link-google';
  static const String _checkAccountEndpoint = '/auth/check-account';
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Initialize Google Sign-In service
  void initialize({
    List<String> scopes = const ['email'],
    String? hostedDomain,
  }) {
    _googleSignIn = GoogleSignIn(
      scopes: scopes,
    );
    
    debugPrint('Google Sign-In service initialized');
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('Attempting Google Sign-In');

      // Check if Google Sign-In is initialized
      if (!_isInitialized) {
        initialize(); // Initialize with default settings
      }

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in - this is normal behavior, not an error
        debugPrint('Google Sign-In cancelled by user');
        return AuthResult.failure(
          error: 'Sign-in cancelled',
          errorType: AuthErrorType.userCancelled,
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('Failed to get Google authentication tokens');
        return AuthResult.failure(
          error: 'Failed to authenticate with Google',
          errorType: AuthErrorType.googleSignInFailed,
        );
      }

      debugPrint('Google Sign-In successful, checking for existing accounts');

      // Check if account exists with different provider
      final accountCheckResult = await _checkExistingAccount(googleUser.email);
      
      if (accountCheckResult.hasConflict) {
        debugPrint('Account exists with different provider: ${googleUser.email}');
        return AuthResult.failure(
          error: 'An account with this email already exists. Please sign in with your original method or contact support to merge accounts.',
          errorType: AuthErrorType.accountExistsWithDifferentCredential,
        );
      }

      // Authenticate with backend using Google tokens
      return await _authenticateWithBackend(
        googleUser: googleUser,
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return _handleGoogleSignInError(e);
    }
  }

  /// Sign out from Google
  Future<AuthResult> signOut() async {
    try {
      debugPrint('Attempting Google Sign-Out');

      if (_isInitialized) {
        await _googleSignIn.signOut();
      }

      // Clear stored authentication data
      await _secureStorage.clearAuthenticationData();
      
      debugPrint('Google Sign-Out successful');
      
      return AuthResult.success(
        user: User(
          id: '',
          email: '',
          name: '',
          provider: AuthProvider.google,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: true, // Google accounts are always verified
        ),
        accessToken: '',
      );
    } catch (e) {
      debugPrint('Google Sign-Out error: $e');
      return _handleGoogleSignInError(e);
    }
  }

  /// Disconnect from Google (revoke access)
  Future<AuthResult> disconnect() async {
    try {
      debugPrint('Attempting Google disconnect');

      if (_isInitialized) {
        await _googleSignIn.disconnect();
      }

      // Clear stored authentication data
      await _secureStorage.clearAuthenticationData();
      
      debugPrint('Google disconnect successful');
      
      return AuthResult.success(
        user: User(
          id: '',
          email: '',
          name: '',
          provider: AuthProvider.google,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: true,
        ),
        accessToken: '',
      );
    } catch (e) {
      debugPrint('Google disconnect error: $e');
      return _handleGoogleSignInError(e);
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    try {
      if (!_isInitialized) return false;
      
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      debugPrint('Google Sign-In status check error: $e');
      return false;
    }
  }

  /// Get current Google user
  GoogleSignInAccount? get currentUser {
    if (!_isInitialized) return null;
    return _googleSignIn.currentUser;
  }

  /// Check if Google Sign-In is initialized
  bool get _isInitialized => _googleSignIn != null;

  /// Authenticate with backend using Google tokens
  Future<AuthResult> _authenticateWithBackend({
    required GoogleSignInAccount googleUser,
    required String accessToken,
    required String idToken,
  }) async {
    try {
      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_googleAuthEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'accessToken': accessToken,
            'idToken': idToken,
            'email': googleUser.email,
            'name': googleUser.displayName ?? '',
            'photoUrl': googleUser.photoUrl,
            'provider': 'google',
          }),
        ).timeout(_requestTimeout);
      });

      return await _handleAuthResponse(response, googleUser);
    } catch (e) {
      debugPrint('Backend authentication error: $e');
      return _handleGoogleSignInError(e);
    }
  }

  /// Handle authentication response from backend
  Future<AuthResult> _handleAuthResponse(
    http.Response response,
    GoogleSignInAccount googleUser,
  ) async {
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

          debugPrint('Google authentication successful for user: ${user.email}');
          return AuthResult.success(user: user, accessToken: token);
        } else {
          return AuthResult.failure(
            error: data['error'] ?? 'Google authentication failed',
            errorType: _mapErrorType(data['error']),
          );
        }
      } else {
        return _handleHttpError(response);
      }
    } catch (e) {
      debugPrint('Google authentication response parsing error: $e');
      return AuthResult.failure(
        error: 'Failed to process server response',
        errorType: AuthErrorType.serverError,
      );
    }
  }

  /// Handle HTTP error responses
  AuthResult _handleHttpError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final errorMessage = data['error'] ?? 'Unknown server error';
      
      AuthErrorType errorType;
      switch (response.statusCode) {
        case 400:
          errorType = _mapErrorType(errorMessage);
          break;
        case 401:
          errorType = AuthErrorType.googleSignInFailed;
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

      debugPrint('Google authentication HTTP error ${response.statusCode}: $errorMessage');
      return AuthResult.failure(error: errorMessage, errorType: errorType);
    } catch (e) {
      debugPrint('Google authentication HTTP error parsing failed: $e');
      return AuthResult.failure(
        error: 'Server error (${response.statusCode})',
        errorType: AuthErrorType.serverError,
      );
    }
  }

  /// Handle Google Sign-In errors
  AuthResult _handleGoogleSignInError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    AuthErrorType errorType;
    String errorMessage;

    if (errorString.contains('network_error') || errorString.contains('timeout')) {
      errorType = AuthErrorType.networkError;
      errorMessage = 'Network error. Please check your connection and try again.';
    } else if (errorString.contains('sign_in_cancelled') || errorString.contains('cancelled')) {
      errorType = AuthErrorType.userCancelled;
      errorMessage = 'Sign-in cancelled';
    } else if (errorString.contains('sign_in_failed')) {
      errorType = AuthErrorType.googleSignInFailed;
      errorMessage = 'Google Sign-In failed. Please try again.';
    } else if (errorString.contains('account_exists_with_different_credential')) {
      errorType = AuthErrorType.accountExistsWithDifferentCredential;
      errorMessage = 'An account already exists with this email using a different sign-in method.';
    } else {
      // Check for network errors using NetworkService
      final networkError = _networkService.detectNetworkError(error);
      
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
          errorType = AuthErrorType.googleSignInFailed;
          errorMessage = 'Google Sign-In failed. Please try again.';
          break;
      }
    }

    return AuthResult.failure(error: errorMessage, errorType: errorType);
  }

  /// Map backend error messages to error types
  AuthErrorType _mapErrorType(String? errorMessage) {
    if (errorMessage == null) return AuthErrorType.googleSignInFailed;

    final message = errorMessage.toLowerCase();
    
    if (message.contains('already exists') || message.contains('duplicate')) {
      return AuthErrorType.emailAlreadyExists;
    } else if (message.contains('invalid') && message.contains('token')) {
      return AuthErrorType.googleSignInFailed;
    } else if (message.contains('not found')) {
      return AuthErrorType.userNotFound;
    } else if (message.contains('required')) {
      return AuthErrorType.validationError;
    } else {
      return AuthErrorType.googleSignInFailed;
    }
  }

  /// Get user profile information from Google account
  Map<String, dynamic>? getUserProfile() {
    final user = currentUser;
    if (user == null) return null;

    return {
      'id': user.id,
      'email': user.email,
      'name': user.displayName ?? '',
      'photoUrl': user.photoUrl,
      'provider': 'google',
    };
  }

  /// Check if Google Play Services are available (Android only)
  Future<bool> isGooglePlayServicesAvailable() async {
    try {
      if (!_isInitialized) return false;
      
      // This will throw an exception if Google Play Services are not available
      await _googleSignIn.isSignedIn();
      return true;
    } catch (e) {
      debugPrint('Google Play Services check error: $e');
      return false;
    }
  }

  /// Silently sign in if user was previously signed in
  Future<AuthResult?> signInSilently() async {
    try {
      if (!_isInitialized) {
        initialize(); // Initialize with default settings
      }

      debugPrint('Attempting silent Google Sign-In');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      if (googleUser == null) {
        debugPrint('Silent Google Sign-In failed - no previous session');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('Silent Google Sign-In failed - no tokens');
        return null;
      }

      debugPrint('Silent Google Sign-In successful, authenticating with backend');

      // Authenticate with backend using Google tokens
      return await _authenticateWithBackend(
        googleUser: googleUser,
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

    } catch (e) {
      debugPrint('Silent Google Sign-In error: $e');
      return null; // Silent sign-in should not throw errors
    }
  }

  /// Check if an account exists with a different provider
  Future<AccountCheckResult> _checkExistingAccount(String email) async {
    try {
      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_checkAccountEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'provider': 'google',
          }),
        ).timeout(_requestTimeout);
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AccountCheckResult(
          exists: data['exists'] ?? false,
          provider: data['provider'],
          hasConflict: data['hasConflict'] ?? false,
          canMerge: data['canMerge'] ?? false,
        );
      } else {
        debugPrint('Account check failed: ${response.statusCode}');
        return AccountCheckResult(exists: false, hasConflict: false, canMerge: false);
      }
    } catch (e) {
      debugPrint('Account check error: $e');
      return AccountCheckResult(exists: false, hasConflict: false, canMerge: false);
    }
  }

  /// Link Google account to existing user account
  Future<AuthResult> linkGoogleAccount({
    required String currentAccessToken,
    required GoogleSignInAccount googleUser,
    required String googleAccessToken,
    required String googleIdToken,
  }) async {
    try {
      debugPrint('Attempting to link Google account: ${googleUser.email}');

      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_linkAccountEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $currentAccessToken',
          },
          body: jsonEncode({
            'googleAccessToken': googleAccessToken,
            'googleIdToken': googleIdToken,
            'email': googleUser.email,
            'name': googleUser.displayName ?? '',
            'photoUrl': googleUser.photoUrl,
            'provider': 'google',
          }),
        ).timeout(_requestTimeout);
      });

      return await _handleAuthResponse(response, googleUser);
    } catch (e) {
      debugPrint('Google account linking error: $e');
      return _handleGoogleSignInError(e);
    }
  }

  /// Merge Google account with existing email account
  Future<AuthResult> mergeGoogleAccount({
    required String email,
    required String password,
    required GoogleSignInAccount googleUser,
    required String googleAccessToken,
    required String googleIdToken,
  }) async {
    try {
      debugPrint('Attempting to merge Google account with existing account: $email');

      final response = await _networkService.retryOperation(() async {
        return await http.post(
          Uri.parse('$_baseUrl$_googleAuthEndpoint'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'accessToken': googleAccessToken,
            'idToken': googleIdToken,
            'email': googleUser.email,
            'name': googleUser.displayName ?? '',
            'photoUrl': googleUser.photoUrl,
            'provider': 'google',
            'mergeWith': {
              'email': email,
              'password': password,
            },
          }),
        ).timeout(_requestTimeout);
      });

      return await _handleAuthResponse(response, googleUser);
    } catch (e) {
      debugPrint('Google account merging error: $e');
      return _handleGoogleSignInError(e);
    }
  }

  /// Check if current user can link Google account
  Future<bool> canLinkGoogleAccount(String currentUserEmail) async {
    try {
      // Get current Google user if signed in
      final googleUser = currentUser;
      if (googleUser == null) return true; // No Google account signed in, can link

      // Check if the Google account email matches current user email
      if (googleUser.email == currentUserEmail) {
        return true; // Same email, can link
      }

      // Check if Google account is already linked to another account
      final accountCheck = await _checkExistingAccount(googleUser.email);
      return !accountCheck.hasConflict;
    } catch (e) {
      debugPrint('Can link Google account check error: $e');
      return false;
    }
  }
}

/// Result of checking if an account exists
class AccountCheckResult {
  final bool exists;
  final String? provider;
  final bool hasConflict;
  final bool canMerge;

  AccountCheckResult({
    required this.exists,
    this.provider,
    required this.hasConflict,
    required this.canMerge,
  });
}