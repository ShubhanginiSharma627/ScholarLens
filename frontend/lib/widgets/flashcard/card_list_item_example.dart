import 'package:flutter/material.dart';
import '../../models/flashcard.dart';
import 'card_list_item.dart';
class CardListItemExample extends StatelessWidget {
  const CardListItemExample({super.key});
  @override
  Widget build(BuildContext context) {
    final sampleFlashcards = [
      Flashcard.create(
        subject: 'Mathematics',
        question: 'What is the derivative of x²?',
        answer: '2x',
      ).copyWith(
        reviewCount: 5,
        difficulty: Difficulty.easy,
      ),
      Flashcard.create(
        subject: 'Physics',
        question: 'What is Newton\'s second law of motion?',
        answer: 'Force equals mass times acceleration (F = ma)',
      ).copyWith(
        reviewCount: 3,
        difficulty: Difficulty.medium,
      ),
      Flashcard.create(
        subject: 'Chemistry',
        question: 'What is the chemical formula for water?',
        answer: 'H₂O - two hydrogen atoms bonded to one oxygen atom',
      ).copyWith(
        reviewCount: 1,
        difficulty: Difficulty.hard,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card List Item Examples'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleFlashcards.length,
        itemBuilder: (context, index) {
          final flashcard = sampleFlashcards[index];
          final isMastered = flashcard.reviewCount >= 3;
          return CardListItem(
            flashcard: flashcard,
            isMastered: isMastered,
            cardNumber: index + 1,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped card: ${flashcard.question}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class CardListWithSections extends StatelessWidget {
  const CardListWithSections({super.key});
  @override
  Widget build(BuildContext context) {
    final masteredCards = <Flashcard>[
      Flashcard.create(
        subject: 'Mathematics',
        question: 'What is 2 + 2?',
        answer: '4',
      ).copyWith(reviewCount: 10, difficulty: Difficulty.easy),
    ];
    final studyCards = <Flashcard>[
      Flashcard.create(
        subject: 'Physics',
        question: 'What is the speed of light?',
        answer: '299,792,458 meters per second',
      ).copyWith(reviewCount: 2, difficulty: Difficulty.medium),
      Flashcard.create(
        subject: 'Chemistry',
        question: 'What is the atomic number of carbon?',
        answer: '6',
      ).copyWith(reviewCount: 0, difficulty: Difficulty.hard),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards by Status'),
      ),
      body: ListView(
        children: [
          if (masteredCards.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Mastered Cards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...masteredCards.asMap().entries.map((entry) {
              return CardListItem(
                flashcard: entry.value,
                isMastered: true,
                cardNumber: entry.key + 1,
                onTap: () => _handleCardTap(context, entry.value),
              );
            }),
          ],
          if (studyCards.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cards to Study',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...studyCards.asMap().entries.map((entry) {
              return CardListItem(
                flashcard: entry.value,
                isMastered: false,
                cardNumber: masteredCards.length + entry.key + 1,
                onTap: () => _handleCardTap(context, entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }
  void _handleCardTap(BuildContext context, Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(flashcard.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(flashcard.question),
            const SizedBox(height: 16),
            Text(
              'Answer:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(flashcard.answer),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Study'),
          ),
        ],
      ),
    );
  }
}