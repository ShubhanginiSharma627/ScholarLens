import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
class FlashcardService {
  static const String _flashcardsKey = 'flashcards';
  static const String _subjectsKey = 'flashcard_subjects';
  Future<List<Flashcard>> getAllFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = prefs.getStringList(_flashcardsKey) ?? [];
    return flashcardsJson
        .map((json) => Flashcard.fromJson(jsonDecode(json)))
        .toList();
  }
  Future<List<Flashcard>> getFlashcardsBySubject(String subject) async {
    final allFlashcards = await getAllFlashcards();
    return allFlashcards.where((card) => card.subject == subject).toList();
  }
  Future<List<Flashcard>> getFlashcardsByCategory(String category) async {
    final allFlashcards = await getAllFlashcards();
    return allFlashcards.where((card) => card.category == category).toList();
  }
  Future<List<Flashcard>> getScheduledCards() async {
    final allFlashcards = await getAllFlashcards();
    final now = DateTime.now();
    return allFlashcards
        .where((card) => card.nextReviewDate.isBefore(now) || card.nextReviewDate.isAtSameMomentAs(now))
        .toList()
      ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
  }
  Future<List<Flashcard>> getTodaysCards() async {
    final allFlashcards = await getAllFlashcards();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return allFlashcards
        .where((card) => 
            card.nextReviewDate.isAfter(startOfDay) && 
            card.nextReviewDate.isBefore(endOfDay))
        .toList();
  }
  Future<void> createFlashcard(Flashcard flashcard) async {
    final allFlashcards = await getAllFlashcards();
    allFlashcards.add(flashcard);
    await _saveFlashcards(allFlashcards);
    await _updateSubjectsList(flashcard.subject);
  }
  Future<void> updateFlashcard(Flashcard updatedFlashcard) async {
    final allFlashcards = await getAllFlashcards();
    final index = allFlashcards.indexWhere((card) => card.id == updatedFlashcard.id);
    if (index != -1) {
      allFlashcards[index] = updatedFlashcard;
      await _saveFlashcards(allFlashcards);
      await _updateSubjectsList(updatedFlashcard.subject);
    }
  }
  Future<void> updateFlashcardDifficulty(String cardId, Difficulty difficulty) async {
    final allFlashcards = await getAllFlashcards();
    final index = allFlashcards.indexWhere((card) => card.id == cardId);
    if (index != -1) {
      final updatedCard = allFlashcards[index].updateAfterReview(difficulty);
      allFlashcards[index] = updatedCard;
      await _saveFlashcards(allFlashcards);
    }
  }
  Future<void> deleteFlashcard(String cardId) async {
    final allFlashcards = await getAllFlashcards();
    allFlashcards.removeWhere((card) => card.id == cardId);
    await _saveFlashcards(allFlashcards);
  }
  Future<List<String>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_subjectsKey) ?? [];
  }
  Future<List<String>> getCategories() async {
    final allFlashcards = await getAllFlashcards();
    final categories = allFlashcards
        .where((card) => card.category != null)
        .map((card) => card.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
  Future<FlashcardStats> getSubjectStats(String subject) async {
    final subjectCards = await getFlashcardsBySubject(subject);
    final now = DateTime.now();
    final totalCards = subjectCards.length;
    final dueCards = subjectCards.where((card) => card.isDue).length;
    final masteredCards = subjectCards.where((card) => 
        card.reviewCount >= 3 && card.difficulty == Difficulty.easy).length;
    final averageReviews = totalCards > 0 
        ? subjectCards.map((card) => card.reviewCount).reduce((a, b) => a + b) / totalCards
        : 0.0;
    return FlashcardStats(
      totalCards: totalCards,
      dueCards: dueCards,
      masteredCards: masteredCards,
      averageReviews: averageReviews,
    );
  }
  Future<List<Flashcard>> searchFlashcards(String query) async {
    if (query.isEmpty) return [];
    final allFlashcards = await getAllFlashcards();
    final lowercaseQuery = query.toLowerCase();
    return allFlashcards.where((card) =>
        card.question.toLowerCase().contains(lowercaseQuery) ||
        card.answer.toLowerCase().contains(lowercaseQuery) ||
        card.subject.toLowerCase().contains(lowercaseQuery) ||
        (card.category?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }
  Future<void> importFlashcards(List<Map<String, dynamic>> flashcardsJson) async {
    final flashcards = flashcardsJson
        .map((json) => Flashcard.fromJson(json))
        .toList();
    final allFlashcards = await getAllFlashcards();
    for (final flashcard in flashcards) {
      if (!allFlashcards.any((existing) => existing.id == flashcard.id)) {
        allFlashcards.add(flashcard);
        await _updateSubjectsList(flashcard.subject);
      }
    }
    await _saveFlashcards(allFlashcards);
  }
  Future<List<Map<String, dynamic>>> exportFlashcards({String? subject}) async {
    List<Flashcard> flashcards;
    if (subject != null) {
      flashcards = await getFlashcardsBySubject(subject);
    } else {
      flashcards = await getAllFlashcards();
    }
    return flashcards.map((card) => card.toJson()).toList();
  }
  Future<void> resetProgress() async {
    final allFlashcards = await getAllFlashcards();
    final resetCards = allFlashcards.map((card) => card.copyWith(
      difficulty: Difficulty.medium,
      reviewCount: 0,
      nextReviewDate: DateTime.now().add(const Duration(days: 1)),
    )).toList();
    await _saveFlashcards(resetCards);
  }
  Future<void> _saveFlashcards(List<Flashcard> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = flashcards
        .map((card) => jsonEncode(card.toJson()))
        .toList();
    await prefs.setStringList(_flashcardsKey, flashcardsJson);
  }
  Future<void> _updateSubjectsList(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final subjects = prefs.getStringList(_subjectsKey) ?? [];
    if (!subjects.contains(subject)) {
      subjects.add(subject);
      subjects.sort();
      await prefs.setStringList(_subjectsKey, subjects);
    }
  }
}
class FlashcardStats {
  final int totalCards;
  final int dueCards;
  final int masteredCards;
  final double averageReviews;
  const FlashcardStats({
    required this.totalCards,
    required this.dueCards,
    required this.masteredCards,
    required this.averageReviews,
  });
  double get masteryPercentage => totalCards > 0 ? masteredCards / totalCards : 0.0;
  double get completionPercentage => totalCards > 0 ? (totalCards - dueCards) / totalCards : 0.0;
}