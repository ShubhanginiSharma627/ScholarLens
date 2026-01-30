import 'quiz_question.dart';
class LessonContent {
  final String lessonTitle;
  final String summaryMarkdown;
  final String audioTranscript;
  final List<QuizQuestion> quiz;
  final DateTime createdAt;
  const LessonContent({
    required this.lessonTitle,
    required this.summaryMarkdown,
    required this.audioTranscript,
    required this.quiz,
    required this.createdAt,
  });
  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      lessonTitle: json['lesson_title'] as String,
      summaryMarkdown: json['summary_markdown'] as String,
      audioTranscript: json['audio_transcript'] as String,
      quiz: (json['quiz'] as List<dynamic>)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'lesson_title': lessonTitle,
      'summary_markdown': summaryMarkdown,
      'audio_transcript': audioTranscript,
      'quiz': quiz.map((q) => q.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
  LessonContent copyWith({
    String? lessonTitle,
    String? summaryMarkdown,
    String? audioTranscript,
    List<QuizQuestion>? quiz,
    DateTime? createdAt,
  }) {
    return LessonContent(
      lessonTitle: lessonTitle ?? this.lessonTitle,
      summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
      audioTranscript: audioTranscript ?? this.audioTranscript,
      quiz: quiz ?? this.quiz,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonContent &&
        other.lessonTitle == lessonTitle &&
        other.summaryMarkdown == summaryMarkdown &&
        other.audioTranscript == audioTranscript &&
        _listEquals(other.quiz, quiz) &&
        other.createdAt == createdAt;
  }
  @override
  int get hashCode {
    return Object.hash(
      lessonTitle,
      summaryMarkdown,
      audioTranscript,
      Object.hashAll(quiz),
      createdAt,
    );
  }
  @override
  String toString() {
    return 'LessonContent(lessonTitle: $lessonTitle, summaryMarkdown: ${summaryMarkdown.length} chars, audioTranscript: ${audioTranscript.length} chars, quiz: ${quiz.length} questions, createdAt: $createdAt)';
  }
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}