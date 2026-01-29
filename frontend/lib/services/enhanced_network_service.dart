import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'network_service.dart';

class EnhancedNetworkService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  
  static const Duration _timeout = Duration(seconds: 30);
  
  final ApiService _apiService = ApiService();
  final NetworkService _networkService = NetworkService.instance;
  
  // Singleton pattern
  static final EnhancedNetworkService _instance = EnhancedNetworkService._internal();
  factory EnhancedNetworkService() => _instance;
  EnhancedNetworkService._internal();
  
  // Health check
  Future<bool> isServerHealthy() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl.replaceAll('/api', '')),
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
  
  // Retry mechanism for failed requests
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(delay * attempts);
        
        // Check if it's a token expiration error
        if (e is TokenExpiredException) {
          try {
            await _apiService.refreshTokens();
            // Retry immediately after token refresh
            continue;
          } catch (refreshError) {
            // If refresh fails, clear tokens and rethrow original error
            _apiService.clearTokens();
            rethrow;
          }
        }
        
        // Check if it's an API exception that might be retryable
        if (e is ApiException && e.statusCode >= 500) {
          // Server error, retry with backoff
          continue;
        }
        
        // For other errors, don't retry
        rethrow;
      }
    }
    
    throw Exception('Max retries exceeded');
  }
  
  // Upload file with progress tracking
  Future<Map<String, dynamic>> uploadFile({
    required String endpoint,
    required File file,
    Map<String, String>? fields,
    Function(double)? onProgress,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    // Add headers
    request.headers.addAll({
      'Accept': 'application/json',
      // Note: Authorization header will be added by ApiService if needed
    });
    
    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }
    
    // Add file
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
    );
    request.files.add(multipartFile);
    
    // Send request with progress tracking
    final streamedResponse = await request.send();
    
    if (onProgress != null) {
      int totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      
      streamedResponse.stream.listen(
        (chunk) {
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress(receivedBytes / totalBytes);
          }
        },
      );
    }
    
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        'Upload failed: ${response.body}',
        response.statusCode,
      );
    }
  }
  
  // Batch requests
  Future<List<Map<String, dynamic>>> batchRequests(
    List<Future<Map<String, dynamic>>> requests,
  ) async {
    try {
      final results = await Future.wait(requests);
      return results;
    } catch (e) {
      debugPrint('Batch request failed: $e');
      rethrow;
    }
  }
  
  // Download file
  Future<List<int>> downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw ApiException(
          'Download failed',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      rethrow;
    }
  }
  
  // Network error handling
  String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    } else if (error is HttpException) {
      return 'Network error occurred. Please try again.';
    } else if (error is FormatException) {
      return 'Invalid response from server.';
    } else if (error is ApiException) {
      return error.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
  
  // Cache management
  final Map<String, CacheEntry> _cache = {};
  
  void cacheResponse(String key, Map<String, dynamic> data, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );
  }
  
  Map<String, dynamic>? getCachedResponse(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data;
    }
    
    // Remove expired entry
    if (entry != null) {
      _cache.remove(key);
    }
    
    return null;
  }
  
  void clearCache() {
    _cache.clear();
  }
  
  // Dispose resources
  void dispose() {
    _networkService.dispose();
    _cache.clear();
    _apiService.dispose();
  }

  // Delegate NetworkService methods
  Future<bool> checkConnectivity() => _networkService.checkConnectivity();
  Future<bool> isConnected() => _networkService.isConnected();
  NetworkError detectNetworkError(dynamic error) => _networkService.detectNetworkError(error);
  Future<void> handleNetworkError(NetworkError error) => _networkService.handleNetworkError(error);
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) => _networkService.retryOperation(operation, maxRetries: maxRetries, initialDelay: initialDelay);
  Stream<bool> get connectivityStream => _networkService.connectivityStream;
  void startMonitoring() => _networkService.startMonitoring();
  void stopMonitoring() => _networkService.stopMonitoring();
}

class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration ttl;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
  
  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

// Additional exception classes for enhanced network service
class NetworkException implements Exception {
  final String message;
  final int statusCode;
  
  NetworkException(this.message, this.statusCode);
  
  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}