/// Response model for file upload operations
class StorageUploadResponse {
  final String fileName;
  final String originalName;
  final int size;
  final String contentType;
  final String downloadUrl;
  final DateTime uploadedAt;
  final String? folder;
  final bool isPublic;

  const StorageUploadResponse({
    required this.fileName,
    required this.originalName,
    required this.size,
    required this.contentType,
    required this.downloadUrl,
    required this.uploadedAt,
    this.folder,
    required this.isPublic,
  });

  /// Creates a StorageUploadResponse from JSON
  factory StorageUploadResponse.fromJson(Map<String, dynamic> json) {
    return StorageUploadResponse(
      fileName: json['fileName'] as String,
      originalName: json['originalName'] as String,
      size: json['size'] as int,
      contentType: json['contentType'] as String,
      downloadUrl: json['downloadUrl'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      folder: json['folder'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  /// Converts StorageUploadResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'originalName': originalName,
      'size': size,
      'contentType': contentType,
      'downloadUrl': downloadUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'folder': folder,
      'isPublic': isPublic,
    };
  }

  /// Gets the file extension
  String get extension {
    final parts = originalName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Gets the file size in a human-readable format
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Checks if the file is an image
  bool get isImage {
    return contentType.startsWith('image/');
  }

  /// Checks if the file is a document
  bool get isDocument {
    return contentType.startsWith('application/') ||
        contentType.startsWith('text/') ||
        ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension);
  }

  /// Checks if the file is a video
  bool get isVideo {
    return contentType.startsWith('video/');
  }

  /// Checks if the file is an audio file
  bool get isAudio {
    return contentType.startsWith('audio/');
  }

  /// Creates a copy with updated fields
  StorageUploadResponse copyWith({
    String? fileName,
    String? originalName,
    int? size,
    String? contentType,
    String? downloadUrl,
    DateTime? uploadedAt,
    String? folder,
    bool? isPublic,
  }) {
    return StorageUploadResponse(
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      size: size ?? this.size,
      contentType: contentType ?? this.contentType,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      folder: folder ?? this.folder,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageUploadResponse &&
        other.fileName == fileName &&
        other.originalName == originalName &&
        other.size == size &&
        other.contentType == contentType &&
        other.downloadUrl == downloadUrl &&
        other.uploadedAt == uploadedAt &&
        other.folder == folder &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode {
    return Object.hash(
      fileName,
      originalName,
      size,
      contentType,
      downloadUrl,
      uploadedAt,
      folder,
      isPublic,
    );
  }

  @override
  String toString() {
    return 'StorageUploadResponse(fileName: $fileName, originalName: $originalName, size: $formattedSize)';
  }
}