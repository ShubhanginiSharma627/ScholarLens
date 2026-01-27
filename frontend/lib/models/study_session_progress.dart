import 'flashcard.dart';

/// Model for tracking real-time progress during a flashcard study session
/// Validates: Requirements 3.1, 3.2, 3.3
class StudySessionProgress {
  final int currentCardIndex;
  final int totalCards;
  final int correctCount;
  final int incorrectCount;
  final Map<String, Difficulty> cardRatings;
  final DateTime sessionStartTime;
  final String? subject;

  StudySessionProgress({
    required this.currentCardIndex,
    required this.totalCards,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.cardRatings = const {},
    DateTime? sessionStartTime,
    this.subject,
  }) : sessionStartTime = sessionStartTime ?? DateTime.now();

  /// Creates initial session progress
  factory StudySessionProgress.initial({
    required int totalCards,
    String? subject,
  }) {
    return StudySessionProgress(
      currentCardIndex: 0,
      totalCards: totalCards,
      correctCount: 0,
      incorrectCount: 0,
      cardRatings: {},
      sessionStartTime: DateTime.now(),
      subject: subject,
    );
  }

  /// Completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (totalCards == 0) return 0.0;
    return currentCardIndex / totalCards;
  }

  /// Accuracy percentage (0.0 to 1.0)
  double get accuracyPercentage {
    final total = correctCount + incorrectCount;
    if (total == 0) return 0.0;
    return correctCount / total;
  }

  /// Whether the session is complete
  bool get isComplete => currentCardIndex >= totalCards;

  /// Number of cards remaining
  int get remainingCards => (totalCards - currentCardIndex).clamp(0, totalCards);

  /// Session duration
  Duration get sessionDuration => DateTime.now().difference(sessionStartTime);

  /// Average time per card (in seconds)
  double get averageTimePerCard {
    if (currentCardIndex == 0) return 0.0;
    return sessionDuration.inSeconds / currentCardIndex;
  }

  /// Number of cards rated as easy
  int get easyCount => cardRatings.values.where((d) => d == Difficulty.easy).length;

  /// Number of cards rated as medium
  int get mediumCount => cardRatings.values.where((d) => d == Difficulty.medium).length;

  /// Number of cards rated as hard
  int get hardCount => cardRatings.values.where((d) => d == Difficulty.hard).length;

  /// Updates progress when moving to next card
  StudySessionProgress nextCard() {
    if (isComplete) return this;
    
    return copyWith(
      currentCardIndex: currentCardIndex + 1,
    );
  }

  /// Updates progress when moving to previous card
  StudySessionProgress previousCard() {
    if (currentCardIndex <= 0) return this;
    
    return copyWith(
      currentCardIndex: currentCardIndex - 1,
    );
  }

  /// Updates progress when a card is rated
  StudySessionProgress rateCard(String cardId, Difficulty difficulty) {
    final newRatings = Map<String, Difficulty>.from(cardRatings);
    newRatings[cardId] = difficulty;
    
    // Update correct/incorrect counts based on difficulty
    int newCorrectCount = correctCount;
    int newIncorrectCount = incorrectCount;
    
    // If this card was previously rated, adjust counts
    if (cardRatings.containsKey(cardId)) {
      final previousDifficulty = cardRatings[cardId]!;
      if (previousDifficulty == Difficulty.easy || previousDifficulty == Difficulty.medium) {
        newCorrectCount--;
      } else {
        newIncorrectCount--;
      }
    }
    
    // Add new rating to counts
    if (difficulty == Difficulty.easy || difficulty == Difficulty.medium) {
      newCorrectCount++;
    } else {
      newIncorrectCount++;
    }
    
    return copyWith(
      cardRatings: newRatings,
      correctCount: newCorrectCount,
      incorrectCount: newIncorrectCount,
    );
  }

  /// Jumps to a specific card index
  StudySessionProgress jumpToCard(int index) {
    final clampedIndex = index.clamp(0, totalCards);
    return copyWith(currentCardIndex: clampedIndex);
  }

  /// Resets the session progress
  StudySessionProgress reset() {
    return StudySessionProgress.initial(
      totalCards: totalCards,
      subject: subject,
    );
  }

  /// Creates a copy with updated fields
  StudySessionProgress copyWith({
    int? currentCardIndex,
    int? totalCards,
    int? correctCount,
    int? incorrectCount,
    Map<String, Difficulty>? cardRatings,
    DateTime? sessionStartTime,
    String? subject,
  }) {
    return StudySessionProgress(
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      totalCards: totalCards ?? this.totalCards,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      cardRatings: cardRatings ?? this.cardRatings,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      subject: subject ?? this.subject,
    );
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'currentCardIndex': currentCardIndex,
      'totalCards': totalCards,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'cardRatings': cardRatings.map((key, value) => MapEntry(key, value.name)),
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'subject': subject,
    };
  }

  /// Creates from JSON
  factory StudySessionProgress.fromJson(Map<String, dynamic> json) {
    final ratingsMap = (json['cardRatings'] as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(
              key,
              Difficulty.values.firstWhere(
                (d) => d.name == value,
                orElse: () => Difficulty.medium,
              ),
            ));

    return StudySessionProgress(
      currentCardIndex: json['currentCardIndex'] as int,
      totalCards: json['totalCards'] as int,
      correctCount: json['correctCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      cardRatings: ratingsMap,
      sessionStartTime: DateTime.parse(json['sessionStartTime'] as String),
      subject: json['subject'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudySessionProgress &&
        other.currentCardIndex == currentCardIndex &&
        other.totalCards == totalCards &&
        other.correctCount == correctCount &&
        other.incorrectCount == incorrectCount &&
        other.sessionStartTime == sessionStartTime &&
        other.subject == subject;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentCardIndex,
      totalCards,
      correctCount,
      incorrectCount,
      sessionStartTime,
      subject,
    );
  }

  @override
  String toString() {
    return 'StudySessionProgress('
        'currentCardIndex: $currentCardIndex, '
        'totalCards: $totalCards, '
        'correctCount: $correctCount, '
        'incorrectCount: $incorrectCount, '
        'completionPercentage: ${(completionPercentage * 100).round()}%, '
        'accuracyPercentage: ${(accuracyPercentage * 100).round()}%'
        ')';
  }
}