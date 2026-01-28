import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Types of network errors
enum NetworkErrorType {
  timeout,
  noConnection,
  serverError,
  unknown,
}

/// Network error with detailed information
class NetworkError {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final String? details;
  final bool isRetryable;

  const NetworkError({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
    this.isRetryable = false,
  });

  @override
  String toString() {
    return 'NetworkError(type: $type, message: $message${statusCode != null ? ', statusCode: $statusCode' : ''}${details != null ? ', details: $details' : ''})';
  }
}

/// Service for monitoring network connectivity and handling errors
class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();

  NetworkService._();

  Timer? _connectivityTimer;
  bool _isMonitoring = false;
  final Duration _checkInterval = const Duration(seconds: 30);
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Starts monitoring network connectivity
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _connectivityTimer = Timer.periodic(_checkInterval, (_) async {
      await _checkConnectivity();
    });

    // Initial check
    _checkConnectivity();
    debugPrint('Network monitoring started');
  }

  /// Stops monitoring network connectivity
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    _isMonitoring = false;
    debugPrint('Network monitoring stopped');
  }

  /// Checks current network connectivity
  Future<bool> checkConnectivity() async {
    return await _checkConnectivity();
  }

  /// Checks if the device is currently connected to the internet
  Future<bool> isConnected() async {
    return await _checkConnectivity();
  }

  /// Detects network error type from exception
  NetworkError detectNetworkError(dynamic error) {
    if (error is SocketException) {
      return NetworkError(
        type: NetworkErrorType.noConnection,
        message: 'No internet connection available',
        details: error.message,
        isRetryable: true,
      );
    } else if (error is TimeoutException) {
      return NetworkError(
        type: NetworkErrorType.timeout,
        message: 'Request timed out',
        details: error.message,
        isRetryable: true,
      );
    } else if (error is HttpException) {
      return NetworkError(
        type: NetworkErrorType.serverError,
        message: 'Server error occurred',
        details: error.message,
        isRetryable: true,
      );
    } else {
      return NetworkError(
        type: NetworkErrorType.unknown,
        message: 'Unknown network error',
        details: error.toString(),
        isRetryable: false,
      );
    }
  }

  /// Handles network error and activates offline mode if needed
  Future<void> handleNetworkError(NetworkError error) async {
    debugPrint('Network error detected: $error');

    switch (error.type) {
      case NetworkErrorType.timeout:
      case NetworkErrorType.noConnection:
        await activateOfflineMode();
        break;
      case NetworkErrorType.serverError:
        // Don't activate offline mode for server errors, just log
        debugPrint('Server error: ${error.message}');
        break;
      case NetworkErrorType.unknown:
        debugPrint('Unknown network error: ${error.message}');
        break;
    }
  }

  /// Attempts to retry a network operation with exponential backoff and performance monitoring
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        
        stopwatch.stop();
        final responseTime = stopwatch.elapsedMilliseconds;
        debugPrint('Network operation completed in ${responseTime}ms (attempt ${attempts + 1})');
        
        // Record performance metrics
        if (responseTime > 5000) {
          debugPrint('Warning: Slow network response detected: ${responseTime}ms');
        }
        
        return result;
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          stopwatch.stop();
          debugPrint('Network operation failed after ${stopwatch.elapsedMilliseconds}ms and $attempts attempts');
          
          final networkError = detectNetworkError(e);
          await handleNetworkError(networkError);
          rethrow;
        }

        debugPrint('Retry attempt $attempts failed, waiting ${delay.inSeconds}s before next attempt');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Checks if the device can reach the internet
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10));
      
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _connectivityController.add(isConnected);

      if (isConnected) {
        await deactivateOfflineMode();
      } else {
        await activateOfflineMode();
      }

      return isConnected;
    } catch (e) {
      _connectivityController.add(false);
      await activateOfflineMode();
      return false;
    }
  }

  /// Activate offline mode
  Future<void> activateOfflineMode() async {
    debugPrint('Activating offline mode');
    // Implementation would go here
  }

  /// Deactivate offline mode  
  Future<void> deactivateOfflineMode() async {
    debugPrint('Deactivating offline mode');
    // Implementation would go here
  }

  /// Disposes of the service
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}