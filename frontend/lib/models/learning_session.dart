import 'lesson_content.dart';
class LearningSession {
  final String id;
  final String subject;
  final String topic;
  final DateTime startTime;
  final DateTime endTime;
  final int questionsAnswered;
  final int correctAnswers;
  final LessonContent content;
  const LearningSession({
    required this.id,
    required this.subject,
    required this.topic,
    required this.startTime,
    required this.endTime,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.content,
  });
  factory LearningSession.fromJson(Map<String, dynamic> json) {
    return LearningSession(
      id: json['id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      questionsAnswered: json['questions_answered'] as int,
      correctAnswers: json['correct_answers'] as int,
      content: LessonContent.fromJson(json['content'] as Map<String, dynamic>),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'questions_answered': questionsAnswered,
      'correct_answers': correctAnswers,
      'content': content.toJson(),
    };
  }
  Duration get duration => endTime.difference(startTime);
  double get accuracy => questionsAnswered > 0 ? correctAnswers / questionsAnswered : 0.0;
  String get accuracyPercentage => '${(accuracy * 100).round()}%';
  String get formattedDuration {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = duration.inHours;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
  bool get isCompleted => questionsAnswered > 0;
  LearningSession copyWith({
    String? id,
    String? subject,
    String? topic,
    DateTime? startTime,
    DateTime? endTime,
    int? questionsAnswered,
    int? correctAnswers,
    LessonContent? content,
  }) {
    return LearningSession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      content: content ?? this.content,
    );
  }
  factory LearningSession.start({
    required String subject,
    required String topic,
    required LessonContent content,
  }) {
    final now = DateTime.now();
    return LearningSession(
      id: '${now.millisecondsSinceEpoch}',
      subject: subject,
      topic: topic,
      startTime: now,
      endTime: now, // Will be updated when session ends
      questionsAnswered: 0,
      correctAnswers: 0,
      content: content,
    );
  }
  LearningSession end({
    required int questionsAnswered,
    required int correctAnswers,
  }) {
    return copyWith(
      endTime: DateTime.now(),
      questionsAnswered: questionsAnswered,
      correctAnswers: correctAnswers,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningSession &&
        other.id == id &&
        other.subject == subject &&
        other.topic == topic &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.questionsAnswered == questionsAnswered &&
        other.correctAnswers == correctAnswers &&
        other.content == content;
  }
  @override
  int get hashCode {
    return Object.hash(
      id,
      subject,
      topic,
      startTime,
      endTime,
      questionsAnswered,
      correctAnswers,
      content,
    );
  }
  @override
  String toString() {
    return 'LearningSession(id: $id, subject: $subject, topic: $topic, duration: $formattedDuration, accuracy: $accuracyPercentage)';
  }
}