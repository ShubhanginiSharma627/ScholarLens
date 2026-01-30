import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/text_highlight.dart';
void main() {
  group('TextHighlight', () {
    late TextHighlight testHighlight;
    late DateTime testDateTime;
    setUp(() {
      testDateTime = DateTime(2024, 1, 15, 10, 30, 0);
      testHighlight = TextHighlight(
        id: 'test_highlight_123',
        textbookId: 'textbook_456',
        chapterNumber: 3,
        sectionNumber: 2,
        highlightedText: 'This is important text to remember',
        startOffset: 100,
        endOffset: 133,
        createdAt: testDateTime,
        highlightColor: const Color(0xFFFFEB3B),
      );
    });
    group('constructor', () {
      test('creates TextHighlight with all required fields', () {
        expect(testHighlight.id, equals('test_highlight_123'));
        expect(testHighlight.textbookId, equals('textbook_456'));
        expect(testHighlight.chapterNumber, equals(3));
        expect(testHighlight.sectionNumber, equals(2));
        expect(testHighlight.highlightedText, equals('This is important text to remember'));
        expect(testHighlight.startOffset, equals(100));
        expect(testHighlight.endOffset, equals(133));
        expect(testHighlight.createdAt, equals(testDateTime));
        expect(testHighlight.highlightColor, equals(const Color(0xFFFFEB3B)));
      });
    });
    group('fromJson', () {
      test('creates TextHighlight from valid JSON', () {
        final json = {
          'id': 'json_highlight_789',
          'textbook_id': 'textbook_123',
          'chapter_number': 5,
          'section_number': 1,
          'highlighted_text': 'JSON test text',
          'start_offset': 50,
          'end_offset': 64,
          'created_at': '2024-02-20T14:30:00.000Z',
          'highlight_color': 0xFF4CAF50,
        };
        final highlight = TextHighlight.fromJson(json);
        expect(highlight.id, equals('json_highlight_789'));
        expect(highlight.textbookId, equals('textbook_123'));
        expect(highlight.chapterNumber, equals(5));
        expect(highlight.sectionNumber, equals(1));
        expect(highlight.highlightedText, equals('JSON test text'));
        expect(highlight.startOffset, equals(50));
        expect(highlight.endOffset, equals(64));
        expect(highlight.createdAt, equals(DateTime.parse('2024-02-20T14:30:00.000Z')));
        expect(highlight.highlightColor, equals(const Color(0xFF4CAF50)));
      });
    });
    group('toJson', () {
      test('converts TextHighlight to valid JSON', () {
        final json = testHighlight.toJson();
        expect(json['id'], equals('test_highlight_123'));
        expect(json['textbook_id'], equals('textbook_456'));
        expect(json['chapter_number'], equals(3));
        expect(json['section_number'], equals(2));
        expect(json['highlighted_text'], equals('This is important text to remember'));
        expect(json['start_offset'], equals(100));
        expect(json['end_offset'], equals(133));
        expect(json['created_at'], equals(testDateTime.toIso8601String()));
        expect(json['highlight_color'], equals(0xFFFFEB3B));
      });
    });
    group('JSON serialization round trip', () {
      test('maintains data integrity through fromJson -> toJson -> fromJson', () {
        final originalJson = testHighlight.toJson();
        final recreatedHighlight = TextHighlight.fromJson(originalJson);
        final finalJson = recreatedHighlight.toJson();
        expect(recreatedHighlight, equals(testHighlight));
        expect(finalJson, equals(originalJson));
      });
    });
    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updatedHighlight = testHighlight.copyWith(
          highlightedText: 'Updated text',
          highlightColor: const Color(0xFF4CAF50),
        );
        expect(updatedHighlight.id, equals(testHighlight.id));
        expect(updatedHighlight.textbookId, equals(testHighlight.textbookId));
        expect(updatedHighlight.highlightedText, equals('Updated text'));
        expect(updatedHighlight.highlightColor, equals(const Color(0xFF4CAF50)));
        expect(updatedHighlight.startOffset, equals(testHighlight.startOffset));
      });
      test('creates identical copy when no fields are updated', () {
        final copiedHighlight = testHighlight.copyWith();
        expect(copiedHighlight, equals(testHighlight));
      });
    });
    group('create factory', () {
      test('creates TextHighlight with generated ID and current timestamp', () {
        final highlight = TextHighlight.create(
          textbookId: 'new_textbook',
          chapterNumber: 1,
          sectionNumber: 1,
          highlightedText: 'New highlight text',
          startOffset: 0,
          endOffset: 18,
        );
        expect(highlight.id, startsWith('highlight_'));
        expect(highlight.textbookId, equals('new_textbook'));
        expect(highlight.chapterNumber, equals(1));
        expect(highlight.sectionNumber, equals(1));
        expect(highlight.highlightedText, equals('New highlight text'));
        expect(highlight.startOffset, equals(0));
        expect(highlight.endOffset, equals(18));
        expect(highlight.highlightColor, equals(const Color(0xFFFFEB3B))); // Default yellow
        expect(highlight.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });
      test('creates TextHighlight with custom color', () {
        final customColor = const Color(0xFF2196F3);
        final highlight = TextHighlight.create(
          textbookId: 'textbook',
          chapterNumber: 1,
          sectionNumber: 1,
          highlightedText: 'Text',
          startOffset: 0,
          endOffset: 4,
          highlightColor: customColor,
        );
        expect(highlight.highlightColor, equals(customColor));
      });
    });
    group('withColorType factory', () {
      test('creates TextHighlight with specific color type', () {
        final highlight = TextHighlight.withColorType(
          textbookId: 'textbook',
          chapterNumber: 1,
          sectionNumber: 1,
          highlightedText: 'Blue highlight',
          startOffset: 0,
          endOffset: 14,
          colorType: HighlightColorType.blue,
        );
        expect(highlight.highlightColor, equals(HighlightColorType.blue.color));
        expect(highlight.colorType, equals(HighlightColorType.blue));
      });
    });
    group('utility methods', () {
      test('textLength returns correct length', () {
        expect(testHighlight.textLength, equals(33));
      });
      test('highlightRange returns correct range', () {
        expect(testHighlight.highlightRange, equals(33));
      });
      test('containsOffset returns correct results', () {
        expect(testHighlight.containsOffset(100), isTrue);
        expect(testHighlight.containsOffset(115), isTrue);
        expect(testHighlight.containsOffset(132), isTrue);
        expect(testHighlight.containsOffset(99), isFalse);
        expect(testHighlight.containsOffset(133), isFalse);
      });
      test('getPreview returns full text when under limit', () {
        final shortHighlight = testHighlight.copyWith(highlightedText: 'Short text');
        expect(shortHighlight.getPreview(), equals('Short text'));
      });
      test('getPreview truncates long text', () {
        final longText = 'This is a very long piece of text that should be truncated';
        final longHighlight = testHighlight.copyWith(highlightedText: longText);
        final preview = longHighlight.getPreview(maxLength: 20);
        expect(preview.length, equals(20));
        expect(preview.endsWith('...'), isTrue);
        expect(preview, equals('This is a very lo...'));
      });
    });
    group('overlap detection', () {
      late TextHighlight otherHighlight;
      setUp(() {
        otherHighlight = TextHighlight(
          id: 'other_highlight',
          textbookId: 'textbook_456',
          chapterNumber: 3,
          sectionNumber: 2,
          highlightedText: 'Overlapping text',
          startOffset: 120,
          endOffset: 140,
          createdAt: DateTime.now(),
          highlightColor: const Color(0xFF4CAF50),
        );
      });
      test('detects overlapping highlights', () {
        expect(testHighlight.overlapsWith(otherHighlight), isTrue);
      });
      test('detects non-overlapping highlights', () {
        final nonOverlapping = otherHighlight.copyWith(
          startOffset: 150,
          endOffset: 170,
        );
        expect(testHighlight.overlapsWith(nonOverlapping), isFalse);
      });
      test('detects adjacent highlights as non-overlapping', () {
        final adjacent = otherHighlight.copyWith(
          startOffset: 133,
          endOffset: 150,
        );
        expect(testHighlight.overlapsWith(adjacent), isFalse);
      });
      test('returns false for different textbooks', () {
        final differentTextbook = otherHighlight.copyWith(textbookId: 'different_textbook');
        expect(testHighlight.overlapsWith(differentTextbook), isFalse);
      });
      test('returns false for different chapters', () {
        final differentChapter = otherHighlight.copyWith(chapterNumber: 4);
        expect(testHighlight.overlapsWith(differentChapter), isFalse);
      });
      test('returns false for different sections', () {
        final differentSection = otherHighlight.copyWith(sectionNumber: 3);
        expect(testHighlight.overlapsWith(differentSection), isFalse);
      });
    });
    group('equality and hashCode', () {
      test('equal highlights have same hashCode', () {
        final duplicate = TextHighlight(
          id: testHighlight.id,
          textbookId: testHighlight.textbookId,
          chapterNumber: testHighlight.chapterNumber,
          sectionNumber: testHighlight.sectionNumber,
          highlightedText: testHighlight.highlightedText,
          startOffset: testHighlight.startOffset,
          endOffset: testHighlight.endOffset,
          createdAt: testHighlight.createdAt,
          highlightColor: testHighlight.highlightColor,
        );
        expect(testHighlight, equals(duplicate));
        expect(testHighlight.hashCode, equals(duplicate.hashCode));
      });
      test('different highlights are not equal', () {
        final different = testHighlight.copyWith(id: 'different_id');
        expect(testHighlight, isNot(equals(different)));
      });
    });
    group('toString', () {
      test('returns formatted string representation', () {
        final string = testHighlight.toString();
        expect(string, contains('TextHighlight'));
        expect(string, contains('test_highlight_123'));
        expect(string, contains('textbook_456'));
        expect(string, contains('chapter: 3'));
        expect(string, contains('section: 2'));
        expect(string, contains('100-133'));
        expect(string, contains('Yellow'));
      });
    });
  });
  group('HighlightColorType', () {
    test('has all expected color types', () {
      expect(HighlightColorType.values.length, equals(6));
      expect(HighlightColorType.values, contains(HighlightColorType.yellow));
      expect(HighlightColorType.values, contains(HighlightColorType.green));
      expect(HighlightColorType.values, contains(HighlightColorType.blue));
      expect(HighlightColorType.values, contains(HighlightColorType.orange));
      expect(HighlightColorType.values, contains(HighlightColorType.pink));
      expect(HighlightColorType.values, contains(HighlightColorType.purple));
    });
    test('fromColor returns correct type for known colors', () {
      expect(HighlightColorType.fromColor(const Color(0xFFFFEB3B)), equals(HighlightColorType.yellow));
      expect(HighlightColorType.fromColor(const Color(0xFF4CAF50)), equals(HighlightColorType.green));
      expect(HighlightColorType.fromColor(const Color(0xFF2196F3)), equals(HighlightColorType.blue));
    });
    test('fromColor returns yellow for unknown colors', () {
      expect(HighlightColorType.fromColor(const Color(0xFF123456)), equals(HighlightColorType.yellow));
    });
    test('allColors returns all color values', () {
      final colors = HighlightColorType.allColors;
      expect(colors.length, equals(6));
      expect(colors, contains(const Color(0xFFFFEB3B))); // Yellow
      expect(colors, contains(const Color(0xFF4CAF50))); // Green
    });
    test('colorMap returns correct name-color mapping', () {
      final colorMap = HighlightColorType.colorMap;
      expect(colorMap.length, equals(6));
      expect(colorMap['Yellow'], equals(const Color(0xFFFFEB3B)));
      expect(colorMap['Green'], equals(const Color(0xFF4CAF50)));
      expect(colorMap['Blue'], equals(const Color(0xFF2196F3)));
    });
  });
  group('ID generation', () {
    test('generates unique IDs', () {
      final highlight1 = TextHighlight.create(
        textbookId: 'test',
        chapterNumber: 1,
        sectionNumber: 1,
        highlightedText: 'text',
        startOffset: 0,
        endOffset: 4,
      );
      final highlight2 = TextHighlight.create(
        textbookId: 'test',
        chapterNumber: 1,
        sectionNumber: 1,
        highlightedText: 'text',
        startOffset: 0,
        endOffset: 4,
      );
      expect(highlight1.id, isNot(equals(highlight2.id)));
      expect(highlight1.id, startsWith('highlight_'));
      expect(highlight2.id, startsWith('highlight_'));
    });
  });
}