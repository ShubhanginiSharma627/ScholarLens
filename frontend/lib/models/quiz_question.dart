/// Represents a quiz question with multiple choice options
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Creates a QuizQuestion from JSON
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List<dynamic>),
      correctIndex: json['correct_index'] as int,
      explanation: json['explanation'] as String,
    );
  }

  /// Converts QuizQuestion to JSON
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correct_index': correctIndex,
      'explanation': explanation,
    };
  }

  /// Gets the correct answer text
  String get correctAnswer {
    if (correctIndex >= 0 && correctIndex < options.length) {
      return options[correctIndex];
    }
    return '';
  }

  /// Checks if the given answer index is correct
  bool isCorrectAnswer(int answerIndex) {
    return answerIndex == correctIndex;
  }

  /// Creates a copy with updated fields
  QuizQuestion copyWith({
    String? question,
    List<String>? options,
    int? correctIndex,
    String? explanation,
  }) {
    return QuizQuestion(
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizQuestion &&
        other.question == question &&
        _listEquals(other.options, options) &&
        other.correctIndex == correctIndex &&
        other.explanation == explanation;
  }

  @override
  int get hashCode {
    return Object.hash(
      question,
      Object.hashAll(options),
      correctIndex,
      explanation,
    );
  }

  @override
  String toString() {
    return 'QuizQuestion(question: $question, options: ${options.length}, correctIndex: $correctIndex, explanation: ${explanation.length} chars)';
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