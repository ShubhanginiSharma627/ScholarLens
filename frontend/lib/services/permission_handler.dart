import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

/// Service for handling platform-specific permissions
class PermissionHandler {
  static PermissionHandler? _instance;
  static PermissionHandler get instance => _instance ??= PermissionHandler._();

  PermissionHandler._();

  // Permission status cache
  final Map<PermissionType, PermissionStatus> _permissionCache = {};
  final Map<PermissionType, DateTime> _lastChecked = {};
  final Duration _cacheExpiry = const Duration(minutes: 1);

  /// Requests camera permission
  Future<PermissionResult> requestCameraPermission() async {
    return await _requestPermission(
      PermissionType.camera,
      'Camera access is required to capture study materials.',
      'ScholarLens needs camera permission to help you learn from your study materials.',
    );
  }

  /// Requests microphone permission
  Future<PermissionResult> requestMicrophonePermission() async {
    return await _requestPermission(
      PermissionType.microphone,
      'Microphone access is required for voice input.',
      'ScholarLens needs microphone permission to understand your spoken questions.',
    );
  }

  /// Requests storage permission (Android only)
  Future<PermissionResult> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionResult(
        status: PermissionStatus.granted,
        canRequest: false,
        message: 'Storage permission not required on this platform',
      );
    }

    return await _requestPermission(
      PermissionType.storage,
      'Storage access is required to save images and data.',
      'ScholarLens needs storage permission to save your learning progress and images.',
    );
  }

  /// Checks current permission status without requesting
  Future<PermissionStatus> checkPermissionStatus(PermissionType type) async {
    // Check cache first
    final lastCheck = _lastChecked[type];
    if (lastCheck != null && 
        DateTime.now().difference(lastCheck) < _cacheExpiry &&
        _permissionCache.containsKey(type)) {
      return _permissionCache[type]!;
    }

    try {
      final status = await _checkPlatformPermission(type);
      _permissionCache[type] = status;
      _lastChecked[type] = DateTime.now();
      return status;
    } catch (e) {
      debugPrint('Permission check failed for $type: $e');
      return PermissionStatus.unknown;
    }
  }

  /// Checks if permission is granted
  Future<bool> isPermissionGranted(PermissionType type) async {
    final status = await checkPermissionStatus(type);
    return status == PermissionStatus.granted;
  }

  /// Checks if permission can be requested
  Future<bool> canRequestPermission(PermissionType type) async {
    final status = await checkPermissionStatus(type);
    return status == PermissionStatus.denied || status == PermissionStatus.unknown;
  }

  /// Opens app settings for manual permission grant
  Future<bool> openAppSettings() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('app_settings');
        return await platform.invokeMethod('openAppSettings') ?? false;
      } else if (Platform.isIOS) {
        const platform = MethodChannel('app_settings');
        return await platform.invokeMethod('openAppSettings') ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to open app settings: $e');
      return false;
    }
  }

  /// Shows permission rationale dialog
  Future<bool> showPermissionRationale(
    BuildContext context,
    PermissionType type,
    String rationale,
  ) async {
    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getPermissionIcon(type)),
            const SizedBox(width: 8),
            Text(_getPermissionTitle(type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rationale),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPermissionExplanation(type),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(false);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(true);
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    return completer.future;
  }

  /// Shows permission denied dialog with options
  Future<PermissionAction> showPermissionDeniedDialog(
    BuildContext context,
    PermissionType type,
  ) async {
    final completer = Completer<PermissionAction>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getPermissionIcon(type), color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Permission Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getPermissionDeniedMessage(type)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can enable this permission in your device settings.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(PermissionAction.cancel);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(PermissionAction.useAlternative);
            },
            child: Text(_getAlternativeActionText(type)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              completer.complete(PermissionAction.openSettings);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return completer.future;
  }

  /// Handles permission workflow with UI
  Future<PermissionResult> handlePermissionWorkflow(
    BuildContext context,
    PermissionType type,
  ) async {
    // Check current status
    final currentStatus = await checkPermissionStatus(type);
    
    if (currentStatus == PermissionStatus.granted) {
      return PermissionResult(
        status: PermissionStatus.granted,
        canRequest: false,
        message: 'Permission already granted',
      );
    }

    if (currentStatus == PermissionStatus.permanentlyDenied) {
      final action = await showPermissionDeniedDialog(context, type);
      
      if (!context.mounted) return PermissionResult(
        status: PermissionStatus.permanentlyDenied,
        canRequest: false,
        message: 'Widget disposed during permission request',
      );
      
      switch (action) {
        case PermissionAction.openSettings:
          final opened = await openAppSettings();
          return PermissionResult(
            status: PermissionStatus.permanentlyDenied,
            canRequest: false,
            message: opened ? 'Settings opened' : 'Failed to open settings',
          );
        case PermissionAction.useAlternative:
          return PermissionResult(
            status: PermissionStatus.permanentlyDenied,
            canRequest: false,
            message: 'User chose alternative',
            useAlternative: true,
          );
        case PermissionAction.cancel:
          return PermissionResult(
            status: PermissionStatus.permanentlyDenied,
            canRequest: false,
            message: 'User cancelled',
          );
      }
    }

    // Show rationale and request permission
    final shouldRequest = await showPermissionRationale(
      context,
      type,
      _getPermissionRationale(type),
    );

    if (!context.mounted) return PermissionResult(
      status: currentStatus,
      canRequest: false,
      message: 'Widget disposed during permission request',
    );

    if (!shouldRequest) {
      return PermissionResult(
        status: PermissionStatus.denied,
        canRequest: true,
        message: 'User declined permission request',
      );
    }

    // Request the permission
    return await _requestPermission(
      type,
      _getPermissionRationale(type),
      _getPermissionExplanation(type),
    );
  }

  /// Invalidates permission cache
  void invalidateCache([PermissionType? type]) {
    if (type != null) {
      _permissionCache.remove(type);
      _lastChecked.remove(type);
    } else {
      _permissionCache.clear();
      _lastChecked.clear();
    }
  }

  // Private methods

  Future<PermissionResult> _requestPermission(
    PermissionType type,
    String rationale,
    String explanation,
  ) async {
    try {
      final status = await _requestPlatformPermission(type);
      
      _permissionCache[type] = status;
      _lastChecked[type] = DateTime.now();

      return PermissionResult(
        status: status,
        canRequest: status == PermissionStatus.denied,
        message: _getStatusMessage(status, type),
      );
    } catch (e) {
      debugPrint('Permission request failed for $type: $e');
      return PermissionResult(
        status: PermissionStatus.unknown,
        canRequest: false,
        message: 'Permission request failed: $e',
      );
    }
  }

  Future<PermissionStatus> _checkPlatformPermission(PermissionType type) async {
    // This would typically use a permission plugin like permission_handler
    // For now, we'll simulate the behavior
    
    try {
      const platform = MethodChannel('permissions');
      final result = await platform.invokeMethod('checkPermission', {
        'permission': _getPermissionString(type),
      });
      
      return _parsePermissionStatus(result);
    } catch (e) {
      // Fallback for when permission plugin is not available
      debugPrint('Permission check failed, assuming granted: $e');
      return PermissionStatus.granted;
    }
  }

  Future<PermissionStatus> _requestPlatformPermission(PermissionType type) async {
    try {
      const platform = MethodChannel('permissions');
      final result = await platform.invokeMethod('requestPermission', {
        'permission': _getPermissionString(type),
      });
      
      return _parsePermissionStatus(result);
    } catch (e) {
      // Fallback for when permission plugin is not available
      debugPrint('Permission request failed, assuming granted: $e');
      return PermissionStatus.granted;
    }
  }

  String _getPermissionString(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'camera';
      case PermissionType.microphone:
        return 'microphone';
      case PermissionType.storage:
        return 'storage';
    }
  }

  PermissionStatus _parsePermissionStatus(dynamic result) {
    if (result == null) return PermissionStatus.unknown;
    
    switch (result.toString().toLowerCase()) {
      case 'granted':
        return PermissionStatus.granted;
      case 'denied':
        return PermissionStatus.denied;
      case 'permanently_denied':
      case 'restricted':
        return PermissionStatus.permanentlyDenied;
      default:
        return PermissionStatus.unknown;
    }
  }

  IconData _getPermissionIcon(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return Icons.camera_alt;
      case PermissionType.microphone:
        return Icons.mic;
      case PermissionType.storage:
        return Icons.storage;
    }
  }

  String _getPermissionTitle(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera Permission';
      case PermissionType.microphone:
        return 'Microphone Permission';
      case PermissionType.storage:
        return 'Storage Permission';
    }
  }

  String _getPermissionRationale(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera access is required to capture study materials and help you learn from your textbooks, notes, and worksheets.';
      case PermissionType.microphone:
        return 'Microphone access is required for voice input, allowing you to ask questions by speaking instead of typing.';
      case PermissionType.storage:
        return 'Storage access is required to save your learning progress, images, and offline content.';
    }
  }

  String _getPermissionExplanation(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Your privacy is important. Images are only processed to generate educational content and are not stored permanently.';
      case PermissionType.microphone:
        return 'Voice input is processed locally when possible and is not recorded or stored permanently.';
      case PermissionType.storage:
        return 'Only app-related data is stored. Your personal files remain private and untouched.';
    }
  }

  String _getPermissionDeniedMessage(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Camera permission is required to capture study materials. Without it, you can still use the app by selecting images from your gallery.';
      case PermissionType.microphone:
        return 'Microphone permission is required for voice input. Without it, you can still type your questions manually.';
      case PermissionType.storage:
        return 'Storage permission is required to save your progress. Without it, some data may not persist between app sessions.';
    }
  }

  String _getAlternativeActionText(PermissionType type) {
    switch (type) {
      case PermissionType.camera:
        return 'Use Gallery';
      case PermissionType.microphone:
        return 'Type Instead';
      case PermissionType.storage:
        return 'Continue';
    }
  }

  String _getStatusMessage(PermissionStatus status, PermissionType type) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted successfully';
      case PermissionStatus.denied:
        return 'Permission denied by user';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable in settings.';
      case PermissionStatus.unknown:
        return 'Permission status unknown';
    }
  }
}

/// Types of permissions the app needs
enum PermissionType {
  camera,
  microphone,
  storage,
}

/// Permission status
enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

/// Actions user can take when permission is denied
enum PermissionAction {
  openSettings,
  useAlternative,
  cancel,
}

/// Result of permission request
class PermissionResult {
  final PermissionStatus status;
  final bool canRequest;
  final String message;
  final bool useAlternative;

  const PermissionResult({
    required this.status,
    required this.canRequest,
    required this.message,
    this.useAlternative = false,
  });

  bool get isGranted => status == PermissionStatus.granted;
  bool get isDenied => status == PermissionStatus.denied;
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;

  @override
  String toString() {
    return 'PermissionResult(status: $status, canRequest: $canRequest, message: $message)';
  }
}

/// Mixin for widgets that need permission handling
mixin PermissionHandlerMixin<T extends StatefulWidget> on State<T> {
  /// Requests permission with UI handling
  Future<bool> requestPermissionWithUI(PermissionType type) async {
    final handler = PermissionHandler.instance;
    final result = await handler.handlePermissionWorkflow(context, type);
    
    if (result.isGranted) {
      return true;
    } else if (result.useAlternative) {
      _handleAlternativeAction(type);
      return false;
    } else {
      _showPermissionError(result);
      return false;
    }
  }

  /// Handles alternative action when permission is denied
  void _handleAlternativeAction(PermissionType type) {
    // Override this method in implementing widgets
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Using alternative for ${type.name}'),
      ),
    );
  }

  /// Shows permission error
  void _showPermissionError(PermissionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: Colors.orange,
      ),
    );
  }
}