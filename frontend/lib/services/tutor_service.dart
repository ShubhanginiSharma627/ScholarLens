import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lesson_content.dart';
import '../utils/performance_utils.dart';
import 'api_service.dart';
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
abstract class TutorService {
  Future<LessonContent> analyzeImage(File image, {String? userPrompt});
  Future<String> askFollowUpQuestion(String question, String context);
  Future<String> askChapterQuestion({
    required String question,
    required String textbookTitle,
    required int chapterNumber,
    required String sectionTitle,
    required String sectionContent,
    List<String>? highlights,
  });
  Future<bool> isServiceAvailable();
}
class HttpTutorService implements TutorService {
  final String baseUrl;
  final Duration timeout;
  final ApiService _apiService;
  final Map<String, Completer<String>> _activeRequests = {};
  HttpTutorService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15), // Reduced timeout
  }) : _apiService = ApiService();
  @override
  Future<LessonContent> analyzeImage(File image, {String? userPrompt}) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (!image.existsSync()) {
        throw const TutorServiceException('Image file does not exist');
      }
      debugPrint('Starting image analysis request via API service...');
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final response = await _apiService.analyzeEducationalImage(
        imageData: base64Image,
        analysisType: 'educational_content',
        language: 'English',
      );
      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;
      debugPrint('Image analysis completed in ${responseTime}ms');
      if (responseTime > 10000) {
        debugPrint('Warning: Slow API response detected: ${responseTime}ms');
      }
      final lessonContent = LessonContent(
        lessonTitle: response['title'] as String? ?? 'Image Analysis',
        summaryMarkdown: response['analysis'] as String? ?? response['explanation'] as String? ?? 'Analysis completed',
        audioTranscript: response['audioTranscript'] as String? ?? '',
        quiz: [], // Empty quiz for image analysis
        createdAt: DateTime.now(),
      );
      return lessonContent;
    } on ApiException catch (e) {
      stopwatch.stop();
      debugPrint('Image analysis failed after ${stopwatch.elapsedMilliseconds}ms: ${e.message}');
      throw TutorServiceException(
        'Failed to analyze image: ${e.message}',
        statusCode: e.statusCode,
        details: e.toString(),
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
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<String>();
    _activeRequests[requestId] = completer;
    try {
      debugPrint('Asking follow-up question via API service: $question');
      final timeoutFuture = Future.delayed(timeout, () {
        throw TimeoutException('Request timed out after ${timeout.inSeconds} seconds', timeout);
      });
      final apiCallFuture = _makeApiCall(question, context);
      final result = await Future.any([
        apiCallFuture,
        timeoutFuture,
      ]);
      completer.complete(result);
      return result;
    } catch (e) {
      debugPrint('Error during follow-up question: $e');
      if (e is TimeoutException) {
        completer.completeError(TutorServiceException(
          'Request timed out. The tutor service is taking too long to respond.',
          statusCode: 408,
          details: e.toString(),
        ));
      } else if (e is ApiException) {
        String errorMessage = 'Failed to get follow-up response: ${e.message}';
        if (e.statusCode == 500) {
          errorMessage = 'The tutor service is temporarily unavailable. Please try again in a moment.';
        } else if (e.statusCode == 403) {
          errorMessage = 'Access denied. Please check your authentication and try again.';
        } else if (e.statusCode == 429) {
          errorMessage = 'Too many requests. Please wait a moment before trying again.';
        }
        completer.completeError(TutorServiceException(
          errorMessage,
          statusCode: e.statusCode,
          details: e.toString(),
        ));
      } else {
        completer.completeError(TutorServiceException(
          'An unexpected error occurred while processing your question. Please try again.',
          details: e.toString(),
        ));
      }
      rethrow;
    } finally {
      _activeRequests.remove(requestId);
    }
  }
  Future<String> _makeApiCall(String question, String context) async {
    return await PerformanceUtils.measureAsync(
      'Tutor API Call',
      () async {
        final response = await _apiService.chatWithTutor(
          message: question,
          sessionType: 'follow_up',
          conversationHistory: [
            {
              'role': 'assistant',
              'content': context,
            },
            {
              'role': 'user', 
              'content': question,
            }
          ],
        );
        
        // Handle structured response
        if (response['structuredData'] != null) {
          // Store structured data for potential future use
          // For now, just return the main response
          final responseText = response['response'] as String? ?? 
                              response['message'] as String? ??
                              'I apologize, but I couldn\'t process your follow-up question at the moment.';
          return responseText;
        }
        
        final responseText = response['response'] as String? ?? 
                            response['message'] as String? ??
                            'I apologize, but I couldn\'t process your follow-up question at the moment.';
        if (responseText.trim().isEmpty) {
          throw TutorServiceException('Received empty response from tutor service');
        }
        debugPrint('Successfully received follow-up response: ${responseText.length} characters');
        return responseText;
      },
    );
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
      debugPrint('Asking chapter question via API service: $question');
      final contextMessage = '''
Context: $textbookTitle - Chapter $chapterNumber: $sectionTitle
Section Content:
$sectionContent
${highlights != null && highlights.isNotEmpty ? 'Highlighted text: ${highlights.join(', ')}' : ''}
Question: $question
''';
      final response = await _apiService.chatWithTutor(
        message: contextMessage,
        subject: textbookTitle,
        sessionType: 'chapter_discussion',
        conversationHistory: [
          {
            'role': 'system',
            'content': 'You are helping a student understand content from their textbook. Provide clear, educational explanations based on the provided context.',
          },
          {
            'role': 'user',
            'content': contextMessage,
          }
        ],
      );
      final responseText = response['response'] as String? ?? 
                          response['message'] as String? ??
                          'I apologize, but I couldn\'t process your chapter question at the moment.';
      if (responseText.trim().isEmpty) {
        throw TutorServiceException('Received empty response from tutor service');
      }
      debugPrint('Successfully received chapter response: ${responseText.length} characters');
      return responseText;
    } on ApiException catch (e) {
      debugPrint('API error during chapter question: $e');
      throw TutorServiceException(
        'Failed to get chapter-specific response: ${e.message}',
        statusCode: e.statusCode,
        details: e.toString(),
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
      final status = await _apiService.getAIStatus();
      return status['available'] == true || status['status'] == 'healthy';
    } catch (e) {
      debugPrint('Tutor service availability check failed: $e');
      return false;
    }
  }
  String _getFileName(String path) {
    final segments = path.split('/');
    return segments.isNotEmpty ? segments.last : 'image.jpg';
  }
  void cancelActiveRequests() {
    for (final completer in _activeRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(TutorServiceException('Request cancelled by user'));
      }
    }
    _activeRequests.clear();
  }
  int get activeRequestCount => _activeRequests.length;
}
class TutorServiceFactory {
  static const String defaultBaseUrl = 'https://scholarlens-afvx.onrender.com';
  static TutorService createProduction({String? baseUrl}) {
    return HttpTutorService(
      baseUrl: baseUrl ?? defaultBaseUrl,
    );
  }
  static TutorService createForTesting({
    required String baseUrl,
    Duration? timeout,
  }) {
    return HttpTutorService(
      baseUrl: baseUrl,
      timeout: timeout ?? const Duration(seconds: 5),
    );
  }
}