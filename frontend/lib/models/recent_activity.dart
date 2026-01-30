class RecentActivity {
  final String id;
  final String title;
  final String description;
  final String subject;
  final DateTime timestamp;
  final ActivityType type;
  const RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.timestamp,
    required this.type,
  });
  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      subject: json['subject'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.lesson,
      ),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
  RecentActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    DateTime? timestamp,
    ActivityType? type,
  }) {
    return RecentActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentActivity &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.subject == subject &&
        other.timestamp == timestamp &&
        other.type == type;
  }
  @override
  int get hashCode {
    return Object.hash(id, title, description, subject, timestamp, type);
  }
  @override
  String toString() {
    return 'RecentActivity(id: $id, title: $title, subject: $subject, type: $type, timestamp: $timestamp)';
  }
}
enum ActivityType {
  lesson('Lesson'),
  quiz('Quiz'),
  flashcard('Flashcard'),
  chat('Chat'),
  upload('Upload');
  const ActivityType(this.displayName);
  final String displayName;
}