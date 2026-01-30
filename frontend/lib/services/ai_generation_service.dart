import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_generation.dart';
import '../models/flashcard.dart';
import 'api_service.dart';
import 'config_service.dart';
class AIGenerationService {
  final ApiService _apiService;
  final ConfigService _configService;
  AIGenerationService({
    ApiService? apiService,
    ConfigService? configService,
  }) : _apiService = apiService ?? ApiService(),
       _configService = configService ?? ConfigService();
  Future<AIGenerationResult> generateFromContent({
    required ContentSource contentSource,
    GenerationOptions? options,
  }) async {
    try {
      final requestBody = {
        'contentSource': contentSource.toJson(),
        'options': options?.toJson() ?? {},
      };
      final response = await _apiService.post(
        '/ai-generation/generate',
        requestBody,
      );
      if (response['success'] == true) {
        final data = response['data'];
        return AIGenerationResult.fromJson(data);
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Generation failed',
          details: response['error']['details'],
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards: ${e.toString()}',
      );
    }
  }
  Future<AIGenerationResult> generateFromImage({
    required File imageFile,
    GenerationOptions? options,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final contentSource = ContentSource(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ContentType.image,
        originalFileName: imageFile.path.split('/').last,
        content: base64Image,
        metadata: ContentMetadata(
          fileName: imageFile.path.split('/').last,
          fileSize: bytes.length,
          mimeType: _getMimeType(imageFile.path),
          uploadedAt: DateTime.now(),
        ),
        uploadedAt: DateTime.now(),
      );
      return await generateFromContent(
        contentSource: contentSource,
        options: options,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from image: ${e.toString()}',
      );
    }
  }
  Future<AIGenerationResult> generateFromPDF({
    required File pdfFile,
    GenerationOptions? options,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final base64PDF = base64Encode(bytes);
      final contentSource = ContentSource(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ContentType.pdf,
        originalFileName: pdfFile.path.split('/').last,
        content: base64PDF,
        metadata: ContentMetadata(
          fileName: pdfFile.path.split('/').last,
          fileSize: bytes.length,
          mimeType: 'application/pdf',
          uploadedAt: DateTime.now(),
        ),
        uploadedAt: DateTime.now(),
      );
      return await generateFromContent(
        contentSource: contentSource,
        options: options,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from PDF: ${e.toString()}',
      );
    }
  }
  Future<AIGenerationResult> generateFromText({
    required String text,
    GenerationOptions? options,
  }) async {
    try {
      final contentSource = ContentSource(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ContentType.text,
        content: text,
        metadata: ContentMetadata(
          uploadedAt: DateTime.now(),
          additionalData: {'textLength': text.length},
        ),
        uploadedAt: DateTime.now(),
      );
      return await generateFromContent(
        contentSource: contentSource,
        options: options,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from text: ${e.toString()}',
      );
    }
  }
  Future<AIGenerationResult> generateFromTopic({
    required String topic,
    GenerationOptions? options,
  }) async {
    try {
      final contentSource = ContentSource(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ContentType.topic,
        content: topic,
        metadata: ContentMetadata(
          uploadedAt: DateTime.now(),
          additionalData: {'topic': topic},
        ),
        uploadedAt: DateTime.now(),
      );
      return await generateFromContent(
        contentSource: contentSource,
        options: options,
      );
    } catch (e) {
      throw AIGenerationException(
        'Failed to generate flashcards from topic: ${e.toString()}',
      );
    }
  }
  Future<GenerationSession> getGenerationSession(String sessionId) async {
    try {
      final response = await _apiService.get('/ai-generation/sessions/$sessionId');
      if (response['success'] == true) {
        final sessionData = response['data']['session'];
        final flashcardsData = response['data']['flashcards'] as List;
        final flashcards = flashcardsData
            .map((card) => GeneratedFlashcard.fromJson(card))
            .toList();
        final session = GenerationSession.fromJson(sessionData);
        return session.copyWith(generatedFlashcards: flashcards);
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to get session',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to get generation session: ${e.toString()}',
      );
    }
  }
  Future<List<GenerationSession>> getUserSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/ai-generation/sessions?limit=$limit&offset=$offset',
      );
      if (response['success'] == true) {
        final sessionsData = response['data']['sessions'] as List;
        return sessionsData
            .map((session) => GenerationSession.fromJson(session))
            .toList();
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to get sessions',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to get user sessions: ${e.toString()}',
      );
    }
  }
  Future<void> updateGeneratedFlashcard({
    required String flashcardId,
    required String sessionId,
    required FlashcardUpdates updates,
  }) async {
    try {
      final requestBody = {
        'sessionId': sessionId,
        ...updates.toJson(),
      };
      final response = await _apiService.put(
        '/ai-generation/flashcards/$flashcardId',
        requestBody,
      );
      if (response['success'] != true) {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to update flashcard',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to update flashcard: ${e.toString()}',
      );
    }
  }
  Future<void> deleteGeneratedFlashcard({
    required String flashcardId,
    required String sessionId,
  }) async {
    try {
      final requestBody = {'sessionId': sessionId};
      final response = await _apiService.delete(
        '/ai-generation/flashcards/$flashcardId',
        requestBody,
      );
      if (response['success'] != true) {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to delete flashcard',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to delete flashcard: ${e.toString()}',
      );
    }
  }
  Future<GeneratedFlashcard> regenerateFlashcard({
    required String flashcardId,
    required String sessionId,
    String? feedback,
  }) async {
    try {
      final requestBody = {
        'sessionId': sessionId,
        'feedback': feedback,
      };
      final response = await _apiService.post(
        '/ai-generation/flashcards/$flashcardId/regenerate',
        requestBody,
      );
      if (response['success'] == true) {
        return GeneratedFlashcard.fromJson(response['data']['flashcard']);
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to regenerate flashcard',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to regenerate flashcard: ${e.toString()}',
      );
    }
  }
  Future<List<Flashcard>> approveAndSaveFlashcards({
    required String sessionId,
    List<String>? flashcardIds,
  }) async {
    try {
      final requestBody = {
        'sessionId': sessionId,
        if (flashcardIds != null) 'flashcardIds': flashcardIds,
      };
      final response = await _apiService.post(
        '/ai-generation/approve',
        requestBody,
      );
      if (response['success'] == true) {
        final flashcardsData = response['data']['flashcards'] as List;
        return flashcardsData
            .map((card) => Flashcard.fromJson(card))
            .toList();
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to approve flashcards',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to approve and save flashcards: ${e.toString()}',
      );
    }
  }
  Future<AIGenerationPreferences> getUserPreferences() async {
    try {
      final response = await _apiService.get('/ai-generation/preferences');
      if (response['success'] == true) {
        return AIGenerationPreferences.fromJson(response['data']['preferences']);
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to get preferences',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to get user preferences: ${e.toString()}',
      );
    }
  }
  Future<void> updateUserPreferences(AIGenerationPreferences preferences) async {
    try {
      final response = await _apiService.put(
        '/ai-generation/preferences',
        preferences.toJson(),
      );
      if (response['success'] != true) {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to update preferences',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to update preferences: ${e.toString()}',
      );
    }
  }
  Future<AIGenerationStats> getUserStats() async {
    try {
      final response = await _apiService.get('/ai-generation/stats');
      if (response['success'] == true) {
        return AIGenerationStats.fromJson(response['data']['stats']);
      } else {
        throw AIGenerationException(
          response['error']['message'] ?? 'Failed to get statistics',
        );
      }
    } catch (e) {
      throw AIGenerationException(
        'Failed to get user statistics: ${e.toString()}',
      );
    }
  }
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final response = await _apiService.get('/ai-generation/health');
      return response['data'] ?? {};
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
class AIGenerationResult {
  final String sessionId;
  final List<GeneratedFlashcard> flashcards;
  final ContentAnalysis? analysis;
  final Map<String, dynamic>? metadata;
  const AIGenerationResult({
    required this.sessionId,
    required this.flashcards,
    this.analysis,
    this.metadata,
  });
  factory AIGenerationResult.fromJson(Map<String, dynamic> json) {
    return AIGenerationResult(
      sessionId: json['sessionId'] as String,
      flashcards: (json['flashcards'] as List)
          .map((card) => GeneratedFlashcard.fromJson(card))
          .toList(),
      analysis: json['analysis'] != null 
          ? ContentAnalysis.fromJson(json['analysis'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
class AIGenerationPreferences {
  final DifficultyLevel defaultDifficulty;
  final List<String> preferredSubjects;
  final int defaultFlashcardCount;
  final bool includeExplanations;
  final bool includeMemoryTips;
  final double qualityThreshold;
  const AIGenerationPreferences({
    required this.defaultDifficulty,
    required this.preferredSubjects,
    required this.defaultFlashcardCount,
    required this.includeExplanations,
    required this.includeMemoryTips,
    required this.qualityThreshold,
  });
  factory AIGenerationPreferences.fromJson(Map<String, dynamic> json) {
    return AIGenerationPreferences(
      defaultDifficulty: DifficultyLevel.fromString(
        json['defaultDifficulty'] as String? ?? 'intermediate',
      ),
      preferredSubjects: List<String>.from(json['preferredSubjects'] ?? []),
      defaultFlashcardCount: json['defaultFlashcardCount'] as int? ?? 5,
      includeExplanations: json['includeExplanations'] as bool? ?? false,
      includeMemoryTips: json['includeMemoryTips'] as bool? ?? false,
      qualityThreshold: (json['qualityThreshold'] as num?)?.toDouble() ?? 0.7,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'defaultDifficulty': defaultDifficulty.value,
      'preferredSubjects': preferredSubjects,
      'defaultFlashcardCount': defaultFlashcardCount,
      'includeExplanations': includeExplanations,
      'includeMemoryTips': includeMemoryTips,
      'qualityThreshold': qualityThreshold,
    };
  }
}
class AIGenerationStats {
  final int totalSessions;
  final int successfulSessions;
  final int failedSessions;
  final int totalFlashcards;
  final double averageConfidence;
  final List<String> mostCommonSubjects;
  const AIGenerationStats({
    required this.totalSessions,
    required this.successfulSessions,
    required this.failedSessions,
    required this.totalFlashcards,
    required this.averageConfidence,
    required this.mostCommonSubjects,
  });
  factory AIGenerationStats.fromJson(Map<String, dynamic> json) {
    return AIGenerationStats(
      totalSessions: json['totalSessions'] as int? ?? 0,
      successfulSessions: json['successfulSessions'] as int? ?? 0,
      failedSessions: json['failedSessions'] as int? ?? 0,
      totalFlashcards: json['totalFlashcards'] as int? ?? 0,
      averageConfidence: (json['averageConfidence'] as num?)?.toDouble() ?? 0.0,
      mostCommonSubjects: List<String>.from(json['mostCommonSubjects'] ?? []),
    );
  }
  double get successRate => totalSessions > 0 ? successfulSessions / totalSessions : 0.0;
  double get averageFlashcardsPerSession => successfulSessions > 0 ? totalFlashcards / successfulSessions : 0.0;
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