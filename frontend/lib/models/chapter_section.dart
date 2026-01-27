/// Represents a section within a chapter for the Chapter Reading Interface
class ChapterSection {
  final int sectionNumber;
  final String title;
  final String content;
  final List<String> keyTerms;
  final bool isCompleted;
  final DateTime? completedAt;

  const ChapterSection({
    required this.sectionNumber,
    required this.title,
    required this.content,
    required this.keyTerms,
    required this.isCompleted,
    this.completedAt,
  });

  /// Creates a ChapterSection from JSON
  factory ChapterSection.fromJson(Map<String, dynamic> json) {
    return ChapterSection(
      sectionNumber: json['section_number'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      keyTerms: List<String>.from(json['key_terms'] as List),
      isCompleted: json['is_completed'] as bool,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Converts ChapterSection to JSON
  Map<String, dynamic> toJson() {
    return {
      'section_number': sectionNumber,
      'title': title,
      'content': content,
      'key_terms': keyTerms,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Creates a copy with updated fields for immutable updates
  ChapterSection copyWith({
    int? sectionNumber,
    String? title,
    String? content,
    List<String>? keyTerms,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ChapterSection(
      sectionNumber: sectionNumber ?? this.sectionNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      keyTerms: keyTerms ?? this.keyTerms,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Creates a new ChapterSection with default values
  factory ChapterSection.create({
    required int sectionNumber,
    required String title,
    required String content,
    List<String>? keyTerms,
  }) {
    return ChapterSection(
      sectionNumber: sectionNumber,
      title: title,
      content: content,
      keyTerms: keyTerms ?? [],
      isCompleted: false,
      completedAt: null,
    );
  }

  /// Marks the section as completed
  ChapterSection markCompleted() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  /// Marks the section as incomplete
  ChapterSection markIncomplete() {
    return copyWith(
      isCompleted: false,
      clearCompletedAt: true,
    );
  }

  /// Gets the estimated reading time in minutes based on content length
  /// Assumes average reading speed of 200 words per minute
  int get estimatedReadingTimeMinutes {
    final wordCount = content.split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes; // Minimum 1 minute
  }

  /// Gets the word count of the section content
  int get wordCount {
    return content.split(RegExp(r'\s+')).length;
  }

  /// Checks if the section has key terms
  bool get hasKeyTerms => keyTerms.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterSection &&
        other.sectionNumber == sectionNumber &&
        other.title == title &&
        other.content == content &&
        _listEquals(other.keyTerms, keyTerms) &&
        other.isCompleted == isCompleted &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      sectionNumber,
      title,
      content,
      Object.hashAll(keyTerms),
      isCompleted,
      completedAt,
    );
  }

  @override
  String toString() {
    return 'ChapterSection(sectionNumber: $sectionNumber, title: $title, isCompleted: $isCompleted, keyTerms: ${keyTerms.length}, wordCount: $wordCount)';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}