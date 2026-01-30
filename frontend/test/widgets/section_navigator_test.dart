import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/widgets/section_navigator.dart';
import 'package:scholar_lens/models/chapter_section.dart';
import 'package:scholar_lens/theme/app_theme.dart';
void main() {
  group('SectionNavigator', () {
    late List<ChapterSection> mockSections;
    late List<bool> mockCompletionStatus;
    setUp(() {
      mockSections = [
        ChapterSection.create(
          sectionNumber: 1,
          title: 'Introduction',
          content: 'This is the introduction section.',
        ),
        ChapterSection.create(
          sectionNumber: 2,
          title: 'Main Content',
          content: 'This is the main content section.',
        ).markCompleted(),
        ChapterSection.create(
          sectionNumber: 3,
          title: 'Conclusion',
          content: 'This is the conclusion section.',
        ),
      ];
      mockCompletionStatus = [false, true, false];
    });
    Widget createTestWidget({
      int currentSection = 1,
      int totalSections = 3,
      List<bool>? completionStatus,
      List<ChapterSection>? sections,
      Function(int)? onSectionChanged,
      VoidCallback? onPreviousPressed,
      VoidCallback? onNextPressed,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SectionNavigator(
            currentSection: currentSection,
            totalSections: totalSections,
            sectionCompletionStatus: completionStatus ?? mockCompletionStatus,
            sections: sections ?? mockSections,
            onSectionChanged: onSectionChanged ?? (index) {},
            onPreviousPressed: onPreviousPressed,
            onNextPressed: onNextPressed,
          ),
        ),
      );
    }
    testWidgets('displays current section indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentSection: 2,
        totalSections: 3,
      ));
      expect(find.text('Section 2 of 3'), findsOneWidget);
    });
    testWidgets('displays navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('All Sections'), findsOneWidget);
    });
    testWidgets('disables previous button on first section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(currentSection: 1));
      final previousButton = find.widgetWithText(OutlinedButton, 'Previous');
      expect(previousButton, findsOneWidget);
      final button = tester.widget<OutlinedButton>(previousButton);
      expect(button.onPressed, isNull);
    });
    testWidgets('disables next button on last section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentSection: 3,
        totalSections: 3,
      ));
      final nextButton = find.widgetWithText(OutlinedButton, 'Next');
      expect(nextButton, findsOneWidget);
      final button = tester.widget<OutlinedButton>(nextButton);
      expect(button.onPressed, isNull);
    });
    testWidgets('calls onPreviousPressed when previous button is tapped', (WidgetTester tester) async {
      bool previousPressed = false;
      await tester.pumpWidget(createTestWidget(
        currentSection: 2,
        onPreviousPressed: () => previousPressed = true,
      ));
      await tester.tap(find.text('Previous'));
      expect(previousPressed, isTrue);
    });
    testWidgets('calls onNextPressed when next button is tapped', (WidgetTester tester) async {
      bool nextPressed = false;
      await tester.pumpWidget(createTestWidget(
        currentSection: 1,
        onNextPressed: () => nextPressed = true,
      ));
      await tester.tap(find.text('Next'));
      expect(nextPressed, isTrue);
    });
    testWidgets('shows section overview modal when All Sections is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('All Sections'));
      await tester.pumpAndSettle();
      expect(find.text('All Sections'), findsNWidgets(2)); // Button + modal header
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Conclusion'), findsOneWidget);
    });
    testWidgets('displays completion indicators in section overview', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('All Sections'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget); // Only section 2 is completed
    });
    testWidgets('highlights current section in overview', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(currentSection: 2));
      await tester.tap(find.text('All Sections'));
      await tester.pumpAndSettle();
      expect(find.text('Current Section'), findsOneWidget);
    });
    testWidgets('calls onSectionChanged when section is selected from overview', (WidgetTester tester) async {
      int? selectedSection;
      await tester.pumpWidget(createTestWidget(
        onSectionChanged: (index) => selectedSection = index,
      ));
      await tester.tap(find.text('All Sections'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conclusion'));
      expect(selectedSection, equals(3));
    });
  });
}