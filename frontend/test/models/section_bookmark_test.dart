import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/section_bookmark.dart';

void main() {
  group('BookmarkCategory', () {
    test('should have correct display names and icons', () {
      expect(BookmarkCategory.important.displayName, 'Important');
      expect(BookmarkCategory.important.icon, '⭐');
      expect(BookmarkCategory.review.displayName, 'Review Later');
      expect(BookmarkCategory.review.icon, '📖');
      expect(BookmarkCategory.question.displayName, 'Question');
      expect(BookmarkCategory.question.icon, '❓');
      expect(BookmarkCategory.reference.displayName, 'Reference');
      expect(BookmarkCategory.reference.icon, '📌');
      expect(BookmarkCategory.summary.displayName, 'Summary');
      expect(BookmarkCategory.summary.icon, '📝');
      expect(BookmarkCategory.custom.displayName, 'Custom');
      expect(BookmarkCategory.custom.icon, '🏷️');
    });

    test('fromString should return correct category', () {
      expect(BookmarkCategory.fromString('important'), BookmarkCategory.important);
      expect(BookmarkCategory.fromString('review'), BookmarkCategory.review);
      expect(BookmarkCategory.fromString('question'), BookmarkCategory.question);
      expect(BookmarkCategory.fromString('reference'), BookmarkCategory.reference);
      expect(BookmarkCategory.fromString('summary'), BookmarkCategory.summary);
      expect(BookmarkCategory.fromString('custom'), BookmarkCategory.custom);
    });

    test('fromString should return default for unknown category', () {
      expect(BookmarkCategory.fromString('unknown'), BookmarkCategory.important);
      expect(BookmarkCategory.fromString(''), BookmarkCategory.important);
    });

    test('allCategories should return all categories', () {
      final categories = BookmarkCategory.allCategories;
      expect(categories.length, 6);
      expect(categories.contains(BookmarkCategory.important), true);
      expect(categories.contains(BookmarkCategory.review), true);
      expect(categories.contains(BookmarkCategory.question), true);
      expect(categories.contains(BookmarkCategory.reference), true);
      expect(categories.contains(BookmarkCategory.summary), true);
      expect(categories.contains(BookmarkCategory.custom), true);
    });

    test('categoryMap should return correct mapping', () {
      final categoryMap = BookmarkCategory.categoryMap;
      expect(categoryMap['Important'], BookmarkCategory.important);
      expect(categoryMap['Review Later'], BookmarkCategory.review);
      expect(categoryMap['Question'], BookmarkCategory.question);
      expect(categoryMap['Reference'], BookmarkCategory.reference);
      expect(categoryMap['Summary'], BookmarkCategory.summary);
      expect(categoryMap['Custom'], BookmarkCategory.custom);
    });
  });

  group('SectionBookmark', () {
    late SectionBookmark testBookmark;

    setUp(() {
      testBookmark = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 5,
        sectionNumber: 2,
        sectionTitle: 'Introduction to Quantum Physics',
        note: 'Important concepts about wave-particle duality',
        category: BookmarkCategory.important,
      );
    });

    test('create should generate valid bookmark with all required fields', () {
      expect(testBookmark.id.isNotEmpty, true);
      expect(testBookmark.id.startsWith('bookmark_'), true);
      expect(testBookmark.textbookId, 'textbook_123');
      expect(testBookmark.chapterNumber, 5);
      expect(testBookmark.sectionNumber, 2);
      expect(testBookmark.sectionTitle, 'Introduction to Quantum Physics');
      expect(testBookmark.note, 'Important concepts about wave-particle duality');
      expect(testBookmark.category, BookmarkCategory.important);
      expect(testBookmark.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
      expect(testBookmark.lastModified, isNotNull);
    });

    test('create with empty note should not set lastModified', () {
      final bookmark = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 1,
        sectionNumber: 1,
        sectionTitle: 'Test Section',
      );

      expect(bookmark.note, '');
      expect(bookmark.lastModified, isNull);
      expect(bookmark.category, BookmarkCategory.important); // Default category
    });

    test('withCategory should create bookmark with specified category', () {
      final bookmark = SectionBookmark.withCategory(
        textbookId: 'textbook_123',
        chapterNumber: 1,
        sectionNumber: 1,
        sectionTitle: 'Test Section',
        category: BookmarkCategory.question,
        note: 'Need to review this',
      );

      expect(bookmark.category, BookmarkCategory.question);
      expect(bookmark.note, 'Need to review this');
      expect(bookmark.lastModified, isNotNull);
    });

    test('toJson should serialize correctly', () {
      final json = testBookmark.toJson();

      expect(json['id'], testBookmark.id);
      expect(json['textbook_id'], 'textbook_123');
      expect(json['chapter_number'], 5);
      expect(json['section_number'], 2);
      expect(json['section_title'], 'Introduction to Quantum Physics');
      expect(json['note'], 'Important concepts about wave-particle duality');
      expect(json['created_at'], testBookmark.createdAt.toIso8601String());
      expect(json['category'], 'important');
      expect(json['last_modified'], testBookmark.lastModified?.toIso8601String());
    });

    test('fromJson should deserialize correctly', () {
      final json = testBookmark.toJson();
      final deserializedBookmark = SectionBookmark.fromJson(json);

      expect(deserializedBookmark.id, testBookmark.id);
      expect(deserializedBookmark.textbookId, testBookmark.textbookId);
      expect(deserializedBookmark.chapterNumber, testBookmark.chapterNumber);
      expect(deserializedBookmark.sectionNumber, testBookmark.sectionNumber);
      expect(deserializedBookmark.sectionTitle, testBookmark.sectionTitle);
      expect(deserializedBookmark.note, testBookmark.note);
      expect(deserializedBookmark.createdAt, testBookmark.createdAt);
      expect(deserializedBookmark.category, testBookmark.category);
      expect(deserializedBookmark.lastModified, testBookmark.lastModified);
    });

    test('fromJson should handle null lastModified', () {
      final json = {
        'id': 'test_id',
        'textbook_id': 'textbook_123',
        'chapter_number': 1,
        'section_number': 1,
        'section_title': 'Test Section',
        'note': '',
        'created_at': DateTime.now().toIso8601String(),
        'category': 'important',
        'last_modified': null,
      };

      final bookmark = SectionBookmark.fromJson(json);
      expect(bookmark.lastModified, isNull);
    });

    test('copyWith should create updated copy', () {
      final updatedBookmark = testBookmark.copyWith(
        note: 'Updated note',
        category: BookmarkCategory.review,
      );

      expect(updatedBookmark.id, testBookmark.id);
      expect(updatedBookmark.textbookId, testBookmark.textbookId);
      expect(updatedBookmark.chapterNumber, testBookmark.chapterNumber);
      expect(updatedBookmark.sectionNumber, testBookmark.sectionNumber);
      expect(updatedBookmark.sectionTitle, testBookmark.sectionTitle);
      expect(updatedBookmark.note, 'Updated note');
      expect(updatedBookmark.category, BookmarkCategory.review);
      expect(updatedBookmark.createdAt, testBookmark.createdAt);
    });

    test('copyWith with clearLastModified should clear lastModified', () {
      final updatedBookmark = testBookmark.copyWith(clearLastModified: true);
      expect(updatedBookmark.lastModified, isNull);
    });

    test('updateNote should update note and lastModified', () {
      final originalLastModified = testBookmark.lastModified;
      
      // Wait a small amount to ensure timestamp difference
      Future.delayed(const Duration(milliseconds: 1));
      
      final updatedBookmark = testBookmark.updateNote('New note content');

      expect(updatedBookmark.note, 'New note content');
      expect(updatedBookmark.lastModified, isNotNull);
      expect(updatedBookmark.lastModified!.isAfter(testBookmark.createdAt), true);
      // Note: We can't reliably test that lastModified is after originalLastModified
      // due to potential timing issues in tests
    });

    test('updateCategory should update category and lastModified', () {
      final updatedBookmark = testBookmark.updateCategory(BookmarkCategory.question);

      expect(updatedBookmark.category, BookmarkCategory.question);
      expect(updatedBookmark.lastModified, isNotNull);
      expect(updatedBookmark.lastModified!.isAfter(testBookmark.createdAt), true);
    });

    test('updateNoteAndCategory should update both fields', () {
      final updatedBookmark = testBookmark.updateNoteAndCategory(
        'New note',
        BookmarkCategory.summary,
      );

      expect(updatedBookmark.note, 'New note');
      expect(updatedBookmark.category, BookmarkCategory.summary);
      expect(updatedBookmark.lastModified, isNotNull);
    });

    test('hasNote should return correct value', () {
      expect(testBookmark.hasNote, true);

      final emptyNoteBookmark = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 1,
        sectionNumber: 1,
        sectionTitle: 'Test Section',
      );
      expect(emptyNoteBookmark.hasNote, false);
    });

    test('hasBeenModified should return correct value', () {
      // Bookmark with note should be considered modified
      expect(testBookmark.hasBeenModified, true);

      // Bookmark without note should not be modified
      final emptyNoteBookmark = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 1,
        sectionNumber: 1,
        sectionTitle: 'Test Section',
      );
      expect(emptyNoteBookmark.hasBeenModified, false);
    });

    test('getNotePreview should truncate long notes', () {
      final longNote = 'This is a very long note that should be truncated when we request a preview with a maximum length limit';
      final bookmarkWithLongNote = testBookmark.copyWith(note: longNote);

      expect(bookmarkWithLongNote.getNotePreview(maxLength: 20), 'This is a very l...');
      expect(bookmarkWithLongNote.getNotePreview(maxLength: 100), longNote); // Shorter than limit
    });

    test('getNotePreview should return "No note" for empty notes', () {
      final emptyNoteBookmark = testBookmark.copyWith(note: '');
      expect(emptyNoteBookmark.getNotePreview(), 'No note');
    });

    test('displayText should return note preview or section title', () {
      expect(testBookmark.displayText, 'Important concepts about wave-particle duality');

      final emptyNoteBookmark = testBookmark.copyWith(note: '');
      expect(emptyNoteBookmark.displayText, 'Introduction to Quantum Physics');
    });

    test('sectionReference should return correct format', () {
      expect(testBookmark.sectionReference, 'Chapter 5, Section 2');
    });

    test('fullReference should return complete reference', () {
      expect(testBookmark.fullReference, 'Chapter 5, Section 2: Introduction to Quantum Physics');
    });

    test('isSameSection should compare sections correctly', () {
      final sameSection = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 5,
        sectionNumber: 2,
        sectionTitle: 'Different Title',
      );

      final differentSection = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 5,
        sectionNumber: 3,
        sectionTitle: 'Introduction to Quantum Physics',
      );

      final differentTextbook = SectionBookmark.create(
        textbookId: 'textbook_456',
        chapterNumber: 5,
        sectionNumber: 2,
        sectionTitle: 'Introduction to Quantum Physics',
      );

      expect(testBookmark.isSameSection(sameSection), true);
      expect(testBookmark.isSameSection(differentSection), false);
      expect(testBookmark.isSameSection(differentTextbook), false);
    });

    test('ageInDays should calculate correctly', () {
      // Create bookmark with specific date
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final pastBookmark = testBookmark.copyWith(createdAt: pastDate);

      expect(pastBookmark.ageInDays, 5);
    });

    test('isRecent should return correct value', () {
      expect(testBookmark.isRecent, true); // Just created

      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      final oldBookmark = testBookmark.copyWith(createdAt: oldDate);
      expect(oldBookmark.isRecent, false);
    });

    test('isValid should validate bookmark data', () {
      expect(testBookmark.isValid(), true);

      // Test invalid cases
      final invalidId = testBookmark.copyWith(id: '');
      expect(invalidId.isValid(), false);

      final invalidTextbookId = testBookmark.copyWith(textbookId: '');
      expect(invalidTextbookId.isValid(), false);

      final invalidChapter = testBookmark.copyWith(chapterNumber: 0);
      expect(invalidChapter.isValid(), false);

      final invalidSection = testBookmark.copyWith(sectionNumber: -1);
      expect(invalidSection.isValid(), false);

      final invalidTitle = testBookmark.copyWith(sectionTitle: '');
      expect(invalidTitle.isValid(), false);

      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final futureBookmark = testBookmark.copyWith(createdAt: futureDate);
      expect(futureBookmark.isValid(), false);
    });

    test('equality should work correctly', () {
      final json = testBookmark.toJson();
      final identicalBookmark = SectionBookmark.fromJson(json);
      final differentBookmark = testBookmark.copyWith(note: 'Different note');

      expect(testBookmark == identicalBookmark, true);
      expect(testBookmark == differentBookmark, false);
      expect(testBookmark.hashCode == identicalBookmark.hashCode, true);
      expect(testBookmark.hashCode == differentBookmark.hashCode, false);
    });

    test('toString should provide useful information', () {
      final stringRepresentation = testBookmark.toString();

      expect(stringRepresentation.contains('SectionBookmark'), true);
      expect(stringRepresentation.contains(testBookmark.id), true);
      expect(stringRepresentation.contains('textbook_123'), true);
      expect(stringRepresentation.contains('chapter: 5'), true);
      expect(stringRepresentation.contains('section: 2'), true);
      expect(stringRepresentation.contains('Important'), true);
      expect(stringRepresentation.contains('Important concepts about'), true);
    });

    test('unique IDs should be generated', () {
      final bookmark1 = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 1,
        sectionNumber: 1,
        sectionTitle: 'Test Section',
      );

      final bookmark2 = SectionBookmark.create(
        textbookId: 'textbook_123',
        chapterNumber: 1,
        sectionNumber: 1,
        sectionTitle: 'Test Section',
      );

      expect(bookmark1.id != bookmark2.id, true);
      expect(bookmark1.id.startsWith('bookmark_'), true);
      expect(bookmark2.id.startsWith('bookmark_'), true);
    });
  });
}