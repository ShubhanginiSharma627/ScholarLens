/// AI Flashcard Generation Data Models
/// 
/// This file contains all data models and interfaces for the AI-powered
/// flashcard generation system, extending the existing flashcard infrastructure.

import 'flashcard.dart';

/// Represents different types of content sources for AI analysis
enum ContentType {
  image('image'),
  pdf('pdf'),
  text('text'),
  topic('topic');

  const ContentType(this.value);
  final String value;

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ContentType.text,
    );
  }
}

/// Represents the status of a generation session
enum GenerationStatus {
  processing('processing'),
  generated('generated'),
  reviewed('reviewed'),
  saved('saved'),
  failed('failed');

  const GenerationStatus(this.value);
  final String value;

  static GenerationStatus fromString(String value) {
    return GenerationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GenerationStatus.processing,
    );
  }
}

/// Difficulty levels for AI-generated content (extends existing Difficulty enum)
enum DifficultyLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const DifficultyLevel(this.value);
  final String value;

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => DifficultyLevel.intermediate,
    );
  }

  /// Convert to existing Difficulty enum for compatibility
  Difficulty toDifficulty() {
    switch (this) {
      case DifficultyLevel.beginner:
        return Difficulty.easy;
      case DifficultyLevel.intermediate:
        return Difficulty.medium;
      case DifficultyLevel.advanced:
        return Difficulty.hard;
    }
  }

  /// Create from existing Difficulty enum
  static DifficultyLevel fromDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return DifficultyLevel.beginner;
      case Difficulty.medium:
        return DifficultyLevel.intermediate;
      case Difficulty.hard:
        return DifficultyLevel.advanced;
    }
  }
}

/// Metadata for content sources
class ContentMetadata {
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final DateTime? uploadedAt;
  final Map<String, dynamic>? additionalData;

  const ContentMetadata({
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.uploadedAt,
    this.additionalData,
  });

  factory ContentMetadata.fromJson(Map<String, dynamic> json) {
    return ContentMetadata(
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      uploadedAt: json['uploaded_at'] != null 
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
      additionalData: json['additional_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'additional_data': additionalData,
    };
  }
}

/// Represents extracted content from various sources
class ExtractedContent {
  final String text;
  final ContentType contentType;
  final ContentMetadata metadata;
  final List<String> concepts;

  const ExtractedContent({
    required this.text,
    required this.contentType,
    required this.metadata,
    required this.concepts,
  });

  factory ExtractedContent.fromJson(Map<String, dynamic> json) {
    return ExtractedContent(
      text: json['text'] as String,
      contentType: ContentType.fromString(json['content_type'] as String),
      metadata: ContentMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      concepts: List<String>.from(json['concepts'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'content_type': contentType.value,
      'metadata': metadata.toJson(),
      'concepts': concepts,
    };
  }
}

/// Represents the result of content validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  factory ValidationResult.valid() {
    return const ValidationResult(
      isValid: true,
      errors: [],
      warnings: [],
    );
  }

  factory ValidationResult.invalid(List<String> errors, [List<String>? warnings]) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings ?? [],
    );
  }
}

/// Represents AI analysis of content
class ContentAnalysis {
  final String id;
  final List<String> keyTopics;
  final List<String> learningObjectives;
  final DifficultyLevel estimatedDifficulty;
  final String subjectArea;
  final Map<String, double> conceptWeights;
  final DateTime analyzedAt;

  const ContentAnalysis({
    required this.id,
    required this.keyTopics,
    required this.learningObjectives,
    required this.estimatedDifficulty,
    required this.subjectArea,
    required this.conceptWeights,
    required this.analyzedAt,
  });

  factory ContentAnalysis.fromJson(Map<String, dynamic> json) {
    return ContentAnalysis(
      id: json['id'] as String,
      keyTopics: List<String>.from(json['key_topics'] as List),
      learningObjectives: List<String>.from(json['learning_objectives'] as List),
      estimatedDifficulty: DifficultyLevel.fromString(json['estimated_difficulty'] as String),
      subjectArea: json['subject_area'] as String,
      conceptWeights: Map<String, double>.from(json['concept_weights'] as Map),
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key_topics': keyTopics,
      'learning_objectives': learningObjectives,
      'estimated_difficulty': estimatedDifficulty.value,
      'subject_area': subjectArea,
      'concept_weights': conceptWeights,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

/// Options for AI flashcard generation
class GenerationOptions {
  final int count;
  final DifficultyLevel? minDifficulty;
  final DifficultyLevel? maxDifficulty;
  final List<String> subjects;
  final List<String> focusAreas;
  final bool includeConcepts;
  final bool includeExplanations;

  const GenerationOptions({
    required this.count,
    this.minDifficulty,
    this.maxDifficulty,
    required this.subjects,
    required this.focusAreas,
    this.includeConcepts = true,
    this.includeExplanations = false,
  });

  factory GenerationOptions.fromJson(Map<String, dynamic> json) {
    return GenerationOptions(
      count: json['count'] as int,
      minDifficulty: json['min_difficulty'] != null 
          ? DifficultyLevel.fromString(json['min_difficulty'] as String)
          : null,
      maxDifficulty: json['max_difficulty'] != null 
          ? DifficultyLevel.fromString(json['max_difficulty'] as String)
          : null,
      subjects: List<String>.from(json['subjects'] as List),
      focusAreas: List<String>.from(json['focus_areas'] as List),
      includeConcepts: json['include_concepts'] as bool? ?? true,
      includeExplanations: json['include_explanations'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'min_difficulty': minDifficulty?.value,
      'max_difficulty': maxDifficulty?.value,
      'subjects': subjects,
      'focus_areas': focusAreas,
      'include_concepts': includeConcepts,
      'include_explanations': includeExplanations,
    };
  }
}

/// Represents a quality score for generated content
class QualityScore {
  final double overall;
  final double clarity;
  final double accuracy;
  final double difficulty;
  final double relevance;
  final List<String> feedback;

  const QualityScore({
    required this.overall,
    required this.clarity,
    required this.accuracy,
    required this.difficulty,
    required this.relevance,
    required this.feedback,
  });

  factory QualityScore.fromJson(Map<String, dynamic> json) {
    return QualityScore(
      overall: (json['overall'] as num).toDouble(),
      clarity: (json['clarity'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      relevance: (json['relevance'] as num).toDouble(),
      feedback: List<String>.from(json['feedback'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'clarity': clarity,
      'accuracy': accuracy,
      'difficulty': difficulty,
      'relevance': relevance,
      'feedback': feedback,
    };
  }

  bool get isAcceptable => overall >= 0.7;
}

/// Represents an AI-generated flashcard before integration
class GeneratedFlashcard {
  final String id;
  final String question;
  final String answer;
  final DifficultyLevel difficulty;
  final String subject;
  final List<String> concepts;
  final double confidence;
  final String? explanation;
  final String? memoryTip;
  final QualityScore? qualityScore;
  final DateTime generatedAt;

  const GeneratedFlashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.difficulty,
    required this.subject,
    required this.concepts,
    required this.confidence,
    this.explanation,
    this.memoryTip,
    this.qualityScore,
    required this.generatedAt,
  });

  factory GeneratedFlashcard.fromJson(Map<String, dynamic> json) {
    return GeneratedFlashcard(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      difficulty: DifficultyLevel.fromString(json['difficulty'] as String),
      subject: json['subject'] as String,
      concepts: List<String>.from(json['concepts'] as List),
      confidence: (json['confidence'] as num).toDouble(),
      explanation: json['explanation'] as String?,
      memoryTip: json['memory_tip'] as String?,
      qualityScore: json['quality_score'] != null 
          ? QualityScore.fromJson(json['quality_score'] as Map<String, dynamic>)
          : null,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'difficulty': difficulty.value,
      'subject': subject,
      'concepts': concepts,
      'confidence': confidence,
      'explanation': explanation,
      'memory_tip': memoryTip,
      'quality_score': qualityScore?.toJson(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  /// Convert to existing Flashcard model for system integration
  Flashcard toFlashcard({String? userId, String? deckId}) {
    return Flashcard(
      id: id,
      subject: subject,
      question: question,
      answer: answer,
      difficulty: difficulty.toDifficulty(),
      nextReviewDate: DateTime.now().add(const Duration(days: 1)),
      reviewCount: 0,
      createdAt: generatedAt,
      category: concepts.isNotEmpty ? concepts.first : null,
    );
  }

  /// Create a copy with updated fields
  GeneratedFlashcard copyWith({
    String? id,
    String? question,
    String? answer,
    DifficultyLevel? difficulty,
    String? subject,
    List<String>? concepts,
    double? confidence,
    String? explanation,
    String? memoryTip,
    QualityScore? qualityScore,
    DateTime? generatedAt,
  }) {
    return GeneratedFlashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      subject: subject ?? this.subject,
      concepts: concepts ?? this.concepts,
      confidence: confidence ?? this.confidence,
      explanation: explanation ?? this.explanation,
      memoryTip: memoryTip ?? this.memoryTip,
      qualityScore: qualityScore ?? this.qualityScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Represents updates to a flashcard during review
class FlashcardUpdates {
  final String? question;
  final String? answer;
  final DifficultyLevel? difficulty;
  final String? subject;
  final List<String>? concepts;
  final String? explanation;
  final String? memoryTip;

  const FlashcardUpdates({
    this.question,
    this.answer,
    this.difficulty,
    this.subject,
    this.concepts,
    this.explanation,
    this.memoryTip,
  });

  factory FlashcardUpdates.fromJson(Map<String, dynamic> json) {
    return FlashcardUpdates(
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      difficulty: json['difficulty'] != null 
          ? DifficultyLevel.fromString(json['difficulty'] as String)
          : null,
      subject: json['subject'] as String?,
      concepts: json['concepts'] != null 
          ? List<String>.from(json['concepts'] as List)
          : null,
      explanation: json['explanation'] as String?,
      memoryTip: json['memory_tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'difficulty': difficulty?.value,
      'subject': subject,
      'concepts': concepts,
      'explanation': explanation,
      'memory_tip': memoryTip,
    };
  }
}

/// Represents a content source for AI analysis
class ContentSource {
  final String id;
  final ContentType type;
  final String? originalFileName;
  final String content;
  final ContentMetadata metadata;
  final DateTime uploadedAt;

  const ContentSource({
    required this.id,
    required this.type,
    this.originalFileName,
    required this.content,
    required this.metadata,
    required this.uploadedAt,
  });

  factory ContentSource.fromJson(Map<String, dynamic> json) {
    return ContentSource(
      id: json['id'] as String,
      type: ContentType.fromString(json['type'] as String),
      originalFileName: json['original_file_name'] as String?,
      content: json['content'] as String,
      metadata: ContentMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'original_file_name': originalFileName,
      'content': content,
      'metadata': metadata.toJson(),
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

/// Represents a complete AI generation session
class GenerationSession {
  final String id;
  final String userId;
  final ContentSource contentSource;
  final List<GeneratedFlashcard> generatedFlashcards;
  final GenerationStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const GenerationSession({
    required this.id,
    required this.userId,
    required this.contentSource,
    required this.generatedFlashcards,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.metadata,
  });

  factory GenerationSession.fromJson(Map<String, dynamic> json) {
    return GenerationSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentSource: ContentSource.fromJson(json['content_source'] as Map<String, dynamic>),
      generatedFlashcards: (json['generated_flashcards'] as List)
          .map((card) => GeneratedFlashcard.fromJson(card as Map<String, dynamic>))
          .toList(),
      status: GenerationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content_source': contentSource.toJson(),
      'generated_flashcards': generatedFlashcards.map((card) => card.toJson()).toList(),
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  GenerationSession copyWith({
    String? id,
    String? userId,
    ContentSource? contentSource,
    List<GeneratedFlashcard>? generatedFlashcards,
    GenerationStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return GenerationSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentSource: contentSource ?? this.contentSource,
      generatedFlashcards: generatedFlashcards ?? this.generatedFlashcards,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isComplete => status == GenerationStatus.saved;
  bool get hasError => status == GenerationStatus.failed;
  int get flashcardCount => generatedFlashcards.length;
}