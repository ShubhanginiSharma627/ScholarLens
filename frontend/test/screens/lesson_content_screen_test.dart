import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/screens/lesson_content_screen.dart';
import 'package:scholar_lens/models/lesson_content.dart';
import 'package:scholar_lens/models/quiz_question.dart';

void main() {
  group('LessonContentScreen', () {
    late LessonContent testLessonContent;

    setUp(() {
      testLessonContent = LessonContent(
        lessonTitle: 'Test Lesson',
        summaryMarkdown: '# Test Content\n\nThis is a **test** lesson with *markdown*.',
        audioTranscript: 'This is the audio transcript for testing.',
        quiz: [
          const QuizQuestion(
            question: 'What is 2 + 2?',
            options: ['3', '4', '5', '6'],
            correctIndex: 1,
            explanation: 'Basic arithmetic: 2 + 2 = 4',
          ),
        ],
        createdAt: DateTime.now(),
      );
    });

    testWidgets('displays lesson title prominently', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonContentScreen(lessonContent: testLessonContent),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Check that lesson title appears in app bar
      expect(find.text('Test Lesson'), findsAtLeastNWidgets(1));
      
      // Check that lesson title appears prominently in content
      final titleFinder = find.text('Test Lesson');
      expect(titleFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('displays audio controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonContentScreen(lessonContent: testLessonContent),
        ),
      );

      await tester.pumpAndSettle();

      // Check for audio control buttons
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('displays quiz navigation button when quiz exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonContentScreen(lessonContent: testLessonContent),
        ),
      );

      await tester.pumpAndSettle();

      // Check for quiz button
      expect(find.textContaining('Take Quiz'), findsOneWidget);
      expect(find.textContaining('1 questions'), findsOneWidget);
    });

    testWidgets('does not display quiz button when no quiz exists', (WidgetTester tester) async {
      final lessonWithoutQuiz = testLessonContent.copyWith(quiz: []);
      
      await tester.pumpWidget(
        MaterialApp(
          home: LessonContentScreen(lessonContent: lessonWithoutQuiz),
        ),
      );

      await tester.pumpAndSettle();

      // Check that quiz button is not present
      expect(find.textContaining('Take Quiz'), findsNothing);
    });

    testWidgets('renders markdown content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonContentScreen(lessonContent: testLessonContent),
        ),
      );

      await tester.pumpAndSettle();

      // Check that markdown content is rendered (text should be present)
      expect(find.textContaining('Test Content'), findsOneWidget);
      expect(find.textContaining('test lesson'), findsOneWidget);
    });
  });
}