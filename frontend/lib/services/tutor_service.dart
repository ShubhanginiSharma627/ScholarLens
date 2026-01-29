import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/lesson_content.dart';

/// Exception thrown when tutor service operations fail
class TutorServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  const TutorServiceException(
    this.message, {
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    return 'TutorServiceException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? ' - $details' : ''}';
  }
}

/// Abstract interface for tutor service operations
abstract class TutorService {
  /// Analyzes an image and returns lesson content
  Future<LessonContent> analyzeImage(File image, {String? userPrompt});

  /// Asks a follow-up question with context
  Future<String> askFollowUpQuestion(String question, String context);

  /// Asks a question about a specific chapter section with context
  Future<String> askChapterQuestion({
    required String question,
    required String textbookTitle,
    required int chapterNumber,
    required String sectionTitle,
    required String sectionContent,
    List<String>? highlights,
  });

  /// Checks if the service is available
  Future<bool> isServiceAvailable();
}

/// HTTP implementation of the tutor service
class HttpTutorService implements TutorService {
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  HttpTutorService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<LessonContent> analyzeImage(File image, {String? userPrompt}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Validate image file
      if (!image.existsSync()) {
        throw const TutorServiceException('Image file does not exist');
      }

      debugPrint('Starting image analysis request...');

      // Create multipart request
      final uri = Uri.parse('$baseUrl/analyze');
      final request = http.MultipartRequest('POST', uri);

      // Add image file
      final imageBytes = await image.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: _getFileName(image.path),
      );
      request.files.add(multipartFile);

      // Add optional user prompt
      if (userPrompt != null && userPrompt.isNotEmpty) {
        request.fields['user_prompt'] = userPrompt;
      }

      // Set headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Send request with timeout
      final streamedResponse = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;
      
      // Handle response
      if (response.statusCode == 200) {
        debugPrint('Image analysis completed in ${responseTime}ms');
        
        // Log performance warning if response is slow
        if (responseTime > 10000) {
          debugPrint('Warning: Slow API response detected: ${responseTime}ms');
        }
        
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return LessonContent.fromJson(jsonData);
      } else {
        debugPrint('Image analysis failed after ${responseTime}ms with status ${response.statusCode}');
        throw TutorServiceException(
          'Failed to analyze image',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      debugPrint('Image analysis failed after ${stopwatch.elapsedMilliseconds}ms: Network connection failed');
      throw TutorServiceException(
        'Network connection failed',
        details: e.message,
      );
    } on http.ClientException catch (e) {
      stopwatch.stop();
      debugPrint('Image analysis failed after ${stopwatch.elapsedMilliseconds}ms: Client error');
      throw TutorServiceException(
        'HTTP client error',
        details: e.message,
      );
    } on FormatException catch (e) {
      throw TutorServiceException(
        'Invalid response format',
        details: e.message,
      );
    } catch (e) {
      if (e is TutorServiceException) rethrow;
      throw TutorServiceException(
        'Unexpected error during image analysis',
        details: e.toString(),
      );
    }
  }

  @override
  Future<String> askFollowUpQuestion(String question, String context) async {
    try {
      final uri = Uri.parse('$baseUrl/follow-up');
      
      final requestData = {
        'question': question,
        'context': context,
      };

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData['response'] as String;
      } else {
        throw TutorServiceException(
          'Failed to get follow-up response',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on SocketException catch (e) {
      throw TutorServiceException(
        'Network connection failed',
        details: e.message,
      );
    } on http.ClientException catch (e) {
      throw TutorServiceException(
        'HTTP client error',
        details: e.message,
      );
    } on FormatException catch (e) {
      throw TutorServiceException(
        'Invalid response format',
        details: e.message,
      );
    } catch (e) {
      if (e is TutorServiceException) rethrow;
      throw TutorServiceException(
        'Unexpected error during follow-up question',
        details: e.toString(),
      );
    }
  }

  @override
  Future<String> askChapterQuestion({
    required String question,
    required String textbookTitle,
    required int chapterNumber,
    required String sectionTitle,
    required String sectionContent,
    List<String>? highlights,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chapter-chat');
      
      // Build context with chapter information
      final contextData = {
        'question': question,
        'textbook_title': textbookTitle,
        'chapter_number': chapterNumber,
        'section_title': sectionTitle,
        'section_content': sectionContent,
        if (highlights != null && highlights.isNotEmpty) 'highlights': highlights,
      };

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(contextData),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData['response'] as String;
      } else {
        throw TutorServiceException(
          'Failed to get chapter-specific response',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on SocketException catch (e) {
      throw TutorServiceException(
        'Network connection failed',
        details: e.message,
      );
    } on http.ClientException catch (e) {
      throw TutorServiceException(
        'HTTP client error',
        details: e.message,
      );
    } on FormatException catch (e) {
      throw TutorServiceException(
        'Invalid response format',
        details: e.message,
      );
    } catch (e) {
      if (e is TutorServiceException) rethrow;
      throw TutorServiceException(
        'Unexpected error during chapter question',
        details: e.toString(),
      );
    }
  }

  @override
  Future<bool> isServiceAvailable() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Tutor service health check failed: $e');
      return false;
    }
  }

  /// Extracts filename from path
  String _getFileName(String path) {
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : 'image.jpg';
  }

  /// Disposes of the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Factory for creating tutor service instances
class TutorServiceFactory {
  static const String defaultBaseUrl = 'https://scholarlens-afvx.onrender.com';

  /// Creates a production tutor service
  static TutorService createProduction({String? baseUrl}) {
    return HttpTutorService(
      baseUrl: baseUrl ?? defaultBaseUrl,
    );
  }

  /// Creates a tutor service for testing
  static TutorService createForTesting({
    required String baseUrl,
    Duration? timeout,
    http.Client? client,
  }) {
    return HttpTutorService(
      baseUrl: baseUrl,
      timeout: timeout ?? const Duration(seconds: 5),
      client: client,
    );
  }
}