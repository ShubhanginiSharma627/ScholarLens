import 'user.dart';
class AuthResult {
  final bool success;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;
  final AuthErrorType? errorType;
  const AuthResult({
    required this.success,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.error,
    this.errorType,
  });
  factory AuthResult.success({
    required User user,
    required String accessToken,
    String? refreshToken,
  }) {
    return AuthResult(
      success: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
  factory AuthResult.failure({
    required String error,
    required AuthErrorType errorType,
  }) {
    return AuthResult(
      success: false,
      error: error,
      errorType: errorType,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.success == success &&
        other.user == user &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.error == error &&
        other.errorType == errorType;
  }
  @override
  int get hashCode {
    return Object.hash(
      success,
      user,
      accessToken,
      refreshToken,
      error,
      errorType,
    );
  }
  @override
  String toString() {
    if (success) {
      return 'AuthResult.success(user: ${user?.email})';
    } else {
      return 'AuthResult.failure(error: $error, type: $errorType)';
    }
  }
}
enum AuthenticationState {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}
enum AuthErrorType {
  invalidCredentials,
  userNotFound,
  emailAlreadyExists,
  weakPassword,
  invalidEmail,
  networkError,
  serverError,
  googleSignInCancelled,
  googleSignInFailed,
  tokenExpired,
  tokenInvalid,
  refreshTokenExpired,
  sessionTerminated,
  validationError,
  termsNotAccepted,
  userCancelled,
  accountExistsWithDifferentCredential,
  unknown,
}
extension AuthErrorTypeExtension on AuthErrorType {
  String get message {
    switch (this) {
      case AuthErrorType.invalidCredentials:
        return 'Invalid email or password. Please try again.';
      case AuthErrorType.userNotFound:
        return 'No account found with this email address.';
      case AuthErrorType.emailAlreadyExists:
        return 'An account with this email already exists.';
      case AuthErrorType.weakPassword:
        return 'Password must be at least 8 characters with uppercase, lowercase, and numbers.';
      case AuthErrorType.invalidEmail:
        return 'Please enter a valid email address.';
      case AuthErrorType.networkError:
        return 'Network error. Please check your connection and try again.';
      case AuthErrorType.serverError:
        return 'Server error. Please try again later.';
      case AuthErrorType.googleSignInCancelled:
        return 'Google Sign-In was cancelled.';
      case AuthErrorType.googleSignInFailed:
        return 'Google Sign-In failed. Please try again.';
      case AuthErrorType.tokenExpired:
        return 'Your session has expired. Please sign in again.';
      case AuthErrorType.tokenInvalid:
        return 'Invalid session. Please sign in again.';
      case AuthErrorType.refreshTokenExpired:
        return 'Session expired. Please sign in again.';
      case AuthErrorType.sessionTerminated:
        return 'Session terminated for security reasons. Please sign in again.';
      case AuthErrorType.validationError:
        return 'Please check your input and try again.';
      case AuthErrorType.termsNotAccepted:
        return 'Please accept the terms and conditions to continue.';
      case AuthErrorType.userCancelled:
        return 'Sign-in was cancelled.';
      case AuthErrorType.accountExistsWithDifferentCredential:
        return 'An account already exists with this email using a different sign-in method.';
      case AuthErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  bool get isRetryable {
    switch (this) {
      case AuthErrorType.networkError:
      case AuthErrorType.serverError:
      case AuthErrorType.unknown:
        return true;
      default:
        return false;
    }
  }
  bool get requiresReauthentication {
    switch (this) {
      case AuthErrorType.tokenExpired:
      case AuthErrorType.tokenInvalid:
      case AuthErrorType.refreshTokenExpired:
      case AuthErrorType.sessionTerminated:
        return true;
      default:
        return false;
    }
  }
}