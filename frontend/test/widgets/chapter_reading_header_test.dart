import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/uploaded_textbook.dart';
import 'package:scholar_lens/models/chapter_reading_state.dart';
import 'package:scholar_lens/models/chapter_section.dart';
import 'package:scholar_lens/widgets/chapter_reading_header.dart';
import 'package:scholar_lens/theme/app_theme.dart';
void main() {
  group('ChapterReadingHeader', () {
    late UploadedTextbook mockTextbook;
    late ChapterReadingState mockReadingState;
    setUp(() {
      mockTextbook = UploadedTextbook(
        id: 'test-textbook-1',
        title: 'Test Textbook',
        fileName: 'test.pdf',
        fileSize: '10MB',
        status: TextbookStatus.ready,
        uploadedAt: DateTime.now(),
        chapters: ['Chapter 1', 'Chapter 2'],
        totalPages: 100,
        keyTopics: ['topic1', 'topic2'],
        subject: 'Mathematics',
      );
      final mockSections = [
        const ChapterSection(
          sectionNumber: 1,
          title: 'Introduction',
          content: 'Test content',
          keyTerms: ['term1'],
          isCompleted: false,
        ),
        const ChapterSection(
          sectionNumber: 2,
          title: 'Main Content',
          content: 'Test content 2',
          keyTerms: ['term2'],
          isCompleted: true,
        ),
      ];
      mockReadingState = ChapterReadingState.initial(
        textbookId: 'test-textbook-1',
        chapterNumber: 1,
        sections: mockSections,
      ).copyWith(readingProgress: 0.5);
    });
    testWidgets('renders header with textbook navigation', (WidgetTester tester) async {
      bool backPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ChapterReadingHeader(
              textbook: mockTextbook,
              readingState: mockReadingState,
              onBackPressed: () => backPressed = true,
              chapterTitle: 'Test Chapter',
              pageRange: 'pp. 1-25',
              estimatedReadingTime: 15,
            ),
          ),
        ),
      );
      expect(find.text('Back to Test Textbook'), findsOneWidget);
      expect(find.text('Test Chapter'), findsOneWidget);
      expect(find.text('pp. 1-25'), findsOneWidget);
      expect(find.text('15 min read'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(backPressed, isTrue);
    });
    testWidgets('displays completion status when chapter is completed', (WidgetTester tester) async {
      final completedState = mockReadingState.copyWith(readingProgress: 1.0);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ChapterReadingHeader(
              textbook: mockTextbook,
              readingState: completedState,
              onBackPressed: () {},
              chapterTitle: 'Test Chapter',
              isChapterCompleted: true,
            ),
          ),
        ),
      );
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
    testWidgets('shows animated progress bar with correct percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ChapterReadingHeader(
              textbook: mockTextbook,
              readingState: mockReadingState,
              onBackPressed: () {},
              chapterTitle: 'Test Chapter',
            ),
          ),
        ),
      );
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('(1/2 sections)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
    testWidgets('displays reading time when available', (WidgetTester tester) async {
      final stateWithTime = mockReadingState.copyWith(
        readingTime: const Duration(minutes: 25),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ChapterReadingHeader(
              textbook: mockTextbook,
              readingState: stateWithTime,
              onBackPressed: () {},
              chapterTitle: 'Test Chapter',
              estimatedReadingTime: 30,
            ),
          ),
        ),
      );
      expect(find.text('Reading time: 25m'), findsOneWidget);
      expect(find.text('5 min remaining'), findsOneWidget);
    });
    testWidgets('handles missing optional parameters gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ChapterReadingHeader(
              textbook: mockTextbook,
              readingState: mockReadingState,
              onBackPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });
}