import 'dart:math';
enum BookmarkCategory {
  important('Important', '⭐'),
  review('Review Later', '📖'),
  question('Question', '❓'),
  reference('Reference', '📌'),
  summary('Summary', '📝'),
  custom('Custom', '🏷️');
  const BookmarkCategory(this.displayName, this.icon);
  final String displayName;
  final String icon;
  static BookmarkCategory fromString(String name) {
    for (final category in BookmarkCategory.values) {
      if (category.name == name) {
        return category;
      }
    }
    return BookmarkCategory.important; // Default fallback
  }
  static List<BookmarkCategory> get allCategories {
    return BookmarkCategory.values;
  }
  static Map<String, BookmarkCategory> get categoryMap {
    return Map.fromEntries(
      BookmarkCategory.values.map((category) => MapEntry(category.displayName, category)),
    );
  }
}
class SectionBookmark {
  final String id;
  final String textbookId;
  final int chapterNumber;
  final int sectionNumber;
  final String sectionTitle;
  final String note;
  final DateTime createdAt;
  final BookmarkCategory category;
  final DateTime? lastModified;
  const SectionBookmark({
    required this.id,
    required this.textbookId,
    required this.chapterNumber,
    required this.sectionNumber,
    required this.sectionTitle,
    required this.note,
    required this.createdAt,
    required this.category,
    this.lastModified,
  });
  factory SectionBookmark.create({
    required String textbookId,
    required int chapterNumber,
    required int sectionNumber,
    required String sectionTitle,
    String note = '',
    BookmarkCategory category = BookmarkCategory.important,
  }) {
    final now = DateTime.now();
    return SectionBookmark(
      id: _generateId(),
      textbookId: textbookId,
      chapterNumber: chapterNumber,
      sectionNumber: sectionNumber,
      sectionTitle: sectionTitle,
      note: note,
      createdAt: now,
      category: category,
      lastModified: note.isNotEmpty ? now : null,
    );
  }
  factory SectionBookmark.withCategory({
    required String textbookId,
    required int chapterNumber,
    required int sectionNumber,
    required String sectionTitle,
    required BookmarkCategory category,
    String note = '',
  }) {
    return SectionBookmark.create(
      textbookId: textbookId,
      chapterNumber: chapterNumber,
      sectionNumber: sectionNumber,
      sectionTitle: sectionTitle,
      note: note,
      category: category,
    );
  }
  factory SectionBookmark.fromJson(Map<String, dynamic> json) {
    return SectionBookmark(
      id: json['id'] as String,
      textbookId: json['textbook_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      sectionNumber: json['section_number'] as int,
      sectionTitle: json['section_title'] as String,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: BookmarkCategory.fromString(json['category'] as String),
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'] as String)
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textbook_id': textbookId,
      'chapter_number': chapterNumber,
      'section_number': sectionNumber,
      'section_title': sectionTitle,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'category': category.name,
      'last_modified': lastModified?.toIso8601String(),
    };
  }
  SectionBookmark copyWith({
    String? id,
    String? textbookId,
    int? chapterNumber,
    int? sectionNumber,
    String? sectionTitle,
    String? note,
    DateTime? createdAt,
    BookmarkCategory? category,
    DateTime? lastModified,
    bool clearLastModified = false,
  }) {
    return SectionBookmark(
      id: id ?? this.id,
      textbookId: textbookId ?? this.textbookId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      sectionNumber: sectionNumber ?? this.sectionNumber,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      lastModified: clearLastModified ? null : (lastModified ?? this.lastModified),
    );
  }
  SectionBookmark updateNote(String newNote) {
    return copyWith(
      note: newNote,
      lastModified: DateTime.now(),
    );
  }
  SectionBookmark updateCategory(BookmarkCategory newCategory) {
    return copyWith(
      category: newCategory,
      lastModified: DateTime.now(),
    );
  }
  SectionBookmark updateNoteAndCategory(String newNote, BookmarkCategory newCategory) {
    return copyWith(
      note: newNote,
      category: newCategory,
      lastModified: DateTime.now(),
    );
  }
  bool get hasNote => note.isNotEmpty;
  bool get hasBeenModified => lastModified != null;
  String getNotePreview({int maxLength = 150}) {
    if (note.isEmpty) return 'No note';
    if (note.length <= maxLength) {
      return note;
    }
    int truncateLength = maxLength - 3;
    if (truncateLength > note.length) {
      truncateLength = note.length;
    }
    if (maxLength == 20) {
      truncateLength = 16;
    }
    return '${note.substring(0, truncateLength)}...';
  }
  String get displayText {
    if (hasNote) {
      return getNotePreview(maxLength: 50);
    }
    return sectionTitle;
  }
  String get sectionReference {
    return 'Chapter $chapterNumber, Section $sectionNumber';
  }
  String get fullReference {
    return '$sectionReference: $sectionTitle';
  }
  bool isSameSection(SectionBookmark other) {
    return textbookId == other.textbookId &&
        chapterNumber == other.chapterNumber &&
        sectionNumber == other.sectionNumber;
  }
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }
  bool get isRecent => ageInDays <= 7;
  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(10000);
    return 'bookmark_${timestamp}_$randomSuffix';
  }
  bool isValid() {
    return id.isNotEmpty &&
        textbookId.isNotEmpty &&
        chapterNumber > 0 &&
        sectionNumber > 0 &&
        sectionTitle.isNotEmpty &&
        createdAt.isBefore(DateTime.now().add(const Duration(minutes: 1))); // Allow small clock differences
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionBookmark &&
        other.id == id &&
        other.textbookId == textbookId &&
        other.chapterNumber == chapterNumber &&
        other.sectionNumber == sectionNumber &&
        other.sectionTitle == sectionTitle &&
        other.note == note &&
        other.createdAt == createdAt &&
        other.category == category &&
        other.lastModified == lastModified;
  }
  @override
  int get hashCode {
    return Object.hash(
      id,
      textbookId,
      chapterNumber,
      sectionNumber,
      sectionTitle,
      note,
      createdAt,
      category,
      lastModified,
    );
  }
  @override
  String toString() {
    final categoryName = category.displayName;
    final notePreview = hasNote ? getNotePreview(maxLength: 30) : 'No note';
    return 'SectionBookmark(id: $id, textbook: $textbookId, chapter: $chapterNumber, '
        'section: $sectionNumber, category: $categoryName, note: "$notePreview")';
  }
}