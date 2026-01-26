import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';

/// Handles camera-related errors and provides user-friendly messages
class CameraErrorHandler {
  /// Handles camera exceptions and returns user-friendly error information
  static CameraErrorInfo handleCameraError(dynamic error) {
    if (error is CameraException) {
      return _handleCameraException(error);
    } else if (error is ScholarLensCameraException) {
      return _handleScholarLensCameraException(error);
    } else if (error is Exception) {
      return _handleGenericException(error);
    } else {
      return CameraErrorInfo(
        type: CameraErrorType.unknown,
        title: 'Unknown Error',
        message: 'An unexpected error occurred: ${error.toString()}',
        canRetry: true,
        suggestedAction: 'Please try again or restart the app',
      );
    }
  }

  static CameraErrorInfo _handleScholarLensCameraException(ScholarLensCameraException error) {
    final message = error.message.toLowerCase();
    final details = error.details.toLowerCase();
    
    if (message.contains('permission') || details.contains('permission')) {
      return CameraErrorInfo(
        type: CameraErrorType.permissionDenied,
        title: 'Camera Permission Required',
        message: error.details,
        canRetry: true,
        suggestedAction: 'Go to Settings > Apps > ScholarLens > Permissions and enable Camera',
        actionIcon: Icons.settings,
      );
    }
    
    if (message.contains('camera') && (message.contains('not') || details.contains('not available'))) {
      return CameraErrorInfo(
        type: CameraErrorType.hardwareUnavailable,
        title: 'Camera Not Available',
        message: error.details,
        canRetry: false,
        suggestedAction: 'Close other camera apps and try again, or use the gallery to select an image',
        actionIcon: Icons.photo_library,
      );
    }
    
    if (message.contains('initialization')) {
      return CameraErrorInfo(
        type: CameraErrorType.initializationFailed,
        title: 'Camera Initialization Failed',
        message: error.details,
        canRetry: true,
        suggestedAction: 'Try again or restart the app',
        actionIcon: Icons.refresh,
      );
    }
    
    if (message.contains('capture')) {
      return CameraErrorInfo(
        type: CameraErrorType.captureFailed,
        title: 'Image Capture Failed',
        message: error.details,
        canRetry: true,
        suggestedAction: 'Ensure good lighting and try capturing again',
        actionIcon: Icons.camera_alt,
      );
    }
    
    if (message.contains('crop')) {
      return CameraErrorInfo(
        type: CameraErrorType.cropFailed,
        title: 'Image Cropping Failed',
        message: error.details,
        canRetry: true,
        suggestedAction: 'Try cropping again or proceed with the original image',
        actionIcon: Icons.crop,
      );
    }
    
    if (message.contains('compress')) {
      return CameraErrorInfo(
        type: CameraErrorType.compressionFailed,
        title: 'Image Compression Failed',
        message: error.details,
        canRetry: true,
        suggestedAction: 'Try capturing a new image or reduce image quality',
        actionIcon: Icons.compress,
      );
    }
    
    return CameraErrorInfo(
      type: CameraErrorType.generic,
      title: 'Camera Error',
      message: error.details,
      canRetry: true,
      suggestedAction: 'Please try again',
    );
  }

  static CameraErrorInfo _handleCameraException(CameraException error) {
    final description = error.description?.toLowerCase() ?? '';
    
    if (description.contains('permission') || description.contains('denied')) {
      return CameraErrorInfo(
        type: CameraErrorType.permissionDenied,
        title: 'Camera Permission Required',
        message: 'ScholarLens needs camera access to capture study materials. Please grant camera permission in your device settings.',
        canRetry: true,
        suggestedAction: 'Go to Settings > Apps > ScholarLens > Permissions and enable Camera',
        actionIcon: Icons.settings,
      );
    }
    
    if (description.contains('no camera') || description.contains('not available')) {
      return CameraErrorInfo(
        type: CameraErrorType.hardwareUnavailable,
        title: 'Camera Not Available',
        message: 'No camera was found on this device or the camera is being used by another app.',
        canRetry: false,
        suggestedAction: 'Close other camera apps and try again, or use the gallery to select an image',
        actionIcon: Icons.photo_library,
      );
    }
    
    if (description.contains('initialization') || description.contains('initialize')) {
      return CameraErrorInfo(
        type: CameraErrorType.initializationFailed,
        title: 'Camera Initialization Failed',
        message: 'Failed to initialize the camera. This might be a temporary issue.',
        canRetry: true,
        suggestedAction: 'Try again or restart the app',
        actionIcon: Icons.refresh,
      );
    }
    
    if (description.contains('capture') || description.contains('picture')) {
      return CameraErrorInfo(
        type: CameraErrorType.captureFailed,
        title: 'Image Capture Failed',
        message: 'Failed to capture the image. Please try again.',
        canRetry: true,
        suggestedAction: 'Ensure good lighting and try capturing again',
        actionIcon: Icons.camera_alt,
      );
    }
    
    if (description.contains('crop')) {
      return CameraErrorInfo(
        type: CameraErrorType.cropFailed,
        title: 'Image Cropping Failed',
        message: 'Failed to crop the image. The original image will be used.',
        canRetry: true,
        suggestedAction: 'Try cropping again or proceed with the original image',
        actionIcon: Icons.crop,
      );
    }
    
    if (description.contains('compress')) {
      return CameraErrorInfo(
        type: CameraErrorType.compressionFailed,
        title: 'Image Compression Failed',
        message: 'Failed to compress the image. The image might be too large or corrupted.',
        canRetry: true,
        suggestedAction: 'Try capturing a new image or reduce image quality',
        actionIcon: Icons.compress,
      );
    }
    
    return CameraErrorInfo(
      type: CameraErrorType.generic,
      title: 'Camera Error',
      message: error.description ?? 'An error occurred while using the camera',
      canRetry: true,
      suggestedAction: 'Please try again',
    );
  }

  static CameraErrorInfo _handleGenericException(Exception error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('storage') || message.contains('space')) {
      return CameraErrorInfo(
        type: CameraErrorType.storageError,
        title: 'Storage Error',
        message: 'Not enough storage space to save the image.',
        canRetry: false,
        suggestedAction: 'Free up storage space and try again',
        actionIcon: Icons.storage,
      );
    }
    
    if (message.contains('network') || message.contains('internet')) {
      return CameraErrorInfo(
        type: CameraErrorType.networkError,
        title: 'Network Error',
        message: 'Network connection is required for some camera features.',
        canRetry: true,
        suggestedAction: 'Check your internet connection and try again',
        actionIcon: Icons.wifi_off,
      );
    }
    
    return CameraErrorInfo(
      type: CameraErrorType.generic,
      title: 'Error',
      message: error.toString(),
      canRetry: true,
      suggestedAction: 'Please try again',
    );
  }

  /// Shows an error dialog with appropriate actions
  static Future<void> showErrorDialog(
    BuildContext context,
    CameraErrorInfo errorInfo, {
    VoidCallback? onRetry,
    VoidCallback? onAlternativeAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(errorInfo.type),
              color: _getErrorColor(errorInfo.type),
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      errorInfo.actionIcon ?? Icons.info,
                      size: 20,
                      color: Colors.blue,
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

  static IconData _getErrorIcon(CameraErrorType type) {
    switch (type) {
      case CameraErrorType.permissionDenied:
        return Icons.security;
      case CameraErrorType.hardwareUnavailable:
        return Icons.camera_alt_outlined;
      case CameraErrorType.initializationFailed:
        return Icons.error_outline;
      case CameraErrorType.captureFailed:
        return Icons.camera_alt;
      case CameraErrorType.cropFailed:
        return Icons.crop;
      case CameraErrorType.compressionFailed:
        return Icons.compress;
      case CameraErrorType.storageError:
        return Icons.storage;
      case CameraErrorType.networkError:
        return Icons.wifi_off;
      case CameraErrorType.generic:
      case CameraErrorType.unknown:
        return Icons.error;
    }
  }

  static Color _getErrorColor(CameraErrorType type) {
    switch (type) {
      case CameraErrorType.permissionDenied:
        return Colors.orange;
      case CameraErrorType.hardwareUnavailable:
        return Colors.red;
      case CameraErrorType.storageError:
        return Colors.red;
      case CameraErrorType.networkError:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  static String _getAlternativeActionText(CameraErrorType type) {
    switch (type) {
      case CameraErrorType.permissionDenied:
        return 'Settings';
      case CameraErrorType.hardwareUnavailable:
        return 'Gallery';
      case CameraErrorType.captureFailed:
        return 'Gallery';
      default:
        return 'Alternative';
    }
  }
}

/// Information about a camera error
class CameraErrorInfo {
  final CameraErrorType type;
  final String title;
  final String message;
  final bool canRetry;
  final String? suggestedAction;
  final IconData? actionIcon;

  const CameraErrorInfo({
    required this.type,
    required this.title,
    required this.message,
    required this.canRetry,
    this.suggestedAction,
    this.actionIcon,
  });
}

/// Types of camera errors
enum CameraErrorType {
  permissionDenied,
  hardwareUnavailable,
  initializationFailed,
  captureFailed,
  cropFailed,
  compressionFailed,
  storageError,
  networkError,
  generic,
  unknown,
}

/// Mixin for widgets that use camera functionality
mixin CameraErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// Handles camera errors with appropriate UI feedback
  void handleCameraError(dynamic error, {VoidCallback? onRetry}) {
    final errorInfo = CameraErrorHandler.handleCameraError(error);
    
    CameraErrorHandler.showErrorDialog(
      context,
      errorInfo,
      onRetry: errorInfo.canRetry ? onRetry : null,
      onAlternativeAction: _getAlternativeAction(errorInfo.type),
    );
  }

  VoidCallback? _getAlternativeAction(CameraErrorType type) {
    switch (type) {
      case CameraErrorType.permissionDenied:
        return () {
          // TODO: Open app settings
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable camera permission in device settings'),
            ),
          );
        };
      case CameraErrorType.hardwareUnavailable:
      case CameraErrorType.captureFailed:
        return () {
          // TODO: Open gallery picker
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery selection coming soon'),
            ),
          );
        };
      default:
        return null;
    }
  }
}