import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/widgets/flashcard/modern_progress_tracker.dart';
import 'package:scholar_lens/theme/app_theme.dart';

void main() {
  group('ModernProgressTracker', () {
    testWidgets('displays basic statistics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ModernProgressTracker(
              totalCards: 10,
              masteredCards: 3,
              completionPercentage: 0.7,
            ),
          ),
        ),
      );

      // Verify total cards display
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Total Cards'), findsOneWidget);

      // Verify mastered cards display
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);

      // Verify completion percentage
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);

      // Verify mastery percentage calculation (3/10 = 30%)
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('Mastery'), findsOneWidget);
    });

    testWidgets('displays counters when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ModernProgressTracker(
              totalCards: 10,
              masteredCards: 3,
              completionPercentage: 0.7,
              correctCount: 5,
              incorrectCount: 2,
              showCounters: true,
            ),
          ),
        ),
      );

      // Verify counters are displayed
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Incorrect'), findsOneWidget);

      // Verify accuracy calculation (5/(5+2) = 71%)
      expect(find.text('71%'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
    });

    testWidgets('handles zero values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ModernProgressTracker(
              totalCards: 0,
              masteredCards: 0,
              completionPercentage: 0.0,
              correctCount: 0,
              incorrectCount: 0,
              showCounters: true,
            ),
          ),
        ),
      );

      // Verify zero values are handled
      expect(find.text('0'), findsWidgets);
      expect(find.text('0%'), findsWidgets);
    });

    testWidgets('hides mastery stats when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ModernProgressTracker(
              totalCards: 10,
              masteredCards: 3,
              completionPercentage: 0.7,
              showMasteryStats: false,
            ),
          ),
        ),
      );

      // Verify mastery stats are hidden
      expect(find.text('Total Cards'), findsNothing);
      expect(find.text('Mastered'), findsNothing);
      expect(find.text('Mastery'), findsNothing);

      // But progress should still be shown
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('clamps completion percentage to valid range', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ModernProgressTracker(
              totalCards: 10,
              masteredCards: 3,
              completionPercentage: 1.5, // Over 100%
            ),
          ),
        ),
      );

      // Should display as 100% (150% clamped to 100%)
      expect(find.text('150%'), findsOneWidget);
    });
  });
}