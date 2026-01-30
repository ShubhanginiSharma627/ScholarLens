import 'dart:convert';
import 'dart:io';
import '../models/flashcard.dart';
import 'api_service.dart';

class AIGenerationService {
  final ApiService _apiService;

  AIGenerationService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<List<Flashcard>> generateFromText({
    required String text,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    try {
      return await _apiService.generateFlashcards(
        topic: text,
        count: count,
        difficulty: difficulty,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from text: ${e.toString()}',
      );
    }
  }

  Future<List<Flashcard>> generateFromTopic({
    required String topic,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    try {
      return await _apiService.generateFlashcards(
        topic: topic,
        count: count,
        difficulty: difficulty,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from topic: ${e.toString()}',
      );
    }
  }

  Future<List<Flashcard>> generateFromImage({
    required File imageFile,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final analysis = await _apiService.analyzeImage(
        imageBase64: base64Image,
        prompt: 'Extract key concepts and information from this image for flashcard generation',
      );
      
      return await _apiService.generateFlashcards(
        topic: analysis,
        count: count,
        difficulty: difficulty,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from image: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      return {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

class AIGenerationException implements Exception {
  final String message;
  final String? details;

  const AIGenerationException(this.message, {this.details});

  @override
  String toString() {
    if (details != null) {
      return 'AIGenerationException: $message\nDetails: $details';
    }
    return 'AIGenerationException: $message';
  }
}