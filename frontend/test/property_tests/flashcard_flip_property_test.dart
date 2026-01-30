import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/flashcard.dart';
import 'package:scholar_lens/widgets/flashcard_widget.dart';
void main() {
  group('Property 30: Flashcard Flip Interaction', () {
    testWidgets('For any flashcard tap or swipe interaction, the card should flip to reveal the answer/explanation on the back side', (WidgetTester tester) async {
      final testFlashcards = _generateTestFlashcards(100);
      for (int i = 0; i < testFlashcards.length; i++) {
        final flashcard = testFlashcards[i];
        bool isFlipped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return FlashcardWidget(
                    flashcard: flashcard,
                    isFlipped: isFlipped,
                    onFlip: () {
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
        expect(find.text(flashcard.question), findsOneWidget);
        expect(find.text(flashcard.answer), findsNothing);
        expect(find.text('Tap to reveal answer'), findsOneWidget);
        await tester.tap(find.byType(FlashcardWidget));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600)); // Wait for flip animation
        expect(find.text(flashcard.answer), findsOneWidget);
        expect(find.text(flashcard.question), findsNothing);
        expect(find.text('Tap to reveal answer'), findsNothing);
        await tester.tap(find.byType(FlashcardWidget));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600)); // Wait for flip animation
        expect(find.text(flashcard.question), findsOneWidget);
        expect(find.text(flashcard.answer), findsNothing);
        expect(find.text('Tap to reveal answer'), findsOneWidget);
      }
    });
    testWidgets('Flashcard flip state should be consistent across multiple interactions', (WidgetTester tester) async {
      final flashcard = Flashcard.create(
        subject: 'Test Subject',
        question: 'Test Question',
        answer: 'Test Answer',
      );
      bool isFlipped = false;
      int flipCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FlashcardWidget(
                  flashcard: flashcard,
                  isFlipped: isFlipped,
                  onFlip: () {
                    setState(() {
                      isFlipped = !isFlipped;
                      flipCount++;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      for (int i = 0; i < 10; i++) {
        final expectedShowingQuestion = i % 2 == 0;
        if (expectedShowingQuestion) {
          expect(find.text('Test Question'), findsOneWidget);
          expect(find.text('Test Answer'), findsNothing);
        } else {
          expect(find.text('Test Answer'), findsOneWidget);
          expect(find.text('Test Question'), findsNothing);
        }
        await tester.tap(find.byType(FlashcardWidget));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(find.text('Test Question'), findsOneWidget);
      expect(find.text('Test Answer'), findsNothing);
    });
    testWidgets('Flashcard displays correct content on both sides for any flashcard', (WidgetTester tester) async {
      final testFlashcards = _generateVariedFlashcards(50);
      for (final flashcard in testFlashcards) {
        bool isFlipped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return FlashcardWidget(
                    flashcard: flashcard,
                    isFlipped: isFlipped,
                    onFlip: () {
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
        expect(find.text(flashcard.question), findsOneWidget);
        expect(find.text(flashcard.subject), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        await tester.tap(find.byType(FlashcardWidget));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(flashcard.answer), findsOneWidget);
        expect(find.text(flashcard.subject), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
        expect(find.text(flashcard.reviewCount.toString()), findsOneWidget);
        expect(find.text(flashcard.difficulty.displayName), findsOneWidget);
      }
    });
  });
}
List<Flashcard> _generateTestFlashcards(int count) {
  final subjects = ['Math', 'Science', 'History', 'English', 'Geography'];
  final difficulties = Difficulty.values;
  return List.generate(count, (index) {
    final subject = subjects[index % subjects.length];
    final difficulty = difficulties[index % difficulties.length];
    final reviewCount = index % 10;
    return Flashcard(
      id: 'test_$index',
      subject: subject,
      question: 'Test Question $index for $subject?',
      answer: 'Test Answer $index for $subject',
      difficulty: difficulty,
      nextReviewDate: DateTime.now().add(Duration(days: index % 7)),
      reviewCount: reviewCount,
      createdAt: DateTime.now().subtract(Duration(days: index)),
      category: index % 3 == 0 ? 'Category ${index ~/ 3}' : null,
    );
  });
}
List<Flashcard> _generateVariedFlashcards(int count) {
  final contentTypes = [
    ('Math', 'What is 2+2?', '4'),
    ('History', 'What were the main causes of World War I and how did they contribute to the outbreak of the conflict?', 'The main causes included militarism, alliance systems, imperialism, and nationalism, which created tensions that ultimately led to war.'),
    ('Science', 'What is H₂O?', 'Water (dihydrogen monoxide)'),
    ('Math', 'Solve: x² + 5x + 6 = 0', 'x = -2 or x = -3'),
    ('English', 'Define metaphor', 'A figure of speech that compares two unlike things without using "like" or "as"'),
  ];
  return List.generate(count, (index) {
    final contentType = contentTypes[index % contentTypes.length];
    final difficulty = Difficulty.values[index % Difficulty.values.length];
    return Flashcard(
      id: 'varied_$index',
      subject: contentType.$1,
      question: contentType.$2,
      answer: contentType.$3,
      difficulty: difficulty,
      nextReviewDate: DateTime.now().add(Duration(days: index % 5 + 1)),
      reviewCount: index % 8,
      createdAt: DateTime.now().subtract(Duration(days: index % 30)),
      category: index % 4 == 0 ? 'Advanced' : null,
    );
  });
}