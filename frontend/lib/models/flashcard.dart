class Flashcard {
  final String id;
  final String subject;
  final String question;
  final String answer;
  final Difficulty difficulty;
  final DateTime nextReviewDate;
  final int reviewCount;
  final DateTime createdAt;
  final String? category;
  const Flashcard({
    required this.id,
    required this.subject,
    required this.question,
    required this.answer,
    required this.difficulty,
    required this.nextReviewDate,
    required this.reviewCount,
    required this.createdAt,
    this.category,
  });
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final studyStats = json['studyStats'] as Map<String, dynamic>?;
    
    return Flashcard(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? 
               (json['tags'] as List?)?.first?.toString() ?? 
               'General',
      question: json['question'] as String,
      answer: json['answer'] as String,
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      nextReviewDate: DateTime.parse(
        json['nextReviewDate'] as String? ?? 
        json['next_review_date'] as String? ?? 
        studyStats?['nextReview'] as String? ?? 
        DateTime.now().add(const Duration(days: 1)).toIso8601String()
      ),
      reviewCount: json['reviewCount'] as int? ?? 
                   json['review_count'] as int? ?? 
                   studyStats?['timesStudied'] as int? ?? 
                   0,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? 
        json['created_at'] as String? ?? 
        DateTime.now().toIso8601String()
      ),
      category: json['category'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'question': question,
      'answer': answer,
      'difficulty': difficulty.name,
      'next_review_date': nextReviewDate.toIso8601String(),
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'category': category,
    };
  }
  bool get isDue => DateTime.now().isAfter(nextReviewDate);
  int get daysUntilReview {
    final now = DateTime.now();
    if (isDue) return 0;
    return nextReviewDate.difference(now).inDays;
  }
  factory Flashcard.create({
    required String subject,
    required String question,
    required String answer,
    String? category,
  }) {
    final now = DateTime.now();
    return Flashcard(
      id: '${now.millisecondsSinceEpoch}',
      subject: subject,
      question: question,
      answer: answer,
      difficulty: Difficulty.medium,
      nextReviewDate: now.add(const Duration(days: 1)), // Review tomorrow
      reviewCount: 0,
      createdAt: now,
      category: category,
    );
  }
  Flashcard updateAfterReview(Difficulty newDifficulty) {
    final now = DateTime.now();
    Duration nextInterval;
    switch (newDifficulty) {
      case Difficulty.easy:
        nextInterval = Duration(days: (reviewCount + 1) * 4);
        break;
      case Difficulty.medium:
        nextInterval = Duration(days: (reviewCount + 1) * 2);
        break;
      case Difficulty.hard:
        nextInterval = const Duration(days: 1);
        break;
    }
    return copyWith(
      difficulty: newDifficulty,
      nextReviewDate: now.add(nextInterval),
      reviewCount: reviewCount + 1,
    );
  }
  Flashcard copyWith({
    String? id,
    String? subject,
    String? question,
    String? answer,
    Difficulty? difficulty,
    DateTime? nextReviewDate,
    int? reviewCount,
    DateTime? createdAt,
    String? category,
  }) {
    return Flashcard(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flashcard &&
        other.id == id &&
        other.subject == subject &&
        other.question == question &&
        other.answer == answer &&
        other.difficulty == difficulty &&
        other.nextReviewDate == nextReviewDate &&
        other.reviewCount == reviewCount &&
        other.createdAt == createdAt &&
        other.category == category;
  }
  @override
  int get hashCode {
    return Object.hash(
      id,
      subject,
      question,
      answer,
      difficulty,
      nextReviewDate,
      reviewCount,
      createdAt,
      category,
    );
  }
  @override
  String toString() {
    return 'Flashcard(id: $id, subject: $subject, difficulty: $difficulty, reviewCount: $reviewCount, isDue: $isDue)';
  }
}
enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');
  const Difficulty(this.displayName);
  final String displayName;
}