import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'camera_error_handler.dart';
import 'network_service.dart';
import 'audio_service.dart';
import 'voice_input_service.dart';
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  ErrorHandler._();
  static ErrorInfo handleError(dynamic error, {ErrorContext? context}) {
    if (error is CameraErrorInfo) {
      return _convertCameraError(error);
    } else if (error is NetworkError) {
      return _convertNetworkError(error);
    } else if (error is AudioServiceException) {
      return _handleAudioError(error);
    } else if (error is VoiceInputException) {
      return _handleVoiceError(error);
    } else if (error is PlatformException) {
      return _handlePlatformError(error, context);
    } else if (error is SocketException) {
      return _handleSocketError(error);
    } else if (error is TimeoutException) {
      return _handleTimeoutError(error);
    } else if (error is FormatException) {
      return _handleFormatError(error);
    } else if (error is FileSystemException) {
      return _handleFileSystemError(error);
    } else if (error is Exception) {
      return _handleGenericException(error, context);
    } else {
      return _handleUnknownError(error, context);
    }
  }
  static ErrorInfo _convertCameraError(CameraErrorInfo cameraError) {
    return ErrorInfo(
      type: ErrorType.camera,
      category: _mapCameraErrorCategory(cameraError.type),
      title: cameraError.title,
      message: cameraError.message,
      canRetry: cameraError.canRetry,
      suggestedAction: cameraError.suggestedAction,
      actionIcon: cameraError.actionIcon,
      severity: _mapCameraErrorSeverity(cameraError.type),
    );
  }
  static ErrorInfo _convertNetworkError(NetworkError networkError) {
    return ErrorInfo(
      type: ErrorType.network,
      category: _mapNetworkErrorCategory(networkError.type),
      title: _getNetworkErrorTitle(networkError.type),
      message: networkError.message,
      canRetry: _canRetryNetworkError(networkError.type),
      suggestedAction: _getNetworkErrorAction(networkError.type),
      actionIcon: _getNetworkErrorIcon(networkError.type),
      severity: _mapNetworkErrorSeverity(networkError.type),
      statusCode: networkError.statusCode,
    );
  }
  static ErrorInfo _handleAudioError(AudioServiceException error) {
    final message = error.message.toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return ErrorInfo(
        type: ErrorType.audio,
        category: ErrorCategory.permission,
        title: 'Audio Permission Required',
        message: 'ScholarLens needs audio permission for text-to-speech functionality.',
        canRetry: true,
        suggestedAction: 'Enable audio permissions in device settings',
        actionIcon: Icons.volume_up,
        severity: ErrorSeverity.medium,
      );
    }
    if (message.contains('not available') || message.contains('unavailable')) {
      return ErrorInfo(
        type: ErrorType.audio,
        category: ErrorCategory.hardware,
        title: 'Audio Not Available',
        message: 'Text-to-speech is not available on this device.',
        canRetry: false,
        suggestedAction: 'Audio functionality will be disabled',
        actionIcon: Icons.volume_off,
        severity: ErrorSeverity.low,
      );
    }
    if (message.contains('initialization') || message.contains('initialize')) {
      return ErrorInfo(
        type: ErrorType.audio,
        category: ErrorCategory.initialization,
        title: 'Audio Initialization Failed',
        message: 'Failed to initialize text-to-speech engine.',
        canRetry: true,
        suggestedAction: 'Try again or restart the app',
        actionIcon: Icons.refresh,
        severity: ErrorSeverity.medium,
      );
    }
    return ErrorInfo(
      type: ErrorType.audio,
      category: ErrorCategory.generic,
      title: 'Audio Error',
      message: error.message,
      canRetry: true,
      suggestedAction: 'Try again later',
      actionIcon: Icons.volume_up,
      severity: ErrorSeverity.low,
    );
  }
  static ErrorInfo _handleVoiceError(VoiceInputException error) {
    final message = error.message.toLowerCase();
    if (message.contains('permission') || message.contains('denied')) {
      return ErrorInfo(
        type: ErrorType.voice,
        category: ErrorCategory.permission,
        title: 'Microphone Permission Required',
        message: 'ScholarLens needs microphone access for voice input.',
        canRetry: true,
        suggestedAction: 'Enable microphone permissions in device settings',
        actionIcon: Icons.mic,
        severity: ErrorSeverity.medium,
      );
    }
    if (message.contains('not available') || message.contains('unavailable')) {
      return ErrorInfo(
        type: ErrorType.voice,
        category: ErrorCategory.hardware,
        title: 'Speech Recognition Not Available',
        message: 'Speech recognition is not available on this device.',
        canRetry: false,
        suggestedAction: 'Use text input instead',
        actionIcon: Icons.keyboard,
        severity: ErrorSeverity.low,
      );
    }
    if (message.contains('already listening')) {
      return ErrorInfo(
        type: ErrorType.voice,
        category: ErrorCategory.state,
        title: 'Already Listening',
        message: 'Voice input is already active.',
        canRetry: false,
        suggestedAction: 'Wait for current session to complete',
        actionIcon: Icons.mic,
        severity: ErrorSeverity.low,
      );
    }
    return ErrorInfo(
      type: ErrorType.voice,
      category: ErrorCategory.generic,
      title: 'Voice Input Error',
      message: error.message,
      canRetry: true,
      suggestedAction: 'Try speaking again',
      actionIcon: Icons.mic,
      severity: ErrorSeverity.low,
    );
  }
  static ErrorInfo _handlePlatformError(PlatformException error, ErrorContext? context) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    if (code.contains('permission') || message.contains('permission')) {
      return ErrorInfo(
        type: ErrorType.platform,
        category: ErrorCategory.permission,
        title: 'Permission Required',
        message: error.message ?? 'A permission is required to continue.',
        canRetry: true,
        suggestedAction: 'Grant the required permission in device settings',
        actionIcon: Icons.security,
        severity: ErrorSeverity.high,
      );
    }
    if (code.contains('camera') || message.contains('camera')) {
      return ErrorInfo(
        type: ErrorType.platform,
        category: ErrorCategory.hardware,
        title: 'Camera Error',
        message: error.message ?? 'Camera functionality is not available.',
        canRetry: true,
        suggestedAction: 'Check camera permissions and try again',
        actionIcon: Icons.camera_alt,
        severity: ErrorSeverity.medium,
      );
    }
    if (code.contains('audio') || code.contains('microphone') || message.contains('audio')) {
      return ErrorInfo(
        type: ErrorType.platform,
        category: ErrorCategory.hardware,
        title: 'Audio Error',
        message: error.message ?? 'Audio functionality is not available.',
        canRetry: true,
        suggestedAction: 'Check audio permissions and try again',
        actionIcon: Icons.volume_up,
        severity: ErrorSeverity.medium,
      );
    }
    return ErrorInfo(
      type: ErrorType.platform,
      category: ErrorCategory.generic,
      title: 'Platform Error',
      message: error.message ?? 'A platform-specific error occurred.',
      canRetry: true,
      suggestedAction: 'Try again or restart the app',
      actionIcon: Icons.error,
      severity: ErrorSeverity.medium,
    );
  }
  static ErrorInfo _handleSocketError(SocketException error) {
    return ErrorInfo(
      type: ErrorType.network,
      category: ErrorCategory.connectivity,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      canRetry: true,
      suggestedAction: 'Check network settings or try offline mode',
      actionIcon: Icons.wifi_off,
      severity: ErrorSeverity.medium,
    );
  }
  static ErrorInfo _handleTimeoutError(TimeoutException error) {
    return ErrorInfo(
      type: ErrorType.network,
      category: ErrorCategory.timeout,
      title: 'Request Timed Out',
      message: 'The request took too long to complete.',
      canRetry: true,
      suggestedAction: 'Check your connection and try again',
      actionIcon: Icons.access_time,
      severity: ErrorSeverity.medium,
    );
  }
  static ErrorInfo _handleFormatError(FormatException error) {
    return ErrorInfo(
      type: ErrorType.data,
      category: ErrorCategory.parsing,
      title: 'Data Format Error',
      message: 'Received data is in an unexpected format.',
      canRetry: true,
      suggestedAction: 'Try again or contact support if the problem persists',
      actionIcon: Icons.data_object,
      severity: ErrorSeverity.medium,
    );
  }
  static ErrorInfo _handleFileSystemError(FileSystemException error) {
    final message = error.message.toLowerCase();
    if (message.contains('space') || message.contains('storage')) {
      return ErrorInfo(
        type: ErrorType.storage,
        category: ErrorCategory.space,
        title: 'Storage Full',
        message: 'Not enough storage space available.',
        canRetry: false,
        suggestedAction: 'Free up storage space and try again',
        actionIcon: Icons.storage,
        severity: ErrorSeverity.high,
      );
    }
    if (message.contains('permission') || message.contains('access')) {
      return ErrorInfo(
        type: ErrorType.storage,
        category: ErrorCategory.permission,
        title: 'Storage Access Denied',
        message: 'Cannot access storage location.',
        canRetry: true,
        suggestedAction: 'Check storage permissions',
        actionIcon: Icons.folder_off,
        severity: ErrorSeverity.medium,
      );
    }
    return ErrorInfo(
      type: ErrorType.storage,
      category: ErrorCategory.generic,
      title: 'File System Error',
      message: error.message,
      canRetry: true,
      suggestedAction: 'Try again later',
      actionIcon: Icons.folder,
      severity: ErrorSeverity.medium,
    );
  }
  static ErrorInfo _handleGenericException(Exception error, ErrorContext? context) {
    final message = error.toString().toLowerCase();
    if (message.contains('network') || message.contains('internet')) {
      return ErrorInfo(
        type: ErrorType.network,
        category: ErrorCategory.connectivity,
        title: 'Network Error',
        message: 'A network error occurred.',
        canRetry: true,
        suggestedAction: 'Check your internet connection',
        actionIcon: Icons.wifi_off,
        severity: ErrorSeverity.medium,
      );
    }
    return ErrorInfo(
      type: ErrorType.generic,
      category: ErrorCategory.generic,
      title: 'Error',
      message: error.toString(),
      canRetry: true,
      suggestedAction: 'Try again later',
      actionIcon: Icons.error,
      severity: ErrorSeverity.low,
    );
  }
  static ErrorInfo _handleUnknownError(dynamic error, ErrorContext? context) {
    return ErrorInfo(
      type: ErrorType.unknown,
      category: ErrorCategory.generic,
      title: 'Unexpected Error',
      message: 'An unexpected error occurred: ${error.toString()}',
      canRetry: true,
      suggestedAction: 'Try again or restart the app',
      actionIcon: Icons.error_outline,
      severity: ErrorSeverity.medium,
    );
  }
  static Future<void> showErrorDialog(
    BuildContext context,
    ErrorInfo errorInfo, {
    VoidCallback? onRetry,
    VoidCallback? onAlternativeAction,
    bool barrierDismissible = true,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(errorInfo.type, errorInfo.category),
              color: _getErrorColor(errorInfo.severity),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(errorInfo.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorInfo.message),
            if (errorInfo.suggestedAction != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getErrorColor(errorInfo.severity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getErrorColor(errorInfo.severity).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      errorInfo.actionIcon ?? Icons.info,
                      size: 20,
                      color: _getErrorColor(errorInfo.severity),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorInfo.suggestedAction!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (errorInfo.canRetry && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          if (onAlternativeAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAlternativeAction();
              },
              child: Text(_getAlternativeActionText(errorInfo.type)),
            ),
        ],
      ),
    );
  }
  static void showErrorSnackBar(
    BuildContext context,
    ErrorInfo errorInfo, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(errorInfo.type, errorInfo.category),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(errorInfo.message)),
          ],
        ),
        backgroundColor: _getErrorColor(errorInfo.severity),
        action: errorInfo.canRetry && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: Duration(
          seconds: errorInfo.severity == ErrorSeverity.high ? 6 : 4,
        ),
      ),
    );
  }
  static void handleErrorWithUI(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onAlternativeAction,
    ErrorContext? errorContext,
    bool forceDialog = false,
  }) {
    final errorInfo = handleError(error, context: errorContext);
    if (forceDialog || errorInfo.severity == ErrorSeverity.high) {
      showErrorDialog(
        context,
        errorInfo,
        onRetry: onRetry,
        onAlternativeAction: onAlternativeAction,
      );
    } else {
      showErrorSnackBar(context, errorInfo, onRetry: onRetry);
    }
  }
  static ErrorCategory _mapCameraErrorCategory(CameraErrorType type) {
    switch (type) {
      case CameraErrorType.permissionDenied:
        return ErrorCategory.permission;
      case CameraErrorType.hardwareUnavailable:
        return ErrorCategory.hardware;
      case CameraErrorType.initializationFailed:
        return ErrorCategory.initialization;
      case CameraErrorType.storageError:
        return ErrorCategory.space;
      case CameraErrorType.networkError:
        return ErrorCategory.connectivity;
      default:
        return ErrorCategory.generic;
    }
  }
  static ErrorSeverity _mapCameraErrorSeverity(CameraErrorType type) {
    switch (type) {
      case CameraErrorType.permissionDenied:
      case CameraErrorType.hardwareUnavailable:
        return ErrorSeverity.high;
      case CameraErrorType.storageError:
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.low;
    }
  }
  static ErrorCategory _mapNetworkErrorCategory(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return ErrorCategory.connectivity;
      case NetworkErrorType.timeout:
        return ErrorCategory.timeout;
      case NetworkErrorType.serverError:
        return ErrorCategory.server;
      default:
        return ErrorCategory.generic;
    }
  }
  static ErrorSeverity _mapNetworkErrorSeverity(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return ErrorSeverity.medium;
      case NetworkErrorType.serverError:
        return ErrorSeverity.high;
      default:
        return ErrorSeverity.low;
    }
  }
  static String _getNetworkErrorTitle(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return 'No Internet Connection';
      case NetworkErrorType.timeout:
        return 'Request Timed Out';
      case NetworkErrorType.serverError:
        return 'Server Error';
      default:
        return 'Network Error';
    }
  }
  static bool _canRetryNetworkError(NetworkErrorType type) {
    return type != NetworkErrorType.serverError;
  }
  static String _getNetworkErrorAction(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return 'Check your internet connection and try again';
      case NetworkErrorType.timeout:
        return 'Check your connection speed and try again';
      case NetworkErrorType.serverError:
        return 'Try again later or contact support';
      default:
        return 'Try again later';
    }
  }
  static IconData _getNetworkErrorIcon(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return Icons.wifi_off;
      case NetworkErrorType.timeout:
        return Icons.access_time;
      case NetworkErrorType.serverError:
        return Icons.error;
      default:
        return Icons.error;
    }
  }
  static IconData _getErrorIcon(ErrorType type, ErrorCategory category) {
    switch (type) {
      case ErrorType.camera:
        return Icons.camera_alt;
      case ErrorType.network:
        return category == ErrorCategory.connectivity ? Icons.wifi_off : Icons.error;
      case ErrorType.audio:
        return Icons.volume_up;
      case ErrorType.voice:
        return Icons.mic;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.platform:
        return Icons.phone_android;
      case ErrorType.data:
        return Icons.data_object;
      default:
        return Icons.error;
    }
  }
  static Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
    }
  }
  static String _getAlternativeActionText(ErrorType type) {
    switch (type) {
      case ErrorType.camera:
        return 'Gallery';
      case ErrorType.network:
        return 'Offline Mode';
      case ErrorType.voice:
        return 'Type Instead';
      default:
        return 'Alternative';
    }
  }
}
class ErrorInfo {
  final ErrorType type;
  final ErrorCategory category;
  final String title;
  final String message;
  final bool canRetry;
  final String? suggestedAction;
  final IconData? actionIcon;
  final ErrorSeverity severity;
  final int? statusCode;
  final DateTime timestamp;
  ErrorInfo({
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.canRetry,
    this.suggestedAction,
    this.actionIcon,
    required this.severity,
    this.statusCode,
  }) : timestamp = DateTime.now();
  @override
  String toString() {
    return 'ErrorInfo(type: $type, category: $category, title: $title, severity: $severity)';
  }
}
enum ErrorType {
  camera,
  network,
  audio,
  voice,
  storage,
  platform,
  data,
  generic,
  unknown,
}
enum ErrorCategory {
  permission,
  hardware,
  connectivity,
  timeout,
  server,
  initialization,
  parsing,
  space,
  state,
  generic,
}
enum ErrorSeverity {
  low,    // Minor issues, can continue with degraded functionality
  medium, // Moderate issues, some features may not work
  high,   // Critical issues, major functionality affected
}
class ErrorContext {
  final String? screen;
  final String? feature;
  final Map<String, dynamic>? metadata;
  const ErrorContext({
    this.screen,
    this.feature,
    this.metadata,
  });
}
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void handleError(
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onAlternativeAction,
    String? feature,
    bool forceDialog = false,
  }) {
    final context = ErrorContext(
      screen: widget.runtimeType.toString(),
      feature: feature,
    );
    ErrorHandler.handleErrorWithUI(
      this.context,
      error,
      onRetry: onRetry,
      onAlternativeAction: onAlternativeAction,
      errorContext: context,
      forceDialog: forceDialog,
    );
  }
  void showErrorDialog(ErrorInfo errorInfo, {VoidCallback? onRetry}) {
    ErrorHandler.showErrorDialog(context, errorInfo, onRetry: onRetry);
  }
  void showErrorSnackBar(ErrorInfo errorInfo, {VoidCallback? onRetry}) {
    ErrorHandler.showErrorSnackBar(context, errorInfo, onRetry: onRetry);
  }
}