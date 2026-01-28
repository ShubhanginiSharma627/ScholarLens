import 'dart:convert';
import 'package:scholar_lens/models/chapter_section.dart';
import 'package:scholar_lens/models/text_highlight.dart';
import 'package:scholar_lens/models/section_bookmark.dart';

/// Manages the overall state of a chapter reading session
class ChapterReadingState {
  final String textbookId;
  final int chapterNumber;
  final int currentSectionIndex;
  final List<ChapterSection> sections;
  final List<TextHighlight> highlights;
  final List<SectionBookmark> bookmarks;
  final bool isHighlightMode;
  final double readingProgress;
  final Duration readingTime;
  final List<String> keyPoints;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  const ChapterReadingState({
    required this.textbookId,
    required this.chapterNumber,
    required this.currentSectionIndex,
    required this.sections,
    required this.highlights,
    required this.bookmarks,
    required this.isHighlightMode,
    required this.readingProgress,
    required this.readingTime,
    required this.keyPoints,
    required this.lastUpdated,
    this.metadata = const {},
  });

  /// Factory constructor to create initial state for a chapter
  factory ChapterReadingState.initial({
    required String textbookId,
    required int chapterNumber,
    required List<ChapterSection> sections,
    List<String> keyPoints = const [],
  }) {
    return ChapterReadingState(
      textbookId: textbookId,
      chapterNumber: chapterNumber,
      currentSectionIndex: 0,
      sections: sections,
      highlights: [],
      bookmarks: [],
      isHighlightMode: false,
      readingProgress: 0.0,
      readingTime: Duration.zero,
      keyPoints: keyPoints,
      lastUpdated: DateTime.now(),
    );
  }
  /// Creates a ChapterReadingState from JSON data
  factory ChapterReadingState.fromJson(Map<String, dynamic> json) {
    return ChapterReadingState(
      textbookId: json['textbook_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      currentSectionIndex: json['current_section_index'] as int,
      sections: (json['sections'] as List)
          .map((section) => ChapterSection.fromJson(section))
          .toList(),
      highlights: (json['highlights'] as List)
          .map((highlight) => TextHighlight.fromJson(highlight))
          .toList(),
      bookmarks: (json['bookmarks'] as List)
          .map((bookmark) => SectionBookmark.fromJson(bookmark))
          .toList(),
      isHighlightMode: json['is_highlight_mode'] as bool,
      readingProgress: (json['reading_progress'] as num).toDouble(),
      readingTime: Duration(milliseconds: json['reading_time_ms'] as int),
      keyPoints: List<String>.from(json['key_points'] as List),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Converts the ChapterReadingState to JSON format
  Map<String, dynamic> toJson() {
    return {
      'textbook_id': textbookId,
      'chapter_number': chapterNumber,
      'current_section_index': currentSectionIndex,
      'sections': sections.map((section) => section.toJson()).toList(),
      'highlights': highlights.map((highlight) => highlight.toJson()).toList(),
      'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
      'is_highlight_mode': isHighlightMode,
      'reading_progress': readingProgress,
      'reading_time_ms': readingTime.inMilliseconds,
      'key_points': keyPoints,
      'last_updated': lastUpdated.toIso8601String(),
      'metadata': metadata,
    };
  }
  /// Creates a copy of this state with optionally updated fields
  ChapterReadingState copyWith({
    String? textbookId,
    int? chapterNumber,
    int? currentSectionIndex,
    List<ChapterSection>? sections,
    List<TextHighlight>? highlights,
    List<SectionBookmark>? bookmarks,
    bool? isHighlightMode,
    double? readingProgress,
    Duration? readingTime,
    List<String>? keyPoints,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return ChapterReadingState(
      textbookId: textbookId ?? this.textbookId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      sections: sections ?? this.sections,
      highlights: highlights ?? this.highlights,
      bookmarks: bookmarks ?? this.bookmarks,
      isHighlightMode: isHighlightMode ?? this.isHighlightMode,
      readingProgress: readingProgress ?? this.readingProgress,
      readingTime: readingTime ?? this.readingTime,
      keyPoints: keyPoints ?? this.keyPoints,
      lastUpdated: lastUpdated ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Updates the current section and recalculates progress
  ChapterReadingState updateCurrentSection(int sectionIndex) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) {
      throw ArgumentError('Section index out of range: $sectionIndex');
    }
    
    final newProgress = _calculateProgress();
    return copyWith(
      currentSectionIndex: sectionIndex,
      readingProgress: newProgress,
    );
  }
  /// Toggles highlight mode
  ChapterReadingState toggleHighlightMode() {
    return copyWith(isHighlightMode: !isHighlightMode);
  }

  /// Adds a new highlight to the state
  ChapterReadingState addHighlight(TextHighlight highlight) {
    final updatedHighlights = List<TextHighlight>.from(highlights)..add(highlight);
    return copyWith(highlights: updatedHighlights);
  }

  /// Removes a highlight from the state
  ChapterReadingState removeHighlight(String highlightId) {
    final updatedHighlights = highlights.where((h) => h.id != highlightId).toList();
    return copyWith(highlights: updatedHighlights);
  }

  /// Updates an existing highlight
  ChapterReadingState updateHighlight(TextHighlight updatedHighlight) {
    final updatedHighlights = highlights.map((h) {
      return h.id == updatedHighlight.id ? updatedHighlight : h;
    }).toList();
    return copyWith(highlights: updatedHighlights);
  }

  /// Adds a new bookmark to the state
  ChapterReadingState addBookmark(SectionBookmark bookmark) {
    final updatedBookmarks = List<SectionBookmark>.from(bookmarks)..add(bookmark);
    return copyWith(bookmarks: updatedBookmarks);
  }

  /// Removes a bookmark from the state
  ChapterReadingState removeBookmark(String bookmarkId) {
    final updatedBookmarks = bookmarks.where((b) => b.id != bookmarkId).toList();
    return copyWith(bookmarks: updatedBookmarks);
  }
  /// Updates an existing bookmark
  ChapterReadingState updateBookmark(SectionBookmark updatedBookmark) {
    final updatedBookmarks = bookmarks.map((b) {
      return b.id == updatedBookmark.id ? updatedBookmark : b;
    }).toList();
    return copyWith(bookmarks: updatedBookmarks);
  }

  /// Marks a section as completed
  ChapterReadingState markSectionCompleted(int sectionIndex) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) {
      throw ArgumentError('Section index out of range: $sectionIndex');
    }

    final updatedSections = List<ChapterSection>.from(sections);
    updatedSections[sectionIndex] = updatedSections[sectionIndex].copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    final newProgress = _calculateProgressFromSections(updatedSections);
    return copyWith(
      sections: updatedSections,
      readingProgress: newProgress,
    );
  }

  /// Updates reading time
  ChapterReadingState updateReadingTime(Duration additionalTime) {
    return copyWith(readingTime: readingTime + additionalTime);
  }

  /// Updates metadata
  ChapterReadingState updateMetadata(String key, dynamic value) {
    final updatedMetadata = Map<String, dynamic>.from(metadata);
    updatedMetadata[key] = value;
    return copyWith(metadata: updatedMetadata);
  }
  /// Calculates reading progress based on completed sections
  double _calculateProgress() {
    return _calculateProgressFromSections(sections);
  }

  double _calculateProgressFromSections(List<ChapterSection> sectionList) {
    if (sectionList.isEmpty) return 0.0;
    
    final completedSections = sectionList.where((s) => s.isCompleted).length;
    return completedSections / sectionList.length;
  }

  // Getters for convenience
  
  /// Returns the current section
  ChapterSection? get currentSection {
    if (currentSectionIndex >= 0 && currentSectionIndex < sections.length) {
      return sections[currentSectionIndex];
    }
    return null;
  }

  /// Returns the total number of sections
  int get totalSections => sections.length;

  /// Returns the number of completed sections
  int get completedSectionsCount => sections.where((s) => s.isCompleted).length;

  /// Returns true if the chapter is completed
  bool get isChapterCompleted => readingProgress >= 1.0;

  /// Returns true if there is a next section
  bool get hasNextSection => currentSectionIndex < sections.length - 1;

  /// Returns true if there is a previous section
  bool get hasPreviousSection => currentSectionIndex > 0;
  /// Returns highlights for the current section
  List<TextHighlight> get currentSectionHighlights {
    if (currentSection == null) return [];
    return highlights.where((h) => 
      h.chapterNumber == chapterNumber && 
      h.sectionNumber == currentSection!.sectionNumber
    ).toList();
  }

  /// Returns bookmarks for the current section
  List<SectionBookmark> get currentSectionBookmarks {
    if (currentSection == null) return [];
    return bookmarks.where((b) => 
      b.chapterNumber == chapterNumber && 
      b.sectionNumber == currentSection!.sectionNumber
    ).toList();
  }

  /// Returns the reading progress as a percentage (0-100)
  double get progressPercentage => readingProgress * 100;

  /// Returns a formatted reading time string
  String get formattedReadingTime {
    final hours = readingTime.inHours;
    final minutes = readingTime.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Validates the state for consistency
  bool isValid() {
    return textbookId.isNotEmpty &&
           chapterNumber > 0 &&
           currentSectionIndex >= 0 &&
           currentSectionIndex < sections.length &&
           readingProgress >= 0.0 &&
           readingProgress <= 1.0 &&
           !readingTime.isNegative;
  }
  /// Serializes the state to a JSON string for persistence
  String serialize() {
    return jsonEncode(toJson());
  }

  /// Deserializes a JSON string to create a ChapterReadingState
  static ChapterReadingState deserialize(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ChapterReadingState.fromJson(json);
  }

  /// Creates a state restoration key for this chapter
  String get restorationKey => 'chapter_reading_${textbookId}_$chapterNumber';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChapterReadingState &&
        other.textbookId == textbookId &&
        other.chapterNumber == chapterNumber &&
        other.currentSectionIndex == currentSectionIndex &&
        other.isHighlightMode == isHighlightMode &&
        other.readingProgress == readingProgress &&
        other.readingTime == readingTime &&
        _listEquals(other.sections, sections) &&
        _listEquals(other.highlights, highlights) &&
        _listEquals(other.bookmarks, bookmarks) &&
        _listEquals(other.keyPoints, keyPoints);
  }

  @override
  int get hashCode {
    return Object.hash(
      textbookId,
      chapterNumber,
      currentSectionIndex,
      isHighlightMode,
      readingProgress,
      readingTime,
      Object.hashAll(sections),
      Object.hashAll(highlights),
      Object.hashAll(bookmarks),
      Object.hashAll(keyPoints),
    );
  }
  @override
  String toString() {
    return 'ChapterReadingState('
        'textbook: $textbookId, '
        'chapter: $chapterNumber, '
        'section: $currentSectionIndex/${sections.length}, '
        'progress: ${progressPercentage.toStringAsFixed(1)}%, '
        'highlights: ${highlights.length}, '
        'bookmarks: ${bookmarks.length}, '
        'readingTime: $formattedReadingTime'
        ')';
  }

  /// Helper method to compare lists for equality
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}