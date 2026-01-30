class RecentSnap {
  final String id;
  final String problemTitle;
  final String subject;
  final String lessonId;
  final DateTime createdAt;
  final String? thumbnailPath;
  const RecentSnap({
    required this.id,
    required this.problemTitle,
    required this.subject,
    required this.lessonId,
    required this.createdAt,
    this.thumbnailPath,
  });
  factory RecentSnap.fromJson(Map<String, dynamic> json) {
    return RecentSnap(
      id: json['id'] as String,
      problemTitle: json['problem_title'] as String,
      subject: json['subject'] as String,
      lessonId: json['lesson_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      thumbnailPath: json['thumbnail_path'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'problem_title': problemTitle,
      'subject': subject,
      'lesson_id': lessonId,
      'created_at': createdAt.toIso8601String(),
      'thumbnail_path': thumbnailPath,
    };
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentSnap &&
        other.id == id &&
        other.problemTitle == problemTitle &&
        other.subject == subject &&
        other.lessonId == lessonId &&
        other.createdAt == createdAt &&
        other.thumbnailPath == thumbnailPath;
  }
  @override
  int get hashCode {
    return Object.hash(
      id,
      problemTitle,
      subject,
      lessonId,
      createdAt,
      thumbnailPath,
    );
  }
  @override
  String toString() {
    return 'RecentSnap(id: $id, problemTitle: $problemTitle, subject: $subject, lessonId: $lessonId, createdAt: $createdAt, thumbnailPath: $thumbnailPath)';
  }
}