import 'dart:ui';
import 'dart:math';

/// Enum representing different highlight color types with predefined colors
enum HighlightColorType {
  yellow(Color(0xFFFFEB3B), 'Yellow'),
  green(Color(0xFF4CAF50), 'Green'),
  blue(Color(0xFF2196F3), 'Blue'),
  orange(Color(0xFFFF9800), 'Orange'),
  pink(Color(0xFFE91E63), 'Pink'),
  purple(Color(0xFF9C27B0), 'Purple');

  const HighlightColorType(this.color, this.displayName);

  final Color color;
  final String displayName;

  /// Returns the HighlightColorType for a given color, defaults to yellow if not found
  static HighlightColorType fromColor(Color color) {
    for (final type in HighlightColorType.values) {
      if (type.color.toARGB32 == color.toARGB32) {
        return type;
      }
    }
    return HighlightColorType.yellow; // Default fallback
  }

  /// Returns all available colors as a list
  static List<Color> get allColors {
    return HighlightColorType.values.map((type) => type.color).toList();
  }

  /// Returns a map of display names to colors
  static Map<String, Color> get colorMap {
    return Map.fromEntries(
      HighlightColorType.values.map((type) => MapEntry(type.displayName, type.color)),
    );
  }
}

/// Represents a highlighted text passage with position, timestamp, and color information
class TextHighlight {
  final String id;
  final String textbookId;
  final int chapterNumber;
  final int sectionNumber;
  final String highlightedText;
  final int startOffset;
  final int endOffset;
  final DateTime createdAt;
  final Color highlightColor;

  const TextHighlight({
    required this.id,
    required this.textbookId,
    required this.chapterNumber,
    required this.sectionNumber,
    required this.highlightedText,
    required this.startOffset,
    required this.endOffset,
    required this.createdAt,
    required this.highlightColor,
  });

  /// Factory constructor to create a new highlight with generated ID and current timestamp
  factory TextHighlight.create({
    required String textbookId,
    required int chapterNumber,
    required int sectionNumber,
    required String highlightedText,
    required int startOffset,
    required int endOffset,
    Color highlightColor = const Color(0xFFFFEB3B), // Default yellow
  }) {
    return TextHighlight(
      id: _generateId(),
      textbookId: textbookId,
      chapterNumber: chapterNumber,
      sectionNumber: sectionNumber,
      highlightedText: highlightedText,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: DateTime.now(),
      highlightColor: highlightColor,
    );
  }

  /// Factory constructor to create a highlight with a specific color type
  factory TextHighlight.withColorType({
    required String textbookId,
    required int chapterNumber,
    required int sectionNumber,
    required String highlightedText,
    required int startOffset,
    required int endOffset,
    required HighlightColorType colorType,
  }) {
    return TextHighlight.create(
      textbookId: textbookId,
      chapterNumber: chapterNumber,
      sectionNumber: sectionNumber,
      highlightedText: highlightedText,
      startOffset: startOffset,
      endOffset: endOffset,
      highlightColor: colorType.color,
    );
  }

  /// Creates a TextHighlight from JSON data
  factory TextHighlight.fromJson(Map<String, dynamic> json) {
    return TextHighlight(
      id: json['id'] as String,
      textbookId: json['textbook_id'] as String,
      chapterNumber: json['chapter_number'] as int,
      sectionNumber: json['section_number'] as int,
      highlightedText: json['highlighted_text'] as String,
      startOffset: json['start_offset'] as int,
      endOffset: json['end_offset'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      highlightColor: Color(json['highlight_color'] as int),
    );
  }

  /// Converts the TextHighlight to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textbook_id': textbookId,
      'chapter_number': chapterNumber,
      'section_number': sectionNumber,
      'highlighted_text': highlightedText,
      'start_offset': startOffset,
      'end_offset': endOffset,
      'created_at': createdAt.toIso8601String(),
      'highlight_color': highlightColor.value,
    };
  }

  /// Creates a copy of this TextHighlight with optionally updated fields
  TextHighlight copyWith({
    String? id,
    String? textbookId,
    int? chapterNumber,
    int? sectionNumber,
    String? highlightedText,
    int? startOffset,
    int? endOffset,
    DateTime? createdAt,
    Color? highlightColor,
  }) {
    return TextHighlight(
      id: id ?? this.id,
      textbookId: textbookId ?? this.textbookId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      sectionNumber: sectionNumber ?? this.sectionNumber,
      highlightedText: highlightedText ?? this.highlightedText,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      createdAt: createdAt ?? this.createdAt,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }

  /// Returns the length of the highlighted text
  int get textLength => highlightedText.length;

  /// Returns the range of the highlight (end - start)
  int get highlightRange => endOffset - startOffset;

  /// Returns the color type for this highlight
  HighlightColorType get colorType => HighlightColorType.fromColor(highlightColor);

  /// Checks if the given offset is within this highlight's range
  bool containsOffset(int offset) {
    return offset >= startOffset && offset < endOffset;
  }

  /// Returns a preview of the highlighted text, truncated if necessary
  String getPreview({int maxLength = 50}) {
    if (highlightedText.length <= maxLength) {
      return highlightedText;
    }
    return '${highlightedText.substring(0, maxLength - 3)}...';
  }

  /// Checks if this highlight overlaps with another highlight
  bool overlapsWith(TextHighlight other) {
    // Must be in the same textbook, chapter, and section
    if (textbookId != other.textbookId ||
        chapterNumber != other.chapterNumber ||
        sectionNumber != other.sectionNumber) {
      return false;
    }

    // Check for range overlap
    return startOffset < other.endOffset && endOffset > other.startOffset;
  }

  /// Generates a unique ID for highlights
  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(10000);
    return 'highlight_${timestamp}_$randomSuffix';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextHighlight &&
        other.id == id &&
        other.textbookId == textbookId &&
        other.chapterNumber == chapterNumber &&
        other.sectionNumber == sectionNumber &&
        other.highlightedText == highlightedText &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.createdAt == createdAt &&
        other.highlightColor == highlightColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      textbookId,
      chapterNumber,
      sectionNumber,
      highlightedText,
      startOffset,
      endOffset,
      createdAt,
      highlightColor,
    );
  }

  @override
  String toString() {
    final colorName = colorType.displayName;
    return 'TextHighlight(id: $id, textbook: $textbookId, chapter: $chapterNumber, '
        'section: $sectionNumber, range: $startOffset-$endOffset, color: $colorName)';
  }
}