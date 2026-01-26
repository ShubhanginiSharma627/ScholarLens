import 'dart:io';

/// Represents an image that has been processed (captured, cropped, compressed)
class ProcessedImage {
  final File file;
  final int sizeKB;
  final DateTime processedAt;
  final String? originalPath;
  final ImageProcessingMetadata metadata;

  const ProcessedImage({
    required this.file,
    required this.sizeKB,
    required this.processedAt,
    this.originalPath,
    required this.metadata,
  });

  /// Creates a ProcessedImage from JSON
  factory ProcessedImage.fromJson(Map<String, dynamic> json) {
    return ProcessedImage(
      file: File(json['file_path'] as String),
      sizeKB: json['size_kb'] as int,
      processedAt: DateTime.parse(json['processed_at'] as String),
      originalPath: json['original_path'] as String?,
      metadata: ImageProcessingMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  /// Converts ProcessedImage to JSON
  Map<String, dynamic> toJson() {
    return {
      'file_path': file.path,
      'size_kb': sizeKB,
      'processed_at': processedAt.toIso8601String(),
      'original_path': originalPath,
      'metadata': metadata.toJson(),
    };
  }

  /// Creates a ProcessedImage from a file
  factory ProcessedImage.fromFile(
    File file, {
    String? originalPath,
    ImageProcessingMetadata? metadata,
  }) {
    final sizeBytes = file.lengthSync();
    return ProcessedImage(
      file: file,
      sizeKB: (sizeBytes / 1024).round(),
      processedAt: DateTime.now(),
      originalPath: originalPath,
      metadata: metadata ?? ImageProcessingMetadata.empty(),
    );
  }

  /// Gets the file size in bytes
  int get sizeBytes => sizeKB * 1024;

  /// Gets formatted file size string
  String get formattedSize {
    if (sizeKB < 1024) {
      return '${sizeKB}KB';
    } else {
      final sizeMB = sizeKB / 1024;
      return '${sizeMB.toStringAsFixed(1)}MB';
    }
  }

  /// Checks if the image is under the size limit (1MB)
  bool get isUnderSizeLimit => sizeKB <= 1024;

  /// Gets the file extension
  String get fileExtension {
    final path = file.path;
    final lastDot = path.lastIndexOf('.');
    return lastDot != -1 ? path.substring(lastDot + 1).toLowerCase() : '';
  }

  /// Checks if the file exists
  bool get exists => file.existsSync();

  /// Creates a copy with updated fields
  ProcessedImage copyWith({
    File? file,
    int? sizeKB,
    DateTime? processedAt,
    String? originalPath,
    ImageProcessingMetadata? metadata,
  }) {
    return ProcessedImage(
      file: file ?? this.file,
      sizeKB: sizeKB ?? this.sizeKB,
      processedAt: processedAt ?? this.processedAt,
      originalPath: originalPath ?? this.originalPath,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessedImage &&
        other.file.path == file.path &&
        other.sizeKB == sizeKB &&
        other.processedAt == processedAt &&
        other.originalPath == originalPath &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return Object.hash(
      file.path,
      sizeKB,
      processedAt,
      originalPath,
      metadata,
    );
  }

  @override
  String toString() {
    return 'ProcessedImage(path: ${file.path}, size: $formattedSize, processed: $processedAt)';
  }
}

/// Metadata about image processing operations
class ImageProcessingMetadata {
  final int originalWidth;
  final int originalHeight;
  final int processedWidth;
  final int processedHeight;
  final bool wasCropped;
  final bool wasCompressed;
  final double compressionRatio;

  const ImageProcessingMetadata({
    required this.originalWidth,
    required this.originalHeight,
    required this.processedWidth,
    required this.processedHeight,
    required this.wasCropped,
    required this.wasCompressed,
    required this.compressionRatio,
  });

  /// Creates empty metadata
  factory ImageProcessingMetadata.empty() {
    return const ImageProcessingMetadata(
      originalWidth: 0,
      originalHeight: 0,
      processedWidth: 0,
      processedHeight: 0,
      wasCropped: false,
      wasCompressed: false,
      compressionRatio: 1.0,
    );
  }

  /// Creates metadata from JSON
  factory ImageProcessingMetadata.fromJson(Map<String, dynamic> json) {
    return ImageProcessingMetadata(
      originalWidth: json['original_width'] as int,
      originalHeight: json['original_height'] as int,
      processedWidth: json['processed_width'] as int,
      processedHeight: json['processed_height'] as int,
      wasCropped: json['was_cropped'] as bool,
      wasCompressed: json['was_compressed'] as bool,
      compressionRatio: (json['compression_ratio'] as num).toDouble(),
    );
  }

  /// Converts metadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'original_width': originalWidth,
      'original_height': originalHeight,
      'processed_width': processedWidth,
      'processed_height': processedHeight,
      'was_cropped': wasCropped,
      'was_compressed': wasCompressed,
      'compression_ratio': compressionRatio,
    };
  }

  /// Creates a copy with updated fields
  ImageProcessingMetadata copyWith({
    int? originalWidth,
    int? originalHeight,
    int? processedWidth,
    int? processedHeight,
    bool? wasCropped,
    bool? wasCompressed,
    double? compressionRatio,
  }) {
    return ImageProcessingMetadata(
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      processedWidth: processedWidth ?? this.processedWidth,
      processedHeight: processedHeight ?? this.processedHeight,
      wasCropped: wasCropped ?? this.wasCropped,
      wasCompressed: wasCompressed ?? this.wasCompressed,
      compressionRatio: compressionRatio ?? this.compressionRatio,
    );
  }

  /// Gets the original aspect ratio
  double get originalAspectRatio => originalHeight > 0 ? originalWidth / originalHeight : 1.0;

  /// Gets the processed aspect ratio
  double get processedAspectRatio => processedHeight > 0 ? processedWidth / processedHeight : 1.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageProcessingMetadata &&
        other.originalWidth == originalWidth &&
        other.originalHeight == originalHeight &&
        other.processedWidth == processedWidth &&
        other.processedHeight == processedHeight &&
        other.wasCropped == wasCropped &&
        other.wasCompressed == wasCompressed &&
        other.compressionRatio == compressionRatio;
  }

  @override
  int get hashCode {
    return Object.hash(
      originalWidth,
      originalHeight,
      processedWidth,
      processedHeight,
      wasCropped,
      wasCompressed,
      compressionRatio,
    );
  }

  @override
  String toString() {
    return 'ImageProcessingMetadata(${originalWidth}x$originalHeight -> ${processedWidth}x$processedHeight, cropped: $wasCropped, compressed: $wasCompressed)';
  }
}