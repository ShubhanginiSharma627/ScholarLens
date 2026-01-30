import 'package:flutter/foundation.dart';
import '../models/lesson_content.dart';
import '../models/processed_image.dart';
import 'tutor_service.dart';
import 'offline_service.dart';
import 'network_service.dart';
class TutorController {
  final TutorService _tutorService;
  final OfflineService _offlineService;
  final NetworkService _networkService;
  TutorController({
    required TutorService tutorService,
    OfflineService? offlineService,
    NetworkService? networkService,
  })  : _tutorService = tutorService,
        _offlineService = offlineService ?? OfflineService.instance,
        _networkService = networkService ?? NetworkService.instance;
  Future<LessonContent> processLearningRequest(
    ProcessedImage image, {
    String? userPrompt,
  }) async {
    try {
      debugPrint('Processing learning request for image: ${image.file.path}');
      if (_offlineService.isOfflineMode) {
        debugPrint('Already in offline mode, returning demo lesson');
        return await _offlineService.getDemoLesson();
      }
      final lessonContent = await _networkService.retryOperation(
        () => _tutorService.analyzeImage(image.file, userPrompt: userPrompt),
        maxRetries: 2,
      );
      debugPrint('Successfully received lesson content: ${lessonContent.lessonTitle}');
      return lessonContent;
    } on TutorServiceException catch (e) {
      debugPrint('TutorService error: $e');
      final networkError = _networkService.detectNetworkError(e);
      await _networkService.handleNetworkError(networkError);
      debugPrint('Falling back to demo lesson due to tutor service error');
      return await _offlineService.getDemoLesson();
    } catch (e) {
      debugPrint('Unexpected error during learning request: $e');
      final networkError = _networkService.detectNetworkError(e);
      await _networkService.handleNetworkError(networkError);
      debugPrint('Falling back to demo lesson due to unexpected error');
      return await _offlineService.getDemoLesson();
    }
  }
  Future<String> askFollowUpQuestion(
    String question,
    String context,
  ) async {
    try {
      debugPrint('Processing follow-up question: $question');
      if (_offlineService.isOfflineMode) {
        return _getOfflineFollowUpResponse(question);
      }
      final response = await _networkService.retryOperation(
        () => _tutorService.askFollowUpQuestion(question, context),
        maxRetries: 2,
      );
      debugPrint('Successfully received follow-up response');
      return response;
    } on TutorServiceException catch (e) {
      debugPrint('TutorService error during follow-up: $e');
      final networkError = _networkService.detectNetworkError(e);
      await _networkService.handleNetworkError(networkError);
      return _getOfflineFollowUpResponse(question);
    } catch (e) {
      debugPrint('Unexpected error during follow-up question: $e');
      final networkError = _networkService.detectNetworkError(e);
      await _networkService.handleNetworkError(networkError);
      return _getOfflineFollowUpResponse(question);
    }
  }
  Future<bool> checkServiceAvailability() async {
    try {
      return await _networkService.checkConnectivity();
    } catch (e) {
      debugPrint('Service availability check failed: $e');
      return false;
    }
  }
  Future<LessonContent?> retryLastRequest({
    ProcessedImage? image,
    String? userPrompt,
  }) async {
    if (image == null) {
      debugPrint('No image provided for retry');
      return null;
    }
    try {
      final isConnected = await _networkService.checkConnectivity();
      if (!isConnected) {
        debugPrint('Still no connectivity, cannot retry');
        return null;
      }
      debugPrint('Retrying last request with restored connectivity');
      return await processLearningRequest(image, userPrompt: userPrompt);
    } catch (e) {
      debugPrint('Retry failed: $e');
      return null;
    }
  }
  Future<List<String>> getAvailableDemoLessons() async {
    return await _offlineService.getAvailableDemoLessons();
  }
  Future<LessonContent?> getDemoLessonByTitle(String title) async {
    return await _offlineService.getDemoLessonByTitle(title);
  }
  String _getOfflineFollowUpResponse(String question) {
    final lowerQuestion = question.toLowerCase();
    if (lowerQuestion.contains('photosynthesis')) {
      return "I'd love to help you learn more about photosynthesis! However, I'm currently in offline mode and can only provide basic information. The demo lesson covers the key concepts including the light-dependent and light-independent reactions, the importance of chlorophyll, and how different plant types (C3, C4, and CAM) have adapted to various environments. When you're back online, I'll be able to provide more detailed and personalized explanations!";
    } else if (lowerQuestion.contains('what') || lowerQuestion.contains('how') || lowerQuestion.contains('why')) {
      return "That's a great question! Unfortunately, I'm currently in offline mode and can't access my full knowledge base to give you a comprehensive answer. I can share the pre-loaded demo lesson about photosynthesis, but for detailed explanations about other topics, you'll need an internet connection. Please try again when you're back online!";
    } else {
      return "I'm currently in offline mode and have limited functionality. I can show you a demo lesson about photosynthesis, but for interactive conversations and detailed explanations, I need an internet connection. Please check your network and try again!";
    }
  }
  void dispose() {
  }
}