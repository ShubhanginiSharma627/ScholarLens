import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/widgets/flashcard/card_list_item.dart';
import 'package:scholar_lens/models/flashcard.dart';
import 'package:scholar_lens/theme/app_theme.dart';

void main() {
  group('CardListItem', () {
    late Flashcard testFlashcard;

    setUp(() {
      testFlashcard = Flashcard(
        id: 'test-1',
        subject: 'Mathematics',
        question: 'What is the derivative of x²?',
        answer: '2x',
        difficulty: Difficulty.medium,
        nextReviewDate: DateTime.now().add(const Duration(days: 2)),
        reviewCount: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );
    });

    Widget createTestWidget({
      required bool isMastered,
      int? cardNumber,
      bool showMasteryIndicator = true,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CardListItem(
            flashcard: testFlashcard,
            isMastered: isMastered,
            cardNumber: cardNumber,
            showMasteryIndicator: showMasteryIndicator,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('displays flashcard question preview', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isMastered: false));
      await tester.pumpAndSettle();

      // Should show question text
      expect(find.text('What is the derivative of x²?'), findsOneWidget);
      
      // Should show subject badge
      expect(find.text('MATHEMATICS'), findsOneWidget);
      
      // Should show answer snippet
      expect(find.text('2x'), findsOneWidget);
    });

    testWidgets('displays mastery indicator when mastered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        isMastered: true,
        cardNumber: 5,
      ));
      await tester.pumpAndSettle();

      // Should show checkmark for mastered card
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      
      // Should show card number label
      expect(find.text('#5'), findsOneWidget);
    });

    testWidgets('displays card number when not mastered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        isMastered: false,
        cardNumber: 3,
      ));
      await tester.pumpAndSettle();

      // Should show card number in circle
      expect(find.text('3'), findsOneWidget);
      
      // Should not show checkmark
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('displays card statistics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isMastered: false));
      await tester.pumpAndSettle();

      // Should show review count
      expect(find.text('5 reviews'), findsOneWidget);
      
      // Should show difficulty
      expect(find.text('Medium'), findsOneWidget);
      
      // Should show days until review (2 days from now)
      expect(find.text('2d'), findsOneWidget);
    });

    testWidgets('displays due status for overdue cards', (WidgetTester tester) async {
      final overdueCard = testFlashcard.copyWith(
        nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CardListItem(
              flashcard: overdueCard,
              isMastered: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show "Due now" status
      expect(find.text('Due now'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        isMastered: false,
        onTap: () => tapCalled = true,
      ));
      await tester.pumpAndSettle();

      // Tap the card
      await tester.tap(find.byType(CardListItem));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('has proper semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        isMastered: true,
        cardNumber: 2,
      ));
      await tester.pumpAndSettle();

      // Check semantic label includes card info and mastery status
      expect(
        find.bySemanticsLabel(RegExp(r'Flashcard 2:.*derivative.*Mastered.*Tap to study')),
        findsOneWidget,
      );
    });

    testWidgets('shows different difficulty colors and icons', (WidgetTester tester) async {
      final easyCard = testFlashcard.copyWith(difficulty: Difficulty.easy);
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CardListItem(
              flashcard: easyCard,
              isMastered: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show easy difficulty
      expect(find.text('Easy'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
    });

    testWidgets('shows hard difficulty correctly', (WidgetTester tester) async {
      final hardCard = testFlashcard.copyWith(difficulty: Difficulty.hard);
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CardListItem(
              flashcard: hardCard,
              isMastered: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show hard difficulty
      expect(find.text('Hard'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('can hide mastery indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        isMastered: false,
        cardNumber: 1,
        showMasteryIndicator: false,
      ));
      await tester.pumpAndSettle();

      // Should not show mastery indicator circle
      expect(find.text('1'), findsNothing);
      
      // Should still show other content
      expect(find.text('What is the derivative of x²?'), findsOneWidget);
    });

    testWidgets('handles long question text with ellipsis', (WidgetTester tester) async {
      final longQuestionCard = testFlashcard.copyWith(
        question: 'This is a very long question that should be truncated with ellipsis when displayed in the card list item widget to maintain proper layout and readability',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CardListItem(
              flashcard: longQuestionCard,
              isMastered: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without overflow errors
      expect(tester.takeException(), isNull);
      
      // Should show truncated text
      final textWidget = tester.widget<Text>(
        find.text(longQuestionCard.question).first,
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 2);
    });

    testWidgets('handles long answer text with ellipsis', (WidgetTester tester) async {
      final longAnswerCard = testFlashcard.copyWith(
        answer: 'This is a very long answer that should be truncated with ellipsis when displayed as a snippet in the card list item',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CardListItem(
              flashcard: longAnswerCard,
              isMastered: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('works with dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CardListItem(
              flashcard: testFlashcard,
              isMastered: false,
              cardNumber: 1,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without errors in dark theme
      expect(find.text('What is the derivative of x²?'), findsOneWidget);
      expect(find.text('MATHEMATICS'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
    });

    testWidgets('shows tap animation feedback', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isMastered: false));
      await tester.pumpAndSettle();

      // Start tap gesture
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CardListItem)),
      );
      await tester.pump();

      // Should show pressed state (animation should be running)
      expect(tester.binding.hasScheduledFrame, isTrue);

      // Complete tap gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('shows navigation arrow indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isMastered: false));
      await tester.pumpAndSettle();

      // Should show navigation arrow
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });

    testWidgets('shows subject badge with school icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isMastered: false));
      await tester.pumpAndSettle();

      // Should show school icon in subject badge
      expect(find.byIcon(Icons.school_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('shows answer snippet with lightbulb icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isMastered: false));
      await tester.pumpAndSettle();

      // Should show lightbulb icon next to answer snippet
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });
  });
}