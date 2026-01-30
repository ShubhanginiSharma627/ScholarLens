import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/widgets/flashcard/enhanced_flashcard_widget.dart';
import 'package:scholar_lens/models/flashcard.dart';
import 'package:scholar_lens/theme/app_theme.dart';
void main() {
  group('EnhancedFlashcardWidget', () {
    late Flashcard testFlashcard;
    setUp(() {
      testFlashcard = Flashcard(
        id: 'test-1',
        subject: 'Mathematics',
        question: 'What is 2 + 2?',
        answer: '4',
        difficulty: Difficulty.easy,
        nextReviewDate: DateTime.now().add(const Duration(days: 1)),
        reviewCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      );
    });
    Widget createTestWidget({
      required bool isFlipped,
      VoidCallback? onFlip,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: EnhancedFlashcardWidget(
              flashcard: testFlashcard,
              isFlipped: isFlipped,
              onFlip: onFlip ?? () {},
            ),
          ),
        ),
      );
    }
    testWidgets('displays question when not flipped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isFlipped: false));
      await tester.pumpAndSettle();
      expect(find.text('What is 2 + 2?'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Tap to reveal answer'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });
    testWidgets('displays answer when flipped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isFlipped: true));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('What is 2 + 2?'), findsNothing);
      expect(find.text('Tap to reveal answer'), findsNothing);
    });
    testWidgets('calls onFlip when tapped', (WidgetTester tester) async {
      bool flipCalled = false;
      await tester.pumpWidget(createTestWidget(
        isFlipped: false,
        onFlip: () => flipCalled = true,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EnhancedFlashcardWidget));
      await tester.pump();
      expect(flipCalled, isTrue);
    });
    testWidgets('has proper semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isFlipped: false));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'Flashcard showing question.*Tap to reveal answer')),
        findsOneWidget,
      );
    });
    testWidgets('animates flip transition', (WidgetTester tester) async {
      bool isFlipped = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Center(
                  child: EnhancedFlashcardWidget(
                    flashcard: testFlashcard,
                    isFlipped: isFlipped,
                    onFlip: () => setState(() => isFlipped = !isFlipped),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What is 2 + 2?'), findsOneWidget);
      expect(find.text('4'), findsNothing);
      await tester.tap(find.byType(EnhancedFlashcardWidget));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('What is 2 + 2?'), findsNothing);
    });
    testWidgets('displays different difficulty icons correctly', (WidgetTester tester) async {
      final hardFlashcard = testFlashcard.copyWith(difficulty: Difficulty.hard);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: EnhancedFlashcardWidget(
                flashcard: hardFlashcard,
                isFlipped: true,
                onFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hard'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });
    testWidgets('works with dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: EnhancedFlashcardWidget(
                flashcard: testFlashcard,
                isFlipped: false,
                onFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('What is 2 + 2?'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
    });
  });
}