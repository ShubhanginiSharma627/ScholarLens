import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/widgets/flashcard/deck_overview_header.dart';
import 'package:scholar_lens/services/flashcard_service.dart';
import 'package:scholar_lens/theme/app_theme.dart';

void main() {
  group('DeckOverviewHeader', () {
    late FlashcardStats mockStats;
    late VoidCallback mockOnStudyAll;
    late VoidCallback mockOnShuffle;

    setUp(() {
      mockStats = const FlashcardStats(
        totalCards: 10,
        dueCards: 3,
        masteredCards: 4,
        averageReviews: 2.5,
      );
      mockOnStudyAll = () {};
      mockOnShuffle = () {};
    });

    testWidgets('displays subject name prominently', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Mathematics',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Verify subject name is displayed
      expect(find.text('Mathematics'), findsOneWidget);
      
      // Verify subject name uses appropriate typography
      final subjectText = tester.widget<Text>(find.text('Mathematics'));
      expect(subjectText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('displays card count badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Science',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Verify card count badge is displayed
      expect(find.text('10 cards'), findsOneWidget);
    });

    testWidgets('displays due cards indicator when cards are due', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'History',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Verify due cards indicator is displayed
      expect(find.text('3 due'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('does not display due cards indicator when no cards are due', (WidgetTester tester) async {
      final noDueStats = const FlashcardStats(
        totalCards: 10,
        dueCards: 0,
        masteredCards: 4,
        averageReviews: 2.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'History',
              stats: noDueStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Verify due cards indicator is not displayed
      expect(find.text('0 due'), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('displays Study All and Shuffle buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'English',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Verify both buttons are displayed
      expect(find.text('Study All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.shuffle), findsOneWidget);
    });

    testWidgets('disables buttons when no cards available', (WidgetTester tester) async {
      final emptyStats = const FlashcardStats(
        totalCards: 0,
        dueCards: 0,
        masteredCards: 0,
        averageReviews: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Empty Subject',
              stats: emptyStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Find the buttons
      final studyAllButton = find.widgetWithText(ElevatedButton, 'Study All');
      final shuffleButton = find.widgetWithText(OutlinedButton, 'Shuffle');

      expect(studyAllButton, findsOneWidget);
      expect(shuffleButton, findsOneWidget);

      // Verify buttons are disabled
      final studyAllWidget = tester.widget<ElevatedButton>(studyAllButton);
      final shuffleWidget = tester.widget<OutlinedButton>(shuffleButton);
      
      expect(studyAllWidget.onPressed, isNull);
      expect(shuffleWidget.onPressed, isNull);
    });

    testWidgets('shows loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Loading Subject',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
              isLoading: true,
            ),
          ),
        ),
      );

      // Verify loading state is displayed
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Verify buttons are disabled during loading
      final studyAllButton = find.widgetWithText(ElevatedButton, 'Loading...');
      final shuffleButton = find.widgetWithText(OutlinedButton, 'Shuffle');
      
      final studyAllWidget = tester.widget<ElevatedButton>(studyAllButton);
      final shuffleWidget = tester.widget<OutlinedButton>(shuffleButton);
      
      expect(studyAllWidget.onPressed, isNull);
      expect(shuffleWidget.onPressed, isNull);
    });

    testWidgets('calls onStudyAll when Study All button is tapped', (WidgetTester tester) async {
      bool studyAllCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Test Subject',
              stats: mockStats,
              onStudyAll: () => studyAllCalled = true,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Tap the Study All button
      await tester.tap(find.text('Study All'));
      await tester.pump();

      expect(studyAllCalled, isTrue);
    });

    testWidgets('calls onShuffle when Shuffle button is tapped', (WidgetTester tester) async {
      bool shuffleCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Test Subject',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: () => shuffleCalled = true,
            ),
          ),
        ),
      );

      // Tap the Shuffle button
      await tester.tap(find.text('Shuffle'));
      await tester.pump();

      expect(shuffleCalled, isTrue);
    });

    testWidgets('displays appropriate subject icons', (WidgetTester tester) async {
      // Test math subject
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Mathematics',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('integrates ModernProgressTracker correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DeckOverviewHeader(
              subjectName: 'Test Subject',
              stats: mockStats,
              onStudyAll: mockOnStudyAll,
              onShuffle: mockOnShuffle,
            ),
          ),
        ),
      );

      // Verify progress tracker displays the correct statistics
      expect(find.text('10'), findsOneWidget); // Total cards
      expect(find.text('4'), findsOneWidget);  // Mastered cards
      expect(find.text('40%'), findsOneWidget); // Mastery percentage (4/10 * 100)
    });
  });
}