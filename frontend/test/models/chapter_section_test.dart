import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/models/chapter_section.dart';
void main() {
  group('ChapterSection', () {
    const testSectionNumber = 1;
    const testTitle = 'Introduction to Physics';
    const testContent = 'Physics is the natural science that studies matter, its motion and behavior through space and time, and the related entities of energy and force. Physics is one of the most fundamental scientific disciplines, and its main goal is to understand how the universe behaves.';
    const testKeyTerms = ['matter', 'energy', 'force', 'motion'];
    group('constructor', () {
      test('creates ChapterSection with all required fields', () {
        final section = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
        expect(section.sectionNumber, testSectionNumber);
        expect(section.title, testTitle);
        expect(section.content, testContent);
        expect(section.keyTerms, testKeyTerms);
        expect(section.isCompleted, false);
        expect(section.completedAt, isNull);
      });
      test('creates ChapterSection with completion data', () {
        final completedAt = DateTime.now();
        final section = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: true,
          completedAt: completedAt,
        );
        expect(section.isCompleted, true);
        expect(section.completedAt, completedAt);
      });
    });
    group('factory constructors', () {
      test('create() creates ChapterSection with default values', () {
        final section = ChapterSection.create(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
        );
        expect(section.sectionNumber, testSectionNumber);
        expect(section.title, testTitle);
        expect(section.content, testContent);
        expect(section.keyTerms, isEmpty);
        expect(section.isCompleted, false);
        expect(section.completedAt, isNull);
      });
      test('create() creates ChapterSection with provided key terms', () {
        final section = ChapterSection.create(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
        );
        expect(section.keyTerms, testKeyTerms);
      });
    });
    group('JSON serialization', () {
      test('fromJson creates ChapterSection from valid JSON', () {
        final json = {
          'section_number': testSectionNumber,
          'title': testTitle,
          'content': testContent,
          'key_terms': testKeyTerms,
          'is_completed': false,
          'completed_at': null,
        };
        final section = ChapterSection.fromJson(json);
        expect(section.sectionNumber, testSectionNumber);
        expect(section.title, testTitle);
        expect(section.content, testContent);
        expect(section.keyTerms, testKeyTerms);
        expect(section.isCompleted, false);
        expect(section.completedAt, isNull);
      });
      test('fromJson creates ChapterSection with completion date', () {
        final completedAt = DateTime.now();
        final json = {
          'section_number': testSectionNumber,
          'title': testTitle,
          'content': testContent,
          'key_terms': testKeyTerms,
          'is_completed': true,
          'completed_at': completedAt.toIso8601String(),
        };
        final section = ChapterSection.fromJson(json);
        expect(section.isCompleted, true);
        expect(section.completedAt, completedAt);
      });
      test('toJson converts ChapterSection to valid JSON', () {
        final section = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
        final json = section.toJson();
        expect(json['section_number'], testSectionNumber);
        expect(json['title'], testTitle);
        expect(json['content'], testContent);
        expect(json['key_terms'], testKeyTerms);
        expect(json['is_completed'], false);
        expect(json['completed_at'], isNull);
      });
      test('toJson converts ChapterSection with completion date to valid JSON', () {
        final completedAt = DateTime.now();
        final section = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: true,
          completedAt: completedAt,
        );
        final json = section.toJson();
        expect(json['is_completed'], true);
        expect(json['completed_at'], completedAt.toIso8601String());
      });
      test('JSON round trip preserves all data', () {
        final originalSection = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        final json = originalSection.toJson();
        final restoredSection = ChapterSection.fromJson(json);
        expect(restoredSection, originalSection);
      });
    });
    group('copyWith', () {
      late ChapterSection originalSection;
      setUp(() {
        originalSection = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
      });
      test('copyWith creates new instance with updated fields', () {
        const newTitle = 'Advanced Physics';
        final updatedSection = originalSection.copyWith(title: newTitle);
        expect(updatedSection.title, newTitle);
        expect(updatedSection.sectionNumber, originalSection.sectionNumber);
        expect(updatedSection.content, originalSection.content);
        expect(updatedSection.keyTerms, originalSection.keyTerms);
        expect(updatedSection.isCompleted, originalSection.isCompleted);
      });
      test('copyWith preserves original when no parameters provided', () {
        final copiedSection = originalSection.copyWith();
        expect(copiedSection, originalSection);
        expect(identical(copiedSection, originalSection), false);
      });
      test('copyWith updates completion status', () {
        final completedAt = DateTime.now();
        final completedSection = originalSection.copyWith(
          isCompleted: true,
          completedAt: completedAt,
        );
        expect(completedSection.isCompleted, true);
        expect(completedSection.completedAt, completedAt);
      });
    });
    group('completion methods', () {
      late ChapterSection incompleteSection;
      setUp(() {
        incompleteSection = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
      });
      test('markCompleted sets completion status and timestamp', () {
        final completedSection = incompleteSection.markCompleted();
        expect(completedSection.isCompleted, true);
        expect(completedSection.completedAt, isNotNull);
        expect(completedSection.completedAt!.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
      });
      test('markIncomplete clears completion status and timestamp', () {
        final completedSection = incompleteSection.markCompleted();
        final incompleteAgain = completedSection.markIncomplete();
        expect(incompleteAgain.isCompleted, false);
        expect(incompleteAgain.completedAt, isNull);
      });
    });
    group('computed properties', () {
      test('estimatedReadingTimeMinutes calculates based on word count', () {
        final section = ChapterSection.create(
          sectionNumber: 1,
          title: 'Test',
          content: testContent,
        );
        expect(section.estimatedReadingTimeMinutes, 1);
      });
      test('estimatedReadingTimeMinutes handles longer content', () {
        final longContent = List.filled(10, testContent).join(' ');
        final section = ChapterSection.create(
          sectionNumber: 1,
          title: 'Test',
          content: longContent,
        );
        expect(section.estimatedReadingTimeMinutes, greaterThan(1));
      });
      test('wordCount returns correct word count', () {
        final section = ChapterSection.create(
          sectionNumber: 1,
          title: 'Test',
          content: testContent,
        );
        expect(section.wordCount, greaterThan(30));
        expect(section.wordCount, lessThan(50));
      });
      test('hasKeyTerms returns true when key terms exist', () {
        final section = ChapterSection.create(
          sectionNumber: 1,
          title: 'Test',
          content: testContent,
          keyTerms: testKeyTerms,
        );
        expect(section.hasKeyTerms, true);
      });
      test('hasKeyTerms returns false when no key terms', () {
        final section = ChapterSection.create(
          sectionNumber: 1,
          title: 'Test',
          content: testContent,
        );
        expect(section.hasKeyTerms, false);
      });
    });
    group('equality and hashCode', () {
      test('equal sections have same hashCode', () {
        final section1 = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
        final section2 = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
        expect(section1, section2);
        expect(section1.hashCode, section2.hashCode);
      });
      test('different sections are not equal', () {
        final section1 = ChapterSection(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
        final section2 = ChapterSection(
          sectionNumber: 2,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
          isCompleted: false,
        );
        expect(section1, isNot(section2));
      });
    });
    group('toString', () {
      test('toString provides meaningful representation', () {
        final section = ChapterSection.create(
          sectionNumber: testSectionNumber,
          title: testTitle,
          content: testContent,
          keyTerms: testKeyTerms,
        );
        final stringRepresentation = section.toString();
        expect(stringRepresentation, contains('ChapterSection'));
        expect(stringRepresentation, contains('sectionNumber: $testSectionNumber'));
        expect(stringRepresentation, contains('title: $testTitle'));
        expect(stringRepresentation, contains('isCompleted: false'));
        expect(stringRepresentation, contains('keyTerms: ${testKeyTerms.length}'));
      });
    });
  });
}