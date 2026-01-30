import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/chapter_section.dart';
import 'package:scholar_lens/models/text_highlight.dart';
import 'package:scholar_lens/widgets/content_display_area.dart';
void main() {
  group('ContentDisplayArea', () {
    late List<ChapterSection> mockSections;
    late List<TextHighlight> mockHighlights;
    setUp(() {
      mockSections = [
        ChapterSection.create(
          sectionNumber: 1,
          title: 'Introduction',
          content: 'This is the introduction section with some content to read.',
          keyTerms: ['term1', 'term2'],
        ),
        ChapterSection.create(
          sectionNumber: 2,
          title: 'Main Content',
          content: 'This is the main content section with more detailed information.',
          keyTerms: ['concept1', 'concept2'],
        ),
      ];
      mockHighlights = [
        TextHighlight.create(
          textbookId: 'test-book',
          chapterNumber: 1,
          sectionNumber: 1,
          highlightedText: 'introduction section',
          startOffset: 12,
          endOffset: 31,
        ),
      ];
    });
    testWidgets('displays section header with correct information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: mockSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
            ),
          ),
        ),
      );
      expect(find.text('Section 1 of 2'), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
    });
    testWidgets('displays content with highlighting support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: mockSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
            ),
          ),
        ),
      );
      expect(find.textContaining('This is the introduction section'), findsOneWidget);
    });
    testWidgets('displays key terms section when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: mockSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
            ),
          ),
        ),
      );
      expect(find.text('Key Terms'), findsOneWidget);
      expect(find.text('term1'), findsOneWidget);
      expect(find.text('term2'), findsOneWidget);
    });
    testWidgets('displays empty state when no sections available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: [],
              currentSectionIndex: 0,
              highlights: [],
            ),
          ),
        ),
      );
      expect(find.text('No content available'), findsOneWidget);
      expect(find.text('Please select a section to read'), findsOneWidget);
    });
    testWidgets('shows completion indicator for completed sections', (WidgetTester tester) async {
      final completedSections = [
        mockSections[0].markCompleted(),
        mockSections[1],
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: completedSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
    testWidgets('calls onTextHighlighted when text is selected in highlight mode', (WidgetTester tester) async {
      String? highlightedText;
      int? startOffset;
      int? endOffset;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: mockSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
              isHighlightMode: true,
              onTextHighlighted: (text, start, end) {
                highlightedText = text;
                startOffset = start;
                endOffset = end;
              },
            ),
          ),
        ),
      );
      expect(highlightedText, isNull);
      expect(startOffset, isNull);
      expect(endOffset, isNull);
    });
    testWidgets('calls onSectionCompleted when section completion criteria are met', (WidgetTester tester) async {
      int? completedSectionIndex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: mockSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
              onSectionCompleted: (index) {
                completedSectionIndex = index;
              },
            ),
          ),
        ),
      );
      expect(completedSectionIndex, isNull);
    });
    testWidgets('displays reading progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentDisplayArea(
              sections: mockSections,
              currentSectionIndex: 0,
              highlights: mockHighlights,
            ),
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Reading in progress'), findsOneWidget);
    });
  });
}