import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/camera_service.dart';
import 'package:scholar_lens/services/camera_error_handler.dart';
void main() {
  group('CameraService', () {
    test('ScholarLensCameraException should contain message and details', () {
      const exception = ScholarLensCameraException('Test message', 'Test details');
      expect(exception.message, equals('Test message'));
      expect(exception.details, equals('Test details'));
      expect(exception.toString(), contains('Test message'));
      expect(exception.toString(), contains('Test details'));
    });
  });
  group('CameraErrorHandler', () {
    test('should handle ScholarLensCameraException with permission denied', () {
      const exception = ScholarLensCameraException('Permission denied', 'Camera permission not granted');
      final errorInfo = CameraErrorHandler.handleCameraError(exception);
      expect(errorInfo.type, equals(CameraErrorType.permissionDenied));
      expect(errorInfo.title, equals('Camera Permission Required'));
      expect(errorInfo.canRetry, isTrue);
    });
    test('should handle ScholarLensCameraException with hardware unavailable', () {
      const exception = ScholarLensCameraException('Camera not available', 'Camera hardware not found');
      final errorInfo = CameraErrorHandler.handleCameraError(exception);
      expect(errorInfo.type, equals(CameraErrorType.hardwareUnavailable));
      expect(errorInfo.title, equals('Camera Not Available'));
      expect(errorInfo.canRetry, isFalse);
    });
    test('should handle generic exceptions', () {
      final exception = Exception('Generic error');
      final errorInfo = CameraErrorHandler.handleCameraError(exception);
      expect(errorInfo.type, equals(CameraErrorType.generic));
      expect(errorInfo.canRetry, isTrue);
    });
    test('should handle unknown errors', () {
      const error = 'Unknown error string';
      final errorInfo = CameraErrorHandler.handleCameraError(error);
      expect(errorInfo.type, equals(CameraErrorType.unknown));
      expect(errorInfo.canRetry, isTrue);
    });
  });
}