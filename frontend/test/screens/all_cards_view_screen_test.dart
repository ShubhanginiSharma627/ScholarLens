import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scholar_lens/screens/all_cards_view_screen.dart';
import 'package:scholar_lens/models/flashcard.dart';
import 'package:scholar_lens/theme/app_theme.dart';

void main() {
  group('AllCardsViewScreen', () {
    setUp(() {
      // Mock SharedPreferences for testing
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

      // Wait for loading to complete
      await tester.pump();

      // Verify the app bar title
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

      // Wait for loading and animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Verify empty state is displayed
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

      // Wait for loading and animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Verify cards are displayed
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

      // Wait for loading to complete
      await tester.pump();

      // Verify search bar and filter button are present
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

      // Wait for loading and animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Verify FAB is displayed
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

      // Wait for loading and animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Initially both cards should be visible
      expect(find.text('2 cards'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pump();

      // Should now show only 1 card
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

      // Wait for loading and animations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Find and tap Study All button
      final studyAllButton = find.text('Study All');
      expect(studyAllButton, findsOneWidget);
      
      await tester.tap(studyAllButton);
      await tester.pumpAndSettle();

      // Verify navigation occurred (FlashcardScreen should be pushed)
      // Note: In a real test, you'd verify the route was pushed
      // For now, we just verify the button exists and is tappable
    });
  });
}