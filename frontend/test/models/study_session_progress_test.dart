import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/flashcard.dart';
import 'package:scholar_lens/models/study_session_progress.dart';
void main() {
  group('StudySessionProgress', () {
    test('should create initial session progress correctly', () {
      final progress = StudySessionProgress.initial(
        totalCards: 10,
        subject: 'Mathematics',
      );
      expect(progress.currentCardIndex, equals(0));
      expect(progress.totalCards, equals(10));
      expect(progress.correctCount, equals(0));
      expect(progress.incorrectCount, equals(0));
      expect(progress.cardRatings, isEmpty);
      expect(progress.subject, equals('Mathematics'));
      expect(progress.completionPercentage, equals(0.0));
      expect(progress.accuracyPercentage, equals(0.0));
      expect(progress.isComplete, isFalse);
      expect(progress.remainingCards, equals(10));
    });
    test('should calculate completion percentage correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
      );
      expect(progress.completionPercentage, equals(0.3));
    });
    test('should handle zero total cards for completion percentage', () {
      final progress = StudySessionProgress(
        currentCardIndex: 0,
        totalCards: 0,
      );
      expect(progress.completionPercentage, equals(0.0));
    });
    test('should calculate accuracy percentage correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 5,
        totalCards: 10,
        correctCount: 3,
        incorrectCount: 2,
      );
      expect(progress.accuracyPercentage, equals(0.6)); // 3/5 = 0.6
    });
    test('should handle zero attempts for accuracy percentage', () {
      final progress = StudySessionProgress(
        currentCardIndex: 0,
        totalCards: 10,
        correctCount: 0,
        incorrectCount: 0,
      );
      expect(progress.accuracyPercentage, equals(0.0));
    });
    test('should navigate to next card correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
      );
      final nextProgress = progress.nextCard();
      expect(nextProgress.currentCardIndex, equals(3));
      expect(nextProgress.totalCards, equals(10));
    });
    test('should not navigate beyond last card', () {
      final progress = StudySessionProgress(
        currentCardIndex: 10,
        totalCards: 10,
      );
      final nextProgress = progress.nextCard();
      expect(nextProgress.currentCardIndex, equals(10));
      expect(nextProgress.isComplete, isTrue);
    });
    test('should navigate to previous card correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
      );
      final prevProgress = progress.previousCard();
      expect(prevProgress.currentCardIndex, equals(2));
    });
    test('should not navigate before first card', () {
      final progress = StudySessionProgress(
        currentCardIndex: 0,
        totalCards: 10,
      );
      final prevProgress = progress.previousCard();
      expect(prevProgress.currentCardIndex, equals(0));
    });
    test('should rate card and update counts correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
        correctCount: 1,
        incorrectCount: 0,
      );
      final ratedProgress = progress.rateCard('card1', Difficulty.easy);
      expect(ratedProgress.cardRatings['card1'], equals(Difficulty.easy));
      expect(ratedProgress.correctCount, equals(2));
      expect(ratedProgress.incorrectCount, equals(0));
    });
    test('should rate card as hard and update incorrect count', () {
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
        correctCount: 1,
        incorrectCount: 0,
      );
      final ratedProgress = progress.rateCard('card1', Difficulty.hard);
      expect(ratedProgress.cardRatings['card1'], equals(Difficulty.hard));
      expect(ratedProgress.correctCount, equals(1));
      expect(ratedProgress.incorrectCount, equals(1));
    });
    test('should update rating and adjust counts when re-rating card', () {
      final initialRatings = {'card1': Difficulty.easy};
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
        correctCount: 1,
        incorrectCount: 0,
        cardRatings: initialRatings,
      );
      final ratedProgress = progress.rateCard('card1', Difficulty.hard);
      expect(ratedProgress.cardRatings['card1'], equals(Difficulty.hard));
      expect(ratedProgress.correctCount, equals(0)); // Decreased from 1
      expect(ratedProgress.incorrectCount, equals(1)); // Increased from 0
    });
    test('should jump to specific card index', () {
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
      );
      final jumpedProgress = progress.jumpToCard(7);
      expect(jumpedProgress.currentCardIndex, equals(7));
    });
    test('should clamp jump to card index within bounds', () {
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
      );
      final jumpedProgress = progress.jumpToCard(15);
      expect(jumpedProgress.currentCardIndex, equals(10));
    });
    test('should reset session progress', () {
      final progress = StudySessionProgress(
        currentCardIndex: 5,
        totalCards: 10,
        correctCount: 3,
        incorrectCount: 2,
        cardRatings: {'card1': Difficulty.easy},
        subject: 'Mathematics',
      );
      final resetProgress = progress.reset();
      expect(resetProgress.currentCardIndex, equals(0));
      expect(resetProgress.totalCards, equals(10));
      expect(resetProgress.correctCount, equals(0));
      expect(resetProgress.incorrectCount, equals(0));
      expect(resetProgress.cardRatings, isEmpty);
      expect(resetProgress.subject, equals('Mathematics'));
    });
    test('should count difficulty ratings correctly', () {
      final ratings = {
        'card1': Difficulty.easy,
        'card2': Difficulty.medium,
        'card3': Difficulty.hard,
        'card4': Difficulty.easy,
        'card5': Difficulty.hard,
      };
      final progress = StudySessionProgress(
        currentCardIndex: 5,
        totalCards: 10,
        cardRatings: ratings,
      );
      expect(progress.easyCount, equals(2));
      expect(progress.mediumCount, equals(1));
      expect(progress.hardCount, equals(2));
    });
    test('should calculate remaining cards correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
      );
      expect(progress.remainingCards, equals(7));
    });
    test('should handle remaining cards when complete', () {
      final progress = StudySessionProgress(
        currentCardIndex: 10,
        totalCards: 10,
      );
      expect(progress.remainingCards, equals(0));
      expect(progress.isComplete, isTrue);
    });
    test('should serialize to and from JSON correctly', () {
      final originalProgress = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
        correctCount: 2,
        incorrectCount: 1,
        cardRatings: {
          'card1': Difficulty.easy,
          'card2': Difficulty.hard,
        },
        sessionStartTime: DateTime(2024, 1, 1, 12, 0, 0),
        subject: 'Mathematics',
      );
      final json = originalProgress.toJson();
      final deserializedProgress = StudySessionProgress.fromJson(json);
      expect(deserializedProgress.currentCardIndex, equals(originalProgress.currentCardIndex));
      expect(deserializedProgress.totalCards, equals(originalProgress.totalCards));
      expect(deserializedProgress.correctCount, equals(originalProgress.correctCount));
      expect(deserializedProgress.incorrectCount, equals(originalProgress.incorrectCount));
      expect(deserializedProgress.cardRatings, equals(originalProgress.cardRatings));
      expect(deserializedProgress.sessionStartTime, equals(originalProgress.sessionStartTime));
      expect(deserializedProgress.subject, equals(originalProgress.subject));
    });
    test('should handle copyWith correctly', () {
      final progress = StudySessionProgress(
        currentCardIndex: 2,
        totalCards: 10,
        correctCount: 1,
        incorrectCount: 0,
        subject: 'Mathematics',
      );
      final copiedProgress = progress.copyWith(
        currentCardIndex: 5,
        correctCount: 3,
      );
      expect(copiedProgress.currentCardIndex, equals(5));
      expect(copiedProgress.correctCount, equals(3));
      expect(copiedProgress.totalCards, equals(10)); // Unchanged
      expect(copiedProgress.incorrectCount, equals(0)); // Unchanged
      expect(copiedProgress.subject, equals('Mathematics')); // Unchanged
    });
    test('should calculate session duration and average time per card', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 10));
      final progress = StudySessionProgress(
        currentCardIndex: 5,
        totalCards: 10,
        sessionStartTime: startTime,
      );
      expect(progress.sessionDuration.inMinutes, greaterThanOrEqualTo(9));
      expect(progress.averageTimePerCard, greaterThan(0));
    });
    test('should handle zero cards for average time calculation', () {
      final progress = StudySessionProgress(
        currentCardIndex: 0,
        totalCards: 10,
      );
      expect(progress.averageTimePerCard, equals(0.0));
    });
    test('should implement equality correctly', () {
      final progress1 = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
        correctCount: 2,
        incorrectCount: 1,
        sessionStartTime: DateTime(2024, 1, 1, 12, 0, 0),
        subject: 'Mathematics',
      );
      final progress2 = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
        correctCount: 2,
        incorrectCount: 1,
        sessionStartTime: DateTime(2024, 1, 1, 12, 0, 0),
        subject: 'Mathematics',
      );
      final progress3 = StudySessionProgress(
        currentCardIndex: 4, // Different
        totalCards: 10,
        correctCount: 2,
        incorrectCount: 1,
        sessionStartTime: DateTime(2024, 1, 1, 12, 0, 0),
        subject: 'Mathematics',
      );
      expect(progress1, equals(progress2));
      expect(progress1, isNot(equals(progress3)));
    });
    test('should have meaningful toString representation', () {
      final progress = StudySessionProgress(
        currentCardIndex: 3,
        totalCards: 10,
        correctCount: 2,
        incorrectCount: 1,
      );
      final stringRep = progress.toString();
      expect(stringRep, contains('currentCardIndex: 3'));
      expect(stringRep, contains('totalCards: 10'));
      expect(stringRep, contains('correctCount: 2'));
      expect(stringRep, contains('incorrectCount: 1'));
      expect(stringRep, contains('completionPercentage: 30%'));
      expect(stringRep, contains('accuracyPercentage: 67%'));
    });
  });
}