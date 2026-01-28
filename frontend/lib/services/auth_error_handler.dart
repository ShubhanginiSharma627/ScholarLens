import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import 'network_service.dart';

class AuthErrorHandler {
  static AuthErrorHandler? _instance;
  static AuthErrorHandler get instance => _instance ??= AuthErrorHandler._();

  AuthErrorHandler._();

  final NetworkService _networkService = NetworkService.instance;

  // Error tracking
  final Map<AuthErrorType, int> _errorCounts = {};
  final Map<AuthErrorType, DateTime> _lastErrorTimes = {};
  
  // Retry configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _errorCooldownPeriod = Duration(minutes: 5);

  /// Handle authentication error with user-friendly messaging and recovery options
  AuthErrorInfo handleAuthError(
    dynamic error, {
    AuthErrorType? errorType,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    debugPrint('Handling auth error: $error (type: $errorType, context: $context)');

    // Determine error type if not provided
    final resolvedErrorType = errorType ?? _determineErrorType(error);
    
    // Track error occurrence
    _trackError(resolvedErrorType);

    // Get user-friendly error information
    final errorInfo = _getErrorInfo(resolvedErrorType, error, context, metadata);

    // Log error for debugging (without sensitive information)
    _logError(errorInfo, error, metadata);

    return errorInfo;
  }

  /// Handle network-specific authentication errors
  AuthErrorInfo handleNetworkError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    debugPrint('Handling network error: $error (context: $context)');

    final networkError = _networkService.detectNetworkError(error);
    AuthErrorType errorType;

    switch (networkError.type) {
      case NetworkErrorType.timeout:
        errorType = AuthErrorType.networkError;
        break;
      case NetworkErrorType.noConnection:
        errorType = AuthErrorType.networkError;
        break;
      case NetworkErrorType.serverError:
        errorType = AuthErrorType.serverError;
        break;
      default:
        errorType = AuthErrorType.unknown;
        break;
    }

    return handleAuthError(
      error,
      errorType: errorType,
      context: context,
      metadata: {
        ...?metadata,
        'networkErrorType': networkError.type.toString(),
        'isRetryable': networkError.isRetryable,
      },
    );
  }

  /// Get retry configuration for an error type
  RetryConfig getRetryConfig(AuthErrorType errorType) {
    switch (errorType) {
      case AuthErrorType.networkError:
      case AuthErrorType.serverError:
        return RetryConfig(
          maxAttempts: _maxRetryAttempts,
          delay: _retryDelay,
          backoffMultiplier: 2.0,
          maxDelay: const Duration(seconds: 30),
        );
      case AuthErrorType.tokenExpired:
      case AuthErrorType.refreshTokenExpired:
        return RetryConfig(
          maxAttempts: 1,
          delay: const Duration(milliseconds: 500),
          backoffMultiplier: 1.0,
          maxDelay: const Duration(seconds: 1),
        );
      default:
        return RetryConfig(
          maxAttempts: 0,
          delay: Duration.zero,
          backoffMultiplier: 1.0,
          maxDelay: Duration.zero,
        );
    }
  }

  /// Execute operation with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    AuthErrorType errorType, {
    String? context,
  }) async {
    final retryConfig = getRetryConfig(errorType);
    
    if (retryConfig.maxAttempts == 0) {
      return await operation();
    }

    int attempts = 0;
    Duration currentDelay = retryConfig.delay;

    while (attempts < retryConfig.maxAttempts) {
      try {
        attempts++;
        debugPrint('Executing operation (attempt $attempts/${retryConfig.maxAttempts})');
        
        return await operation();
      } catch (error) {
        debugPrint('Operation failed (attempt $attempts): $error');
        
        if (attempts >= retryConfig.maxAttempts) {
          debugPrint('Max retry attempts reached, throwing error');
          rethrow;
        }

        // Check if error is retryable
        final errorInfo = handleAuthError(error, context: context);
        if (!errorInfo.isRetryable) {
          debugPrint('Error is not retryable, throwing error');
          rethrow;
        }

        // Wait before retry
        debugPrint('Waiting ${currentDelay.inMilliseconds}ms before retry');
        await Future.delayed(currentDelay);
        
        // Increase delay for next attempt (exponential backoff)
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * retryConfig.backoffMultiplier).round(),
        );
        
        if (currentDelay > retryConfig.maxDelay) {
          currentDelay = retryConfig.maxDelay;
        }
      }
    }

    throw StateError('Retry logic error - should not reach here');
  }

  /// Check if error should be shown to user (avoid spam)
  bool shouldShowError(AuthErrorType errorType) {
    final lastErrorTime = _lastErrorTimes[errorType];
    if (lastErrorTime == null) return true;

    final timeSinceLastError = DateTime.now().difference(lastErrorTime);
    return timeSinceLastError > _errorCooldownPeriod;
  }

  /// Get error statistics for debugging
  Map<String, dynamic> getErrorStatistics() {
    return {
      'errorCounts': Map.from(_errorCounts),
      'lastErrorTimes': _lastErrorTimes.map(
        (key, value) => MapEntry(key.toString(), value.toIso8601String()),
      ),
    };
  }

  /// Clear error statistics
  void clearErrorStatistics() {
    _errorCounts.clear();
    _lastErrorTimes.clear();
    debugPrint('Error statistics cleared');
  }

  /// Determine error type from exception
  AuthErrorType _determineErrorType(dynamic error) {
    if (error == null) return AuthErrorType.unknown;

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return AuthErrorType.networkError;
    }

    // HTTP errors
    if (errorString.contains('http')) {
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        return AuthErrorType.invalidCredentials;
      } else if (errorString.contains('404') || errorString.contains('not found')) {
        return AuthErrorType.userNotFound;
      } else if (errorString.contains('409') || errorString.contains('conflict')) {
        return AuthErrorType.emailAlreadyExists;
      } else if (errorString.contains('500') || errorString.contains('server')) {
        return AuthErrorType.serverError;
      }
    }

    // Google Sign-In errors
    if (errorString.contains('google') || errorString.contains('sign_in')) {
      if (errorString.contains('cancelled')) {
        return AuthErrorType.userCancelled;
      } else {
        return AuthErrorType.googleSignInFailed;
      }
    }

    // Token errors
    if (errorString.contains('token') || errorString.contains('jwt')) {
      if (errorString.contains('expired')) {
        return AuthErrorType.tokenExpired;
      } else {
        return AuthErrorType.tokenInvalid;
      }
    }

    // Validation errors
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return AuthErrorType.validationError;
    }

    return AuthErrorType.unknown;
  }

  /// Get comprehensive error information
  AuthErrorInfo _getErrorInfo(
    AuthErrorType errorType,
    dynamic originalError,
    String? context,
    Map<String, dynamic>? metadata,
  ) {
    final baseMessage = errorType.message;
    final isRetryable = errorType.isRetryable;
    final requiresReauth = errorType.requiresReauthentication;

    // Get context-specific message
    String contextualMessage = baseMessage;
    if (context != null) {
      contextualMessage = _getContextualMessage(errorType, context, baseMessage);
    }

    // Get recovery suggestions
    final recoverySuggestions = _getRecoverySuggestions(errorType, context);

    // Get user actions
    final userActions = _getUserActions(errorType, context);

    return AuthErrorInfo(
      type: errorType,
      message: contextualMessage,
      originalError: originalError,
      context: context,
      metadata: metadata,
      isRetryable: isRetryable,
      requiresReauthentication: requiresReauth,
      recoverySuggestions: recoverySuggestions,
      userActions: userActions,
      errorCount: _errorCounts[errorType] ?? 0,
      lastOccurrence: _lastErrorTimes[errorType],
    );
  }

  /// Get contextual error message
  String _getContextualMessage(AuthErrorType errorType, String context, String baseMessage) {
    switch (context.toLowerCase()) {
      case 'login':
      case 'signin':
        switch (errorType) {
          case AuthErrorType.networkError:
            return 'Unable to sign in due to network issues. Please check your connection.';
          case AuthErrorType.invalidCredentials:
            return 'Invalid email or password. Please check your credentials and try again.';
          case AuthErrorType.userNotFound:
            return 'No account found with this email. Please check your email or sign up.';
          default:
            return 'Sign in failed. $baseMessage';
        }
      case 'signup':
      case 'register':
        switch (errorType) {
          case AuthErrorType.networkError:
            return 'Unable to create account due to network issues. Please check your connection.';
          case AuthErrorType.emailAlreadyExists:
            return 'An account with this email already exists. Please sign in instead.';
          case AuthErrorType.weakPassword:
            return 'Password is too weak. Please choose a stronger password.';
          default:
            return 'Account creation failed. $baseMessage';
        }
      case 'google_signin':
        switch (errorType) {
          case AuthErrorType.userCancelled:
            return 'Google Sign-In was cancelled.';
          case AuthErrorType.googleSignInFailed:
            return 'Google Sign-In failed. Please try again or use email/password.';
          case AuthErrorType.accountExistsWithDifferentCredential:
            return 'An account exists with this email using a different sign-in method.';
          default:
            return 'Google Sign-In failed. $baseMessage';
        }
      default:
        return baseMessage;
    }
  }

  /// Get recovery suggestions for error type
  List<String> _getRecoverySuggestions(AuthErrorType errorType, String? context) {
    switch (errorType) {
      case AuthErrorType.networkError:
        return [
          'Check your internet connection',
          'Try switching between WiFi and mobile data',
          'Wait a moment and try again',
          'Restart the app if the problem persists',
        ];
      case AuthErrorType.serverError:
        return [
          'The server is temporarily unavailable',
          'Please try again in a few minutes',
          'Check our status page for updates',
        ];
      case AuthErrorType.invalidCredentials:
        return [
          'Double-check your email and password',
          'Make sure Caps Lock is off',
          'Try resetting your password if you forgot it',
        ];
      case AuthErrorType.emailAlreadyExists:
        return [
          'Try signing in instead of creating a new account',
          'Use the "Forgot Password" option if needed',
          'Check if you have an existing account with this email',
        ];
      case AuthErrorType.googleSignInFailed:
        return [
          'Make sure Google Play Services are up to date',
          'Try signing out of Google and signing back in',
          'Use email/password sign-in as an alternative',
        ];
      case AuthErrorType.tokenExpired:
        return [
          'Your session has expired for security',
          'Please sign in again',
          'Enable "Remember Me" to stay signed in longer',
        ];
      default:
        return [
          'Please try again',
          'Restart the app if the problem continues',
          'Contact support if you need help',
        ];
    }
  }

  /// Get user actions for error type
  List<UserAction> _getUserActions(AuthErrorType errorType, String? context) {
    switch (errorType) {
      case AuthErrorType.networkError:
      case AuthErrorType.serverError:
        return [
          UserAction(
            label: 'Retry',
            action: UserActionType.retry,
            isPrimary: true,
          ),
          UserAction(
            label: 'Cancel',
            action: UserActionType.cancel,
            isPrimary: false,
          ),
        ];
      case AuthErrorType.invalidCredentials:
        return [
          UserAction(
            label: 'Try Again',
            action: UserActionType.retry,
            isPrimary: true,
          ),
          UserAction(
            label: 'Forgot Password',
            action: UserActionType.forgotPassword,
            isPrimary: false,
          ),
        ];
      case AuthErrorType.emailAlreadyExists:
        return [
          UserAction(
            label: 'Sign In',
            action: UserActionType.switchToSignIn,
            isPrimary: true,
          ),
          UserAction(
            label: 'Forgot Password',
            action: UserActionType.forgotPassword,
            isPrimary: false,
          ),
        ];
      case AuthErrorType.googleSignInFailed:
        return [
          UserAction(
            label: 'Try Again',
            action: UserActionType.retry,
            isPrimary: true,
          ),
          UserAction(
            label: 'Use Email/Password',
            action: UserActionType.switchToEmailAuth,
            isPrimary: false,
          ),
        ];
      case AuthErrorType.tokenExpired:
      case AuthErrorType.refreshTokenExpired:
        return [
          UserAction(
            label: 'Sign In Again',
            action: UserActionType.signIn,
            isPrimary: true,
          ),
        ];
      default:
        return [
          UserAction(
            label: 'OK',
            action: UserActionType.dismiss,
            isPrimary: true,
          ),
        ];
    }
  }

  /// Track error occurrence
  void _trackError(AuthErrorType errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _lastErrorTimes[errorType] = DateTime.now();
  }

  /// Log error for debugging (without sensitive information)
  void _logError(
    AuthErrorInfo errorInfo,
    dynamic originalError,
    Map<String, dynamic>? metadata,
  ) {
    if (kDebugMode) {
      debugPrint('=== AUTH ERROR LOG ===');
      debugPrint('Type: ${errorInfo.type}');
      debugPrint('Message: ${errorInfo.message}');
      debugPrint('Context: ${errorInfo.context}');
      debugPrint('Retryable: ${errorInfo.isRetryable}');
      debugPrint('Requires Reauth: ${errorInfo.requiresReauthentication}');
      debugPrint('Error Count: ${errorInfo.errorCount}');
      debugPrint('Metadata: ${metadata?.toString()}');
      debugPrint('Original Error: ${originalError.toString()}');
      debugPrint('=====================');
    }
  }
}

/// Comprehensive error information
class AuthErrorInfo {
  final AuthErrorType type;
  final String message;
  final dynamic originalError;
  final String? context;
  final Map<String, dynamic>? metadata;
  final bool isRetryable;
  final bool requiresReauthentication;
  final List<String> recoverySuggestions;
  final List<UserAction> userActions;
  final int errorCount;
  final DateTime? lastOccurrence;

  const AuthErrorInfo({
    required this.type,
    required this.message,
    this.originalError,
    this.context,
    this.metadata,
    required this.isRetryable,
    required this.requiresReauthentication,
    required this.recoverySuggestions,
    required this.userActions,
    required this.errorCount,
    this.lastOccurrence,
  });

  @override
  String toString() {
    return 'AuthErrorInfo(type: $type, message: $message, context: $context)';
  }
}

/// User action configuration
class UserAction {
  final String label;
  final UserActionType action;
  final bool isPrimary;
  final Map<String, dynamic>? data;

  const UserAction({
    required this.label,
    required this.action,
    required this.isPrimary,
    this.data,
  });

  @override
  String toString() {
    return 'UserAction(label: $label, action: $action, isPrimary: $isPrimary)';
  }
}

/// User action types
enum UserActionType {
  retry,
  cancel,
  dismiss,
  signIn,
  switchToSignIn,
  switchToEmailAuth,
  forgotPassword,
  contactSupport,
  checkSettings,
}

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration delay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    required this.maxAttempts,
    required this.delay,
    required this.backoffMultiplier,
    required this.maxDelay,
  });

  @override
  String toString() {
    return 'RetryConfig(maxAttempts: $maxAttempts, delay: $delay, backoffMultiplier: $backoffMultiplier)';
  }
}