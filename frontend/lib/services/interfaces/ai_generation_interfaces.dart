import 'dart:io';
import '../models/ai_generation.dart';
abstract class ContentProcessor {
  Future<ExtractedContent> processImage(File file);
  Future<ExtractedContent> processPDF(File file);
  Future<ExtractedContent> processText(String text);
  Future<ExtractedContent> processTopic(String topic);
  ValidationResult validateContent(ExtractedContent content);
}
abstract class AIGenerator {
  Future<ContentAnalysis> analyzeContent(ExtractedContent content);
  Future<List<GeneratedFlashcard>> generateFlashcards(
    ContentAnalysis analysis, 
    GenerationOptions options,
  );
  QualityScore assessQuality(GeneratedFlashcard flashcard);
  Future<GeneratedFlashcard> regenerateFlashcard(
    GeneratedFlashcard flashcard, 
    String feedback,
  );
}
abstract class ReviewInterface {
  void displayFlashcards(List<GeneratedFlashcard> flashcards);
  Future<void> editFlashcard(String id, FlashcardUpdates updates);
  Future<void> deleteFlashcard(String id);
  Future<GeneratedFlashcard> regenerateFlashcard(String id, String feedback);
  Future<List<Flashcard>> approveFlashcards(List<GeneratedFlashcard> flashcards);
}
abstract class IntegrationManager {
  Flashcard convertToFlashcard(GeneratedFlashcard generated);
  Future<void> saveToUserDeck(List<Flashcard> flashcards, String userId);
  Future<void> scheduleForSpacedRepetition(List<Flashcard> flashcards);
  Future<void> syncWithOfflineStorage(List<Flashcard> flashcards);
}
abstract class GenerationSessionManager {
  Future<GenerationSession> createSession(
    String userId, 
    ContentSource contentSource,
  );
  Future<void> updateSessionStatus(
    String sessionId, 
    GenerationStatus status,
  );
  Future<void> addFlashcardsToSession(
    String sessionId, 
    List<GeneratedFlashcard> flashcards,
  );
  Future<GenerationSession?> getSession(String sessionId);
  Future<List<GenerationSession>> getUserSessions(String userId);
  Future<void> completeSession(String sessionId);
  Future<void> failSession(String sessionId, String errorMessage);
}
abstract class AIService {
  Future<List<GeneratedFlashcard>> generateFlashcardsFromContent(
    String content,
    GenerationOptions options,
  );
  Future<String> analyzeImageContent(File imageFile);
  Future<String> extractTextFromPDF(File pdfFile);
  Future<String> generateTopicContent(String topic);
  Future<QualityScore> assessFlashcardQuality(GeneratedFlashcard flashcard);
}
abstract class AIGenerationErrorHandler {
  void handleContentProcessingError(Exception error, ContentType contentType);
  void handleGenerationError(Exception error, String context);
  void handleValidationError(ValidationResult result);
  void handleNetworkError(Exception error);
  String getUserFriendlyErrorMessage(Exception error);
}
abstract class GenerationProgressTracker {
  void startTracking(String sessionId);
  void updateProgress(String sessionId, double percentage);
  void updateProgressWithMessage(String sessionId, String message);
  void completeProgress(String sessionId);
  void errorProgress(String sessionId, String errorMessage);
  double getCurrentProgress(String sessionId);
}
abstract class AIGenerationCache {
  Future<void> cacheFlashcards(String sessionId, List<GeneratedFlashcard> flashcards);
  Future<List<GeneratedFlashcard>?> getCachedFlashcards(String sessionId);
  Future<void> cacheContentAnalysis(String contentId, ContentAnalysis analysis);
  Future<ContentAnalysis?> getCachedContentAnalysis(String contentId);
  Future<void> clearSessionCache(String sessionId);
  Future<void> clearAllCache();
}
abstract class AIGenerationAnalytics {
  void trackGenerationStart(String sessionId, ContentType contentType);
  void trackGenerationComplete(String sessionId, int flashcardCount);
  void trackGenerationFailure(String sessionId, String errorType);
  void trackReviewAction(String sessionId, String action, String flashcardId);
  void trackQualityScores(String sessionId, List<QualityScore> scores);
  Future<Map<String, dynamic>> getGenerationStats(String userId);
}