import 'dart:io';
import '../../models/flashcard.dart';

// Stub interfaces for AI generation functionality
// These can be implemented when the full AI generation system is built

abstract class ContentProcessor {
  Future<Map<String, dynamic>> processImage(File file);
  Future<Map<String, dynamic>> processPDF(File file);
  Future<Map<String, dynamic>> processText(String text);
  Future<Map<String, dynamic>> processTopic(String topic);
}

abstract class AIGenerator {
  Future<List<Flashcard>> generateFlashcards(
    String content, 
    Map<String, dynamic> options,
  );
}

abstract class ReviewInterface {
  void displayFlashcards(List<Flashcard> flashcards);
  Future<void> editFlashcard(String id, Map<String, dynamic> updates);
  Future<void> deleteFlashcard(String id);
}

abstract class IntegrationManager {
  Future<void> saveToUserDeck(List<Flashcard> flashcards, String userId);
  Future<void> scheduleForSpacedRepetition(List<Flashcard> flashcards);
}

abstract class GenerationSessionManager {
  Future<String> createSession(String userId, Map<String, dynamic> contentSource);
  Future<void> updateSessionStatus(String sessionId, String status);
  Future<Map<String, dynamic>?> getSession(String sessionId);
}

abstract class AIService {
  Future<List<Flashcard>> generateFlashcardsFromContent(
    String content,
    Map<String, dynamic> options,
  );
  Future<String> analyzeImageContent(File imageFile);
  Future<String> extractTextFromPDF(File pdfFile);
}