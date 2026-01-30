import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/error_handler.dart';
import 'package:scholar_lens/services/camera_error_handler.dart';
import 'package:scholar_lens/services/network_service.dart';
import 'package:scholar_lens/services/audio_service.dart';
import 'package:scholar_lens/services/voice_input_service.dart';
void main() {
  group('ErrorHandler', () {
    test('should handle camera errors correctly', () {
      final cameraError = CameraErrorInfo(
        type: CameraErrorType.permissionDenied,
        title: 'Camera Permission Required',
        message: 'Camera access is needed',
        canRetry: true,
      );
      final errorInfo = ErrorHandler.handleError(cameraError);
      expect(errorInfo.type, ErrorType.camera);
      expect(errorInfo.category, ErrorCategory.permission);
      expect(errorInfo.title, 'Camera Permission Required');
      expect(errorInfo.canRetry, true);
    });
    test('should handle network errors correctly', () {
      final networkError = NetworkError(
        type: NetworkErrorType.noConnection,
        message: 'No internet connection',
      );
      final errorInfo = ErrorHandler.handleError(networkError);
      expect(errorInfo.type, ErrorType.network);
      expect(errorInfo.category, ErrorCategory.connectivity);
      expect(errorInfo.canRetry, true);
    });
    test('should handle audio service errors correctly', () {
      final audioError = AudioServiceException('TTS not available');
      final errorInfo = ErrorHandler.handleError(audioError);
      expect(errorInfo.type, ErrorType.audio);
      expect(errorInfo.title, 'Audio Not Available');
    });
    test('should handle voice input errors correctly', () {
      final voiceError = VoiceInputException('Microphone permission denied');
      final errorInfo = ErrorHandler.handleError(voiceError);
      expect(errorInfo.type, ErrorType.voice);
      expect(errorInfo.category, ErrorCategory.permission);
    });
    test('should handle unknown errors correctly', () {
      final unknownError = Exception('Something went wrong');
      final errorInfo = ErrorHandler.handleError(unknownError);
      expect(errorInfo.type, ErrorType.generic);
      expect(errorInfo.category, ErrorCategory.generic);
      expect(errorInfo.canRetry, true);
    });
    test('should map error severity correctly', () {
      final highSeverityError = CameraErrorInfo(
        type: CameraErrorType.permissionDenied,
        title: 'Permission Denied',
        message: 'Camera permission required',
        canRetry: true,
      );
      final errorInfo = ErrorHandler.handleError(highSeverityError);
      expect(errorInfo.severity, ErrorSeverity.high);
    });
  });
  group('ErrorInfo', () {
    test('should create error info with timestamp', () {
      final errorInfo = ErrorInfo(
        type: ErrorType.camera,
        category: ErrorCategory.permission,
        title: 'Test Error',
        message: 'Test message',
        canRetry: true,
        severity: ErrorSeverity.medium,
      );
      expect(errorInfo.timestamp, isA<DateTime>());
      expect(errorInfo.toString(), contains('ErrorInfo'));
    });
  });
}