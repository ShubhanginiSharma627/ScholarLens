import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scholar_lens/screens/quiz_screen.dart';
import 'package:scholar_lens/models/quiz_question.dart';
import 'package:scholar_lens/models/lesson_content.dart';
import 'package:scholar_lens/providers/progress_provider.dart';
void main() {
  group('QuizScreen', () {
    late List<QuizQuestion> testQuestions;
    late LessonContent testLessonContent;
    setUp(() {
      testQuestions = [
        const QuizQuestion(
          question: 'What is 2 + 2?',
          options: ['3', '4', '5', '6'],
          correctIndex: 1,
          explanation: 'Basic arithmetic: 2 + 2 = 4',
        ),
        const QuizQuestion(
          question: 'What is the capital of France?',
          options: ['London', 'Berlin', 'Paris', 'Madrid'],
          correctIndex: 2,
          explanation: 'Paris is the capital and largest city of France.',
        ),
      ];
      testLessonContent = LessonContent(
        lessonTitle: 'Test Quiz Lesson',
        summaryMarkdown: 'Test content',
        audioTranscript: 'Test transcript',
        quiz: testQuestions,
        createdAt: DateTime.now(),
      );
    });
    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ],
        child: MaterialApp(
          home: QuizScreen(
            questions: testQuestions,
            lessonContent: testLessonContent,
            subject: 'Mathematics',
          ),
        ),
      );
    }
    testWidgets('displays quiz title and progress', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Quiz: Test Quiz Lesson'), findsOneWidget);
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
    testWidgets('displays first question and options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('What is 2 + 2?'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });
    testWidgets('allows answer selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      final submitButton = find.text('Submit Answer');
      expect(submitButton, findsOneWidget);
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(submitButton, findsOneWidget);
    });
    testWidgets('shows feedback after answer submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Basic arithmetic: 2 + 2 = 4'), findsOneWidget);
      expect(find.text('Next Question'), findsOneWidget);
    });
    testWidgets('shows incorrect feedback for wrong answer', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Basic arithmetic: 2 + 2 = 4'), findsOneWidget);
    });
    testWidgets('navigates to next question', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.tap(find.text('Next Question'));
      await tester.pump();
      expect(find.text('Question 2 of 2'), findsOneWidget);
      expect(find.text('What is the capital of France?'), findsOneWidget);
    });
    testWidgets('shows quiz completion screen after last question', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.tap(find.text('Next Question'));
      await tester.pump();
      await tester.tap(find.text('Paris'));
      await tester.pump();
      await tester.tap(find.text('Submit Answer'));
      await tester.pump();
      await tester.tap(find.text('Finish Quiz'));
      await tester.pump();
      expect(find.text('Quiz Complete!'), findsOneWidget);
      expect(find.text('Your Score'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('100% Accuracy'), findsOneWidget);
    });
    testWidgets('displays navigation buttons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      final previousButton = find.text('Previous');
      expect(previousButton, findsOneWidget);
      expect(find.text('Submit Answer'), findsOneWidget);
    });
  });
}