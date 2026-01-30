import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../services/authentication_service.dart';
import '../services/google_signin_service.dart';
import '../services/session_manager.dart';
import '../services/form_validator.dart' as form_validator;
import '../services/auth_error_handler.dart';
import '../services/offline_auth_handler.dart';
import '../services/api_service.dart' as api;
class AuthenticationProvider extends ChangeNotifier {
  static AuthenticationProvider? _instance;
  static AuthenticationProvider get instance => _instance ??= AuthenticationProvider._();
  AuthenticationProvider._() {
    _initialize();
  }
  final AuthenticationService _authService = AuthenticationService.instance;
  final GoogleSignInService _googleSignInService = GoogleSignInService.instance;
  final SessionManager _sessionManager = SessionManager.instance;
  final AuthErrorHandler _errorHandler = AuthErrorHandler.instance;
  final OfflineAuthHandler _offlineHandler = OfflineAuthHandler.instance;
  final api.ApiService _apiService = api.ApiService();
  AuthenticationState _state = AuthenticationState.unauthenticated;
  User? _currentUser;
  String? _error;
  AuthErrorType? _errorType;
  AuthErrorInfo? _lastErrorInfo;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isOfflineMode = false;
  final form_validator.FormValidationState _formValidationState = form_validator.FormValidationState();
  StreamSubscription<bool>? _sessionStateSubscription;
  StreamSubscription<AuthErrorType>? _sessionErrorSubscription;
  AuthenticationState get state => _state;
  User? get currentUser => _currentUser;
  String? get error => _error;
  AuthErrorType? get errorType => _errorType;
  AuthErrorInfo? get lastErrorInfo => _lastErrorInfo;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthenticationState.authenticated;
  bool get rememberMe => _rememberMe;
  bool get isOfflineMode => _isOfflineMode;
  form_validator.FormValidationState get formValidationState => _formValidationState;
  Future<void> _initialize() async {
    try {
      debugPrint('Initializing authentication provider');
      _sessionStateSubscription = _sessionManager.sessionStateStream.listen(
        _handleSessionStateChange,
        onError: (error) {
          debugPrint('Session state stream error: $error');
          _handleAuthError('Session error occurred', AuthErrorType.sessionTerminated);
        },
      );
      _sessionErrorSubscription = _sessionManager.sessionErrorStream.listen(
        _handleSessionError,
        onError: (error) {
          debugPrint('Session error stream error: $error');
        },
      );
      await _sessionManager.initialize();
      _googleSignInService.initialize();
      await _offlineHandler.initialize();
      debugPrint('Authentication provider initialized');
    } catch (e) {
      debugPrint('Authentication provider initialization error: $e');
      _handleAuthError('Initialization failed', AuthErrorType.unknown);
    }
  }
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('Attempting to sign up user: $email');
      _setLoading(true);
      _clearError();
      final emailError = form_validator.FormValidator.validateEmail(email);
      final passwordError = form_validator.FormValidator.validatePassword(password);
      final nameError = form_validator.FormValidator.validateName(name);
      if (emailError != null || passwordError != null || nameError != null) {
        _handleAuthError(
          emailError ?? passwordError ?? nameError!,
          AuthErrorType.validationError,
        );
        return;
      }
      final result = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      if (result.success && result.user != null && result.accessToken != null) {
        _currentUser = result.user;
        _rememberMe = rememberMe;
        _clearError();
        _apiService.setTokens(result.accessToken!, result.refreshToken ?? '');
        _setState(AuthenticationState.authenticated);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        _startSessionInBackground(result.accessToken!, result.refreshToken, result.user!.id, rememberMe);
        debugPrint('User registration successful: ${result.user!.email}');
      } else {
        _handleAuthErrorWithHandler(
          result.error ?? 'Registration failed',
          result.errorType ?? AuthErrorType.unknown,
          context: 'signup',
        );
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
      _handleAuthErrorWithHandler(e, AuthErrorType.unknown, context: 'signup');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('Attempting to sign in user: $email');
      _setLoading(true);
      _clearError();
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (result.success && result.user != null && result.accessToken != null) {
        _currentUser = result.user;
        _rememberMe = rememberMe;
        _clearError();
        _apiService.setTokens(result.accessToken!, result.refreshToken ?? '');
        _setState(AuthenticationState.authenticated);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        _startSessionInBackground(result.accessToken!, result.refreshToken, result.user!.id, rememberMe);
        debugPrint('User login successful: ${result.user!.email}');
      } else {
        _handleAuthErrorWithHandler(
          result.error ?? 'Login failed',
          result.errorType ?? AuthErrorType.invalidCredentials,
          context: 'login',
        );
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      _handleAuthErrorWithHandler(e, AuthErrorType.unknown, context: 'login');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> signInWithGoogle({bool rememberMe = false}) async {
    try {
      debugPrint('Attempting Google Sign-In');
      _setLoading(true);
      _clearError();
      final result = await _googleSignInService.signInWithGoogle();
      if (result.success && result.user != null && result.accessToken != null) {
        await _sessionManager.startSession(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          userId: result.user!.id,
          rememberMe: rememberMe,
        );
        await _offlineHandler.cacheUserData(result.user!, result.accessToken!);
        _currentUser = result.user;
        _rememberMe = rememberMe;
        _setState(AuthenticationState.authenticated);
        debugPrint('Google Sign-In successful: ${result.user!.email}');
      } else {
        if (result.errorType == AuthErrorType.userCancelled) {
          debugPrint('Google Sign-In cancelled by user - no error shown');
          return;
        }
        if (result.errorType == AuthErrorType.accountExistsWithDifferentCredential) {
          _lastErrorInfo = AuthErrorInfo(
            type: result.errorType!,
            message: result.error!,
            context: 'google_signin',
            metadata: {
              'conflictEmail': result.error?.contains('@') == true 
                  ? result.error!.split(' ').firstWhere((word) => word.contains('@'), orElse: () => '')
                  : '',
              'conflictProvider': 'email',
            },
            isRetryable: false,
            requiresReauthentication: false,
            recoverySuggestions: ['Try signing in with email/password instead'],
            userActions: [],
            errorCount: 1,
            lastOccurrence: DateTime.now(),
          );
        }
        _handleAuthErrorWithHandler(
          result.error ?? 'Google Sign-In failed',
          result.errorType ?? AuthErrorType.googleSignInFailed,
          context: 'google_signin',
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _handleAuthErrorWithHandler(e, AuthErrorType.googleSignInFailed, context: 'google_signin');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> linkGoogleAccount() async {
    try {
      debugPrint('Attempting to link Google account');
      _setLoading(true);
      _clearError();
      if (!isAuthenticated || _currentUser == null) {
        _handleAuthError('Must be signed in to link Google account', AuthErrorType.validationError);
        return;
      }
      final currentToken = await _sessionManager.getValidAccessToken();
      if (currentToken == null) {
        _handleAuthError('Invalid session. Please sign in again.', AuthErrorType.tokenInvalid);
        return;
      }
      final canLink = await _googleSignInService.canLinkGoogleAccount(_currentUser!.email);
      if (!canLink) {
        _handleAuthError(
          'Cannot link Google account. It may already be linked to another account.',
          AuthErrorType.accountExistsWithDifferentCredential,
        );
        return;
      }
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _handleAuthError('Google Sign-In cancelled', AuthErrorType.userCancelled);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _handleAuthError('Failed to get Google authentication tokens', AuthErrorType.googleSignInFailed);
        return;
      }
      final result = await _googleSignInService.linkGoogleAccount(
        currentAccessToken: currentToken,
        googleUser: googleUser,
        googleAccessToken: googleAuth.accessToken!,
        googleIdToken: googleAuth.idToken!,
      );
      if (result.success && result.user != null) {
        _currentUser = result.user;
        await _offlineHandler.cacheUserData(result.user!, currentToken);
        debugPrint('Google account linked successfully: ${result.user!.email}');
      } else {
        _handleAuthErrorWithHandler(
          result.error ?? 'Failed to link Google account',
          result.errorType ?? AuthErrorType.googleSignInFailed,
          context: 'google_account_linking',
        );
      }
    } catch (e) {
      debugPrint('Google account linking error: $e');
      _handleAuthErrorWithHandler(e, AuthErrorType.googleSignInFailed, context: 'google_account_linking');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> mergeGoogleAccount({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('Attempting to merge Google account with existing account: $email');
      _setLoading(true);
      _clearError();
      final emailError = form_validator.FormValidator.validateEmail(email);
      if (emailError != null) {
        _handleAuthError(emailError, AuthErrorType.validationError);
        return;
      }
      if (password.isEmpty) {
        _handleAuthError('Password is required', AuthErrorType.validationError);
        return;
      }
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _handleAuthError('Google Sign-In cancelled', AuthErrorType.userCancelled);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _handleAuthError('Failed to get Google authentication tokens', AuthErrorType.googleSignInFailed);
        return;
      }
      final result = await _googleSignInService.mergeGoogleAccount(
        email: email,
        password: password,
        googleUser: googleUser,
        googleAccessToken: googleAuth.accessToken!,
        googleIdToken: googleAuth.idToken!,
      );
      if (result.success && result.user != null && result.accessToken != null) {
        await _sessionManager.startSession(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          userId: result.user!.id,
          rememberMe: rememberMe,
        );
        await _offlineHandler.cacheUserData(result.user!, result.accessToken!);
        _currentUser = result.user;
        _rememberMe = rememberMe;
        _setState(AuthenticationState.authenticated);
        debugPrint('Google account merged successfully: ${result.user!.email}');
      } else {
        _handleAuthErrorWithHandler(
          result.error ?? 'Failed to merge Google account',
          result.errorType ?? AuthErrorType.googleSignInFailed,
          context: 'google_account_merging',
        );
      }
    } catch (e) {
      debugPrint('Google account merging error: $e');
      _handleAuthErrorWithHandler(e, AuthErrorType.googleSignInFailed, context: 'google_account_merging');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> signUpWithGoogle({bool rememberMe = false}) async {
    await signInWithGoogle(rememberMe: rememberMe);
  }
  Future<void> signOut() async {
    try {
      debugPrint('Attempting to sign out user');
      _setLoading(true);
      _clearError();
      final isGoogleUser = _currentUser?.provider == AuthProvider.google;
      await _authService.signOut();
      if (isGoogleUser) {
        await _googleSignInService.signOut();
      }
      await _sessionManager.endSession();
      await _offlineHandler.clearCachedData();
      _apiService.clearTokens();
      _currentUser = null;
      _rememberMe = false;
      _isOfflineMode = false;
      _setState(AuthenticationState.unauthenticated);
      _formValidationState.clear();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      _currentUser = null;
      _rememberMe = false;
      _isOfflineMode = false;
      _setState(AuthenticationState.unauthenticated);
      _formValidationState.clear();
    } finally {
      _setLoading(false);
    }
  }
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('Attempting to reset password for: $email');
      _setLoading(true);
      _clearError();
      final emailError = form_validator.FormValidator.validateEmail(email);
      if (emailError != null) {
        _handleAuthErrorWithHandler(emailError, AuthErrorType.validationError, context: 'password_reset');
        return;
      }
      final result = await _authService.requestPasswordReset(email);
      if (!result.success) {
        _handleAuthErrorWithHandler(
          result.error ?? 'Password reset failed',
          result.errorType ?? AuthErrorType.unknown,
          context: 'password_reset',
        );
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      _handleAuthErrorWithHandler(e, AuthErrorType.unknown, context: 'password_reset');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> checkAuthenticationStatus() async {
    try {
      debugPrint('Checking authentication status');
      _setLoading(true);
      _isOfflineMode = _offlineHandler.isOfflineMode;
      final isValid = await _sessionManager.isSessionValid();
      if (isValid) {
        final result = await _authService.getCurrentUser();
        if (result.success && result.user != null) {
          await _offlineHandler.cacheUserData(result.user!, result.accessToken!);
          _currentUser = result.user;
          _setState(AuthenticationState.authenticated);
          debugPrint('Authentication status: authenticated as ${result.user!.email}');
          return;
        }
      }
      if (await _offlineHandler.isOfflineAuthAvailable()) {
        final offlineResult = await _offlineHandler.authenticateOffline();
        if (offlineResult.success && offlineResult.user != null) {
          _currentUser = offlineResult.user;
          _isOfflineMode = true;
          _setState(AuthenticationState.authenticated);
          debugPrint('Authentication status: authenticated offline as ${offlineResult.user!.email}');
          return;
        }
      }
      final googleResult = await _googleSignInService.signInSilently();
      if (googleResult != null && googleResult.success && googleResult.user != null) {
        await _sessionManager.startSession(
          accessToken: googleResult.accessToken!,
          refreshToken: googleResult.refreshToken,
          userId: googleResult.user!.id,
          rememberMe: true, // Silent sign-in implies remember me
        );
        await _offlineHandler.cacheUserData(googleResult.user!, googleResult.accessToken!);
        _currentUser = googleResult.user;
        _rememberMe = true;
        _setState(AuthenticationState.authenticated);
        debugPrint('Authentication status: authenticated via Google as ${googleResult.user!.email}');
        return;
      }
      _setState(AuthenticationState.unauthenticated);
      debugPrint('Authentication status: unauthenticated');
    } catch (e) {
      debugPrint('Authentication status check error: $e');
      _setState(AuthenticationState.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }
  Future<bool> isGooglePlayServicesAvailable() async {
    return await _googleSignInService.isGooglePlayServicesAvailable();
  }
  void updateFormField(String fieldName, String value) {
    form_validator.ValidationResult result;
    switch (fieldName) {
      case 'email':
        result = form_validator.FormValidator.validateEmailRealTime(value);
        break;
      case 'password':
        result = form_validator.FormValidator.validatePasswordRealTime(value);
        break;
      case 'name':
        result = form_validator.FormValidator.validateNameRealTime(value);
        break;
      case 'confirmPassword':
        final password = _formValidationState.getFieldValue('password') ?? '';
        final error = form_validator.FormValidator.validateConfirmPassword(password, value);
        result = form_validator.ValidationResult(
          isValid: error == null,
          message: error,
          showError: value.isNotEmpty,
        );
        break;
      default:
        result = form_validator.ValidationResult(isValid: true, showError: false);
        break;
    }
    _formValidationState.updateField(fieldName, value, result);
    notifyListeners();
  }
  void clearFormValidation() {
    _formValidationState.clear();
    notifyListeners();
  }
  void clearError() {
    _clearError();
    notifyListeners();
  }
  void setRememberMe(bool remember) {
    _rememberMe = remember;
    notifyListeners();
  }
  void _handleSessionStateChange(bool isActive) {
    debugPrint('Session state changed: $isActive');
    if (!isActive && _state == AuthenticationState.authenticated) {
      _currentUser = null;
      _setState(AuthenticationState.unauthenticated);
      _clearError();
    }
  }
  void _handleSessionError(AuthErrorType errorType) {
    debugPrint('Session error: $errorType');
    _handleAuthError(errorType.message, errorType);
    if (errorType.requiresReauthentication) {
      _currentUser = null;
      _setState(AuthenticationState.unauthenticated);
    }
  }
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  void _setState(AuthenticationState newState) {
    debugPrint('Setting authentication state from $_state to $newState');
    if (_state != newState) {
      _state = newState;
      debugPrint('Authentication state changed to $_state, notifying listeners');
      notifyListeners();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        debugPrint('Post-frame callback: Authentication state is $_state, isAuthenticated: $isAuthenticated');
        notifyListeners();
      });
    } else {
      debugPrint('Authentication state unchanged: $_state');
    }
  }
  void _handleAuthError(String error, AuthErrorType errorType) {
    _error = error;
    _errorType = errorType;
    _setState(AuthenticationState.error);
    debugPrint('Authentication error: $error ($errorType)');
  }
  void _handleAuthErrorWithHandler(
    dynamic error,
    AuthErrorType errorType, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final errorInfo = _errorHandler.handleAuthError(
      error,
      errorType: errorType,
      context: context,
      metadata: metadata,
    );
    _lastErrorInfo = errorInfo;
    if (_errorHandler.shouldShowError(errorType)) {
      _error = errorInfo.message;
      _errorType = errorInfo.type;
      _setState(AuthenticationState.error);
      debugPrint('Authentication error handled: ${errorInfo.message} (${errorInfo.type})');
    } else {
      debugPrint('Authentication error handled but not shown: ${errorInfo.message} (${errorInfo.type})');
    }
  }
  Future<T> retryOperation<T>(
    Future<T> Function() operation,
    AuthErrorType errorType, {
    String? context,
  }) async {
    return await _errorHandler.executeWithRetry(
      operation,
      errorType,
      context: context,
    );
  }
  Map<String, dynamic> getOfflineStatus() {
    return _offlineHandler.getOfflineStatus();
  }
  Future<void> onConnectivityChanged(bool isConnected) async {
    await _offlineHandler.onConnectivityChanged(isConnected);
    _isOfflineMode = _offlineHandler.isOfflineMode;
    notifyListeners();
  }
  void _clearError() {
    _error = null;
    _errorType = null;
    _lastErrorInfo = null;
    if (_state == AuthenticationState.error) {
      _setState(_currentUser != null 
          ? AuthenticationState.authenticated 
          : AuthenticationState.unauthenticated);
    }
  }
  void _startSessionInBackground(String accessToken, String? refreshToken, String userId, bool rememberMe) {
    Future.microtask(() async {
      try {
        debugPrint('Starting session in background for user: $userId');
        await _sessionManager.startSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
          rememberMe: rememberMe,
        );
        await _offlineHandler.cacheUserData(_currentUser!, accessToken);
        debugPrint('Background session initialization completed');
      } catch (e) {
        debugPrint('Background session initialization error: $e');
      }
    });
  }
  @override
  void dispose() {
    _sessionStateSubscription?.cancel();
    _sessionErrorSubscription?.cancel();
    _sessionManager.dispose();
    _offlineHandler.dispose();
    super.dispose();
  }
}