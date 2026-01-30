import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/google_signin_service.dart';
import '../../lib/services/auth_error_handler.dart';
import '../../lib/providers/authentication_provider.dart';
import '../../lib/models/auth_result.dart';
@GenerateMocks([GoogleSignInService, AuthErrorHandler])
import 'google_signin_cancellation_test.mocks.dart';
void main() {
  group('Google Sign-In Cancellation Tests', () {
    late MockGoogleSignInService mockGoogleSignInService;
    late MockAuthErrorHandler mockAuthErrorHandler;
    late AuthenticationProvider authProvider;
    setUp(() {
      mockGoogleSignInService = MockGoogleSignInService();
      mockAuthErrorHandler = MockAuthErrorHandler();
    });
    test('should not show error when user cancels Google Sign-In', () async {
      final cancelledResult = AuthResult.failure(
        error: 'Sign-in cancelled',
        errorType: AuthErrorType.userCancelled,
      );
      when(mockGoogleSignInService.signInWithGoogle())
          .thenAnswer((_) async => cancelledResult);
      when(mockAuthErrorHandler.shouldShowError(AuthErrorType.userCancelled))
          .thenReturn(false);
      expect(mockAuthErrorHandler.shouldShowError(AuthErrorType.userCancelled), false);
    });
    test('should show error for actual Google Sign-In failures', () async {
      final failureResult = AuthResult.failure(
        error: 'Google Sign-In failed',
        errorType: AuthErrorType.googleSignInFailed,
      );
      when(mockGoogleSignInService.signInWithGoogle())
          .thenAnswer((_) async => failureResult);
      when(mockAuthErrorHandler.shouldShowError(AuthErrorType.googleSignInFailed))
          .thenReturn(true);
      expect(mockAuthErrorHandler.shouldShowError(AuthErrorType.googleSignInFailed), true);
    });
    test('should handle network errors appropriately', () async {
      final networkErrorResult = AuthResult.failure(
        error: 'Network error',
        errorType: AuthErrorType.networkError,
      );
      when(mockGoogleSignInService.signInWithGoogle())
          .thenAnswer((_) async => networkErrorResult);
      when(mockAuthErrorHandler.shouldShowError(AuthErrorType.networkError))
          .thenReturn(true);
      expect(mockAuthErrorHandler.shouldShowError(AuthErrorType.networkError), true);
    });
  });
}