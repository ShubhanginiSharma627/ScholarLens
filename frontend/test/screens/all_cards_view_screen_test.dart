import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholar_lens/screens/all_cards_view_screen.dart';
import 'package:scholar_lens/models/flashcard.dart';
import 'package:scholar_lens/theme/app_theme.dart';
void main() {
  group('AllCardsViewScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    testWidgets('displays screen title correctly', (WidgetTester tester) async {
      const subject = 'Test Subject';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllCardsViewScreen(subject: subject),
        ),
      );
      await tester.pump();
      expect(find.text(subject), findsOneWidget);
    });
    testWidgets('displays empty state when no cards available', (WidgetTester tester) async {
      const subject = 'Empty Subject';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllCardsViewScreen(
            subject: subject,
            initialCards: [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('No cards available'), findsOneWidget);
      expect(find.text('Generate some flashcards to start studying!'), findsOneWidget);
      expect(find.byIcon(Icons.style_rounded), findsOneWidget);
    });
    testWidgets('displays cards when provided', (WidgetTester tester) async {
      const subject = 'Test Subject';
      final testCards = [
        Flashcard.create(
          subject: subject,
          question: 'What is Flutter?',
          answer: 'A UI toolkit for building applications',
        ),
        Flashcard.create(
          subject: subject,
          question: 'What is Dart?',
          answer: 'A programming language',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AllCardsViewScreen(
            subject: subject,
            initialCards: testCards,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('What is Flutter?'), findsOneWidget);
      expect(find.text('What is Dart?'), findsOneWidget);
      expect(find.text('2 cards'), findsOneWidget);
    });
    testWidgets('displays search bar and filter button', (WidgetTester tester) async {
      const subject = 'Test Subject';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllCardsViewScreen(
            subject: subject,
            initialCards: [],
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
      expect(find.text('Search cards...'), findsOneWidget);
    });
    testWidgets('displays Generate More Cards FAB', (WidgetTester tester) async {
      const subject = 'Test Subject';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AllCardsViewScreen(
            subject: subject,
            initialCards: [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.text('Generate More Cards'), findsOneWidget);
    });
    testWidgets('search functionality filters cards', (WidgetTester tester) async {
      const subject = 'Test Subject';
      final testCards = [
        Flashcard.create(
          subject: subject,
          question: 'What is Flutter?',
          answer: 'A UI toolkit',
        ),
        Flashcard.create(
          subject: subject,
          question: 'What is Dart?',
          answer: 'A programming language',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AllCardsViewScreen(
            subject: subject,
            initialCards: testCards,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('2 cards'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pump();
      expect(find.text('1 cards'), findsOneWidget);
      expect(find.text('What is Flutter?'), findsOneWidget);
      expect(find.text('What is Dart?'), findsNothing);
    });
    testWidgets('Study All button navigates to study mode', (WidgetTester tester) async {
      const subject = 'Test Subject';
      final testCards = [
        Flashcard.create(
          subject: subject,
          question: 'Test question',
          answer: 'Test answer',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AllCardsViewScreen(
            subject: subject,
            initialCards: testCards,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      final studyAllButton = find.text('Study All');
      expect(studyAllButton, findsOneWidget);
      await tester.tap(studyAllButton);
      await tester.pumpAndSettle();
    });
  });
}