/// Represents a file stored in Google Cloud Storage
class StorageFile {
  final String name;
  final String bucket;
  final int size;
  final String contentType;
  final DateTime timeCreated;
  final DateTime updated;
  final String? folder;
  final Map<String, String> metadata;
  final bool isPublic;

  const StorageFile({
    required this.name,
    required this.bucket,
    required this.size,
    required this.contentType,
    required this.timeCreated,
    required this.updated,
    this.folder,
    required this.metadata,
    required this.isPublic,
  });

  /// Creates a StorageFile from JSON
  factory StorageFile.fromJson(Map<String, dynamic> json) {
    return StorageFile(
      name: json['name'] as String,
      bucket: json['bucket'] as String,
      size: json['size'] as int,
      contentType: json['contentType'] as String,
      timeCreated: DateTime.parse(json['timeCreated'] as String),
      updated: DateTime.parse(json['updated'] as String),
      folder: json['folder'] as String?,
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  /// Converts StorageFile to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bucket': bucket,
      'size': size,
      'contentType': contentType,
      'timeCreated': timeCreated.toIso8601String(),
      'updated': updated.toIso8601String(),
      'folder': folder,
      'metadata': metadata,
      'isPublic': isPublic,
    };
  }

  /// Gets the file extension
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Gets the display name (filename without folder path)
  String get displayName {
    final parts = name.split('/');
    return parts.last;
  }

  /// Gets the original filename from metadata
  String get originalName {
    return metadata['originalName'] ?? displayName;
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
  StorageFile copyWith({
    String? name,
    String? bucket,
    int? size,
    String? contentType,
    DateTime? timeCreated,
    DateTime? updated,
    String? folder,
    Map<String, String>? metadata,
    bool? isPublic,
  }) {
    return StorageFile(
      name: name ?? this.name,
      bucket: bucket ?? this.bucket,
      size: size ?? this.size,
      contentType: contentType ?? this.contentType,
      timeCreated: timeCreated ?? this.timeCreated,
      updated: updated ?? this.updated,
      folder: folder ?? this.folder,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageFile &&
        other.name == name &&
        other.bucket == bucket &&
        other.size == size &&
        other.contentType == contentType &&
        other.timeCreated == timeCreated &&
        other.updated == updated &&
        other.folder == folder &&
        other.isPublic == isPublic;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      bucket,
      size,
      contentType,
      timeCreated,
      updated,
      folder,
      isPublic,
    );
  }

  @override
  String toString() {
    return 'StorageFile(name: $name, size: $formattedSize, contentType: $contentType)';
  }
}