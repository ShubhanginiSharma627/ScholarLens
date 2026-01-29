/// AI Flashcard Generation Service Interfaces
/// 
/// This file defines the abstract interfaces for all AI generation components,
/// providing clear contracts for implementation and testing.

import 'dart:io';
import '../models/ai_generation.dart';

/// Abstract interface for content processing
abstract class ContentProcessor {
  /// Process an image file and extract educational content
  Future<ExtractedContent> processImage(File file);
  
  /// Process a PDF file and extract text content
  Future<ExtractedContent> processPDF(File file);
  
  /// Process plain text content
  Future<ExtractedContent> processText(String text);
  
  /// Process a topic/subject and generate contextual content
  Future<ExtractedContent> processTopic(String topic);
  
  /// Validate extracted content for quality and completeness
  ValidationResult validateContent(ExtractedContent content);
}

/// Abstract interface for AI-powered flashcard generation
abstract class AIGenerator {
  /// Analyze content and extract learning concepts
  Future<ContentAnalysis> analyzeContent(ExtractedContent content);
  
  /// Generate flashcards from analyzed content
  Future<List<GeneratedFlashcard>> generateFlashcards(
    ContentAnalysis analysis, 
    GenerationOptions options,
  );
  
  /// Assess the quality of a generated flashcard
  QualityScore assessQuality(GeneratedFlashcard flashcard);
  
  /// Regenerate a specific flashcard with feedback
  Future<GeneratedFlashcard> regenerateFlashcard(
    GeneratedFlashcard flashcard, 
    String feedback,
  );
}

/// Abstract interface for the review and editing system
abstract class ReviewInterface {
  /// Display generated flashcards for user review
  void displayFlashcards(List<GeneratedFlashcard> flashcards);
  
  /// Edit a specific flashcard
  Future<void> editFlashcard(String id, FlashcardUpdates updates);
  
  /// Delete a flashcard from the generated set
  Future<void> deleteFlashcard(String id);
  
  /// Regenerate a specific flashcard with user feedback
  Future<GeneratedFlashcard> regenerateFlashcard(String id, String feedback);
  
  /// Approve and save flashcards to the user's collection
  Future<List<Flashcard>> approveFlashcards(List<GeneratedFlashcard> flashcards);
}

/// Abstract interface for system integration
abstract class IntegrationManager {
  /// Convert a generated flashcard to the existing Flashcard model
  Flashcard convertToFlashcard(GeneratedFlashcard generated);
  
  /// Save flashcards to the user's deck
  Future<void> saveToUserDeck(List<Flashcard> flashcards, String userId);
  
  /// Schedule flashcards for spaced repetition
  Future<void> scheduleForSpacedRepetition(List<Flashcard> flashcards);
  
  /// Sync flashcards with offline storage
  Future<void> syncWithOfflineStorage(List<Flashcard> flashcards);
}

/// Abstract interface for generation session management
abstract class GenerationSessionManager {
  /// Create a new generation session
  Future<GenerationSession> createSession(
    String userId, 
    ContentSource contentSource,
  );
  
  /// Update session status
  Future<void> updateSessionStatus(
    String sessionId, 
    GenerationStatus status,
  );
  
  /// Add generated flashcards to a session
  Future<void> addFlashcardsToSession(
    String sessionId, 
    List<GeneratedFlashcard> flashcards,
  );
  
  /// Get session by ID
  Future<GenerationSession?> getSession(String sessionId);
  
  /// Get user's generation sessions
  Future<List<GenerationSession>> getUserSessions(String userId);
  
  /// Complete a generation session
  Future<void> completeSession(String sessionId);
  
  /// Mark session as failed with error message
  Future<void> failSession(String sessionId, String errorMessage);
}

/// Abstract interface for AI service communication
abstract class AIService {
  /// Generate flashcards from content using AI
  Future<List<GeneratedFlashcard>> generateFlashcardsFromContent(
    String content,
    GenerationOptions options,
  );
  
  /// Analyze image content using AI vision
  Future<String> analyzeImageContent(File imageFile);
  
  /// Extract text from PDF using AI
  Future<String> extractTextFromPDF(File pdfFile);
  
  /// Generate topic-based content using AI
  Future<String> generateTopicContent(String topic);
  
  /// Assess flashcard quality using AI
  Future<QualityScore> assessFlashcardQuality(GeneratedFlashcard flashcard);
}

/// Abstract interface for error handling
abstract class AIGenerationErrorHandler {
  /// Handle content processing errors
  void handleContentProcessingError(Exception error, ContentType contentType);
  
  /// Handle AI generation errors
  void handleGenerationError(Exception error, String context);
  
  /// Handle validation errors
  void handleValidationError(ValidationResult result);
  
  /// Handle network/API errors
  void handleNetworkError(Exception error);
  
  /// Get user-friendly error message
  String getUserFriendlyErrorMessage(Exception error);
}

/// Abstract interface for progress tracking
abstract class GenerationProgressTracker {
  /// Start tracking progress for a session
  void startTracking(String sessionId);
  
  /// Update progress percentage
  void updateProgress(String sessionId, double percentage);
  
  /// Update progress with status message
  void updateProgressWithMessage(String sessionId, String message);
  
  /// Complete progress tracking
  void completeProgress(String sessionId);
  
  /// Handle progress error
  void errorProgress(String sessionId, String errorMessage);
  
  /// Get current progress
  double getCurrentProgress(String sessionId);
}

/// Abstract interface for caching and offline support
abstract class AIGenerationCache {
  /// Cache generated flashcards
  Future<void> cacheFlashcards(String sessionId, List<GeneratedFlashcard> flashcards);
  
  /// Get cached flashcards
  Future<List<GeneratedFlashcard>?> getCachedFlashcards(String sessionId);
  
  /// Cache content analysis
  Future<void> cacheContentAnalysis(String contentId, ContentAnalysis analysis);
  
  /// Get cached content analysis
  Future<ContentAnalysis?> getCachedContentAnalysis(String contentId);
  
  /// Clear cache for session
  Future<void> clearSessionCache(String sessionId);
  
  /// Clear all cache
  Future<void> clearAllCache();
}

/// Abstract interface for analytics and metrics
abstract class AIGenerationAnalytics {
  /// Track generation session start
  void trackGenerationStart(String sessionId, ContentType contentType);
  
  /// Track generation completion
  void trackGenerationComplete(String sessionId, int flashcardCount);
  
  /// Track generation failure
  void trackGenerationFailure(String sessionId, String errorType);
  
  /// Track user review actions
  void trackReviewAction(String sessionId, String action, String flashcardId);
  
  /// Track flashcard quality scores
  void trackQualityScores(String sessionId, List<QualityScore> scores);
  
  /// Get generation statistics
  Future<Map<String, dynamic>> getGenerationStats(String userId);
}