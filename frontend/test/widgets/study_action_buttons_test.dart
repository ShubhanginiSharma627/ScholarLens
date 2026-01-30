import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/widgets/study_action_buttons.dart';
void main() {
  group('StudyActionButtons', () {
    testWidgets('renders both action buttons with correct labels', (WidgetTester tester) async {
      bool flashcardsPressed = false;
      bool quizPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyActionButtons(
              onCreateFlashcards: () => flashcardsPressed = true,
              onQuizMe: () => quizPressed = true,
            ),
          ),
        ),
      );
      expect(find.text('Create Flashcards'), findsOneWidget);
      expect(find.text('Quiz Me'), findsOneWidget);
      expect(find.byIcon(Icons.quiz), findsOneWidget);
      expect(find.byIcon(Icons.assignment), findsOneWidget);
      expect(find.text('Study Tools'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });
    testWidgets('calls correct callbacks when buttons are pressed', (WidgetTester tester) async {
      bool flashcardsPressed = false;
      bool quizPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyActionButtons(
              onCreateFlashcards: () => flashcardsPressed = true,
              onQuizMe: () => quizPressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Create Flashcards'));
      await tester.pump();
      expect(flashcardsPressed, isTrue);
      await tester.tap(find.text('Quiz Me'));
      await tester.pump();
      expect(quizPressed, isTrue);
    });
    testWidgets('shows tooltips on long press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudyActionButtons(
              onCreateFlashcards: () {},
              onQuizMe: () {},
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Create Flashcards'));
      await tester.pumpAndSettle();
      expect(find.text('Generate flashcards from this chapter content'), findsOneWidget);
    });
  });
}