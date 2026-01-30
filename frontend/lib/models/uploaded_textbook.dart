class UploadedTextbook {
  final String id;
  final String title;
  final String fileName;
  final String fileSize;
  final TextbookStatus status;
  final DateTime uploadedAt;
  final List<String> chapters;
  final int totalPages;
  final List<String> keyTopics;
  final String subject;
  const UploadedTextbook({
    required this.id,
    required this.title,
    required this.fileName,
    required this.fileSize,
    required this.status,
    required this.uploadedAt,
    required this.chapters,
    required this.totalPages,
    required this.keyTopics,
    required this.subject,
  });
  factory UploadedTextbook.fromJson(Map<String, dynamic> json) {
    return UploadedTextbook(
      id: json['id'] as String,
      title: json['title'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as String,
      status: TextbookStatus.values.firstWhere(
        (e) => e.toString() == 'TextbookStatus.${json['status']}',
        orElse: () => TextbookStatus.ready,
      ),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      chapters: List<String>.from(json['chapters'] as List),
      totalPages: json['totalPages'] as int,
      keyTopics: List<String>.from(json['keyTopics'] as List),
      subject: json['subject'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status.toString().split('.').last,
      'uploadedAt': uploadedAt.toIso8601String(),
      'chapters': chapters,
      'totalPages': totalPages,
      'keyTopics': keyTopics,
      'subject': subject,
    };
  }
  UploadedTextbook copyWith({
    String? id,
    String? title,
    String? fileName,
    String? fileSize,
    TextbookStatus? status,
    DateTime? uploadedAt,
    List<String>? chapters,
    int? totalPages,
    List<String>? keyTopics,
    String? subject,
  }) {
    return UploadedTextbook(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      chapters: chapters ?? this.chapters,
      totalPages: totalPages ?? this.totalPages,
      keyTopics: keyTopics ?? this.keyTopics,
      subject: subject ?? this.subject,
    );
  }
}
class TextbookProgress {
  final String textbookId;
  final int completedChapters;
  final int totalChapters;
  final double studyHours;
  final int currentChapter;
  final List<String> keyTopics;
  final List<ChapterProgress> chapterProgresses;
  final DateTime lastStudied;
  const TextbookProgress({
    required this.textbookId,
    required this.completedChapters,
    required this.totalChapters,
    required this.studyHours,
    required this.currentChapter,
    required this.keyTopics,
    required this.chapterProgresses,
    required this.lastStudied,
  });
  factory TextbookProgress.fromJson(Map<String, dynamic> json) {
    return TextbookProgress(
      textbookId: json['textbookId'] as String,
      completedChapters: json['completedChapters'] as int,
      totalChapters: json['totalChapters'] as int,
      studyHours: (json['studyHours'] as num).toDouble(),
      currentChapter: json['currentChapter'] as int,
      keyTopics: List<String>.from(json['keyTopics'] as List),
      chapterProgresses: (json['chapterProgresses'] as List)
          .map((e) => ChapterProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastStudied: DateTime.parse(json['lastStudied'] as String),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'textbookId': textbookId,
      'completedChapters': completedChapters,
      'totalChapters': totalChapters,
      'studyHours': studyHours,
      'currentChapter': currentChapter,
      'keyTopics': keyTopics,
      'chapterProgresses': chapterProgresses.map((e) => e.toJson()).toList(),
      'lastStudied': lastStudied.toIso8601String(),
    };
  }
  double get completionPercentage =>
      totalChapters > 0 ? (completedChapters / totalChapters) * 100 : 0;
  TextbookProgress copyWith({
    String? textbookId,
    int? completedChapters,
    int? totalChapters,
    double? studyHours,
    int? currentChapter,
    List<String>? keyTopics,
    List<ChapterProgress>? chapterProgresses,
    DateTime? lastStudied,
  }) {
    return TextbookProgress(
      textbookId: textbookId ?? this.textbookId,
      completedChapters: completedChapters ?? this.completedChapters,
      totalChapters: totalChapters ?? this.totalChapters,
      studyHours: studyHours ?? this.studyHours,
      currentChapter: currentChapter ?? this.currentChapter,
      keyTopics: keyTopics ?? this.keyTopics,
      chapterProgresses: chapterProgresses ?? this.chapterProgresses,
      lastStudied: lastStudied ?? this.lastStudied,
    );
  }
}
class ChapterProgress {
  final int chapterNumber;
  final String chapterTitle;
  final String pageRange;
  final int estimatedReadingTimeMinutes;
  final bool isCompleted;
  final double progressPercentage;
  final DateTime? completedAt;
  final DateTime? lastAccessed;
  const ChapterProgress({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.pageRange,
    required this.estimatedReadingTimeMinutes,
    required this.isCompleted,
    required this.progressPercentage,
    this.completedAt,
    this.lastAccessed,
  });
  factory ChapterProgress.fromJson(Map<String, dynamic> json) {
    return ChapterProgress(
      chapterNumber: json['chapterNumber'] as int,
      chapterTitle: json['chapterTitle'] as String,
      pageRange: json['pageRange'] as String,
      estimatedReadingTimeMinutes: json['estimatedReadingTimeMinutes'] as int,
      isCompleted: json['isCompleted'] as bool,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      lastAccessed: json['lastAccessed'] != null 
          ? DateTime.parse(json['lastAccessed'] as String) 
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'chapterNumber': chapterNumber,
      'chapterTitle': chapterTitle,
      'pageRange': pageRange,
      'estimatedReadingTimeMinutes': estimatedReadingTimeMinutes,
      'isCompleted': isCompleted,
      'progressPercentage': progressPercentage,
      'completedAt': completedAt?.toIso8601String(),
      'lastAccessed': lastAccessed?.toIso8601String(),
    };
  }
  ChapterProgress copyWith({
    int? chapterNumber,
    String? chapterTitle,
    String? pageRange,
    int? estimatedReadingTimeMinutes,
    bool? isCompleted,
    double? progressPercentage,
    DateTime? completedAt,
    DateTime? lastAccessed,
  }) {
    return ChapterProgress(
      chapterNumber: chapterNumber ?? this.chapterNumber,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      pageRange: pageRange ?? this.pageRange,
      estimatedReadingTimeMinutes: estimatedReadingTimeMinutes ?? this.estimatedReadingTimeMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      completedAt: completedAt ?? this.completedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}
enum TextbookStatus { uploading, processing, ready, error }