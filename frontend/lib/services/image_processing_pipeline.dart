import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/processed_image.dart';
class ImageProcessingPipeline {
  static const int _maxSizeKB = 1024; // 1MB limit
  static const int _minQuality = 10;
  static const int _maxQuality = 95;
  static const double _minScaleFactor = 0.1;
  static Future<ProcessedImage> processImage(
    File inputFile, {
    String? originalPath,
    int maxSizeKB = _maxSizeKB,
    bool maintainAspectRatio = true,
  }) async {
    try {
      if (!inputFile.existsSync()) {
        throw ImageProcessingException(
          'Input file does not exist',
          'The specified image file could not be found',
        );
      }
      final fileStat = await inputFile.stat();
      if (fileStat.size == 0) {
        throw ImageProcessingException(
          'Empty image file',
          'The image file is empty or corrupted',
        );
      }
      Uint8List? originalBytes;
      img.Image? originalImage;
      try {
        originalBytes = await inputFile.readAsBytes();
        originalImage = img.decodeImage(originalBytes);
      } catch (e) {
        throw ImageProcessingException(
          'Failed to read image',
          'Could not read or decode the image file: $e',
        );
      }
      if (originalImage == null) {
        throw ImageProcessingException(
          'Invalid image format',
          'The image format is not supported or the file is corrupted',
        );
      }
      final originalSizeKB = originalBytes.length ~/ 1024;
      final originalWidth = originalImage.width;
      final originalHeight = originalImage.height;
      var metadata = ImageProcessingMetadata(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        processedWidth: originalWidth,
        processedHeight: originalHeight,
        wasCropped: false,
        wasCompressed: false,
        compressionRatio: 1.0,
      );
      if (originalSizeKB <= maxSizeKB) {
        originalBytes = null;
        originalImage = null;
        return ProcessedImage(
          file: inputFile,
          sizeKB: originalSizeKB,
          processedAt: DateTime.now(),
          originalPath: originalPath,
          metadata: metadata,
        );
      }
      final processedResult = await _compressToSizeLimit(
        originalImage,
        maxSizeKB,
        maintainAspectRatio,
      );
      originalImage = null;
      originalBytes = null;
      final outputFile = await _saveProcessedImage(processedResult.bytes);
      final finalSizeKB = processedResult.bytes.length ~/ 1024;
      metadata = ImageProcessingMetadata(
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        processedWidth: processedResult.width,
        processedHeight: processedResult.height,
        wasCropped: false,
        wasCompressed: true,
        compressionRatio: finalSizeKB / originalSizeKB,
      );
      return ProcessedImage(
        file: outputFile,
        sizeKB: finalSizeKB,
        processedAt: DateTime.now(),
        originalPath: originalPath ?? inputFile.path,
        metadata: metadata,
      );
    } catch (e) {
      if (e is ImageProcessingException) {
        rethrow;
      }
      throw ImageProcessingException(
        'Image processing failed',
        e.toString(),
      );
    }
  }
  static Future<ProcessedImageResult> _compressToSizeLimit(
    img.Image originalImage,
    int maxSizeKB,
    bool maintainAspectRatio,
  ) async {
    final targetSizeBytes = maxSizeKB * 1024;
    final compressionResult = await _compressByQuality(
      originalImage,
      targetSizeBytes,
    );
    if (compressionResult.bytes.length <= targetSizeBytes) {
      return compressionResult;
    }
    return await _compressByResizing(
      originalImage,
      targetSizeBytes,
      maintainAspectRatio,
    );
  }
  static Future<ProcessedImageResult> _compressByQuality(
    img.Image image,
    int targetSizeBytes,
  ) async {
    int quality = _maxQuality;
    Uint8List? bestResult;
    while (quality >= _minQuality) {
      final compressed = img.encodeJpg(image, quality: quality);
      if (compressed.length <= targetSizeBytes) {
        bestResult = compressed;
        break;
      }
      quality -= 10;
    }
    return ProcessedImageResult(
      bytes: bestResult ?? img.encodeJpg(image, quality: _minQuality),
      width: image.width,
      height: image.height,
    );
  }
  static Future<ProcessedImageResult> _compressByResizing(
    img.Image originalImage,
    int targetSizeBytes,
    bool maintainAspectRatio,
  ) async {
    final originalBytes = img.encodeJpg(originalImage, quality: 75);
    double scaleFactor = (targetSizeBytes / originalBytes.length).clamp(_minScaleFactor, 1.0);
    img.Image? bestImage;
    Uint8List? bestResult;
    int attempts = 0;
    const maxAttempts = 10;
    while (attempts < maxAttempts && scaleFactor >= _minScaleFactor) {
      final newWidth = (originalImage.width * scaleFactor).round();
      final newHeight = maintainAspectRatio 
          ? (originalImage.height * scaleFactor).round()
          : (originalImage.height * scaleFactor).round();
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
      final compressed = img.encodeJpg(resizedImage, quality: 75);
      if (compressed.length <= targetSizeBytes) {
        bestImage = resizedImage;
        bestResult = compressed;
        break;
      }
      scaleFactor *= 0.9; // Reduce by 10%
      attempts++;
    }
    if (bestResult == null) {
      final minWidth = (originalImage.width * _minScaleFactor).round();
      final minHeight = (originalImage.height * _minScaleFactor).round();
      bestImage = img.copyResize(
        originalImage,
        width: minWidth,
        height: minHeight,
      );
      bestResult = img.encodeJpg(bestImage, quality: _minQuality);
    }
    return ProcessedImageResult(
      bytes: bestResult,
      width: bestImage?.width ?? originalImage.width,
      height: bestImage?.height ?? originalImage.height,
    );
  }
  static Future<File> _saveProcessedImage(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputFile = File('${tempDir.path}/$fileName');
    await outputFile.writeAsBytes(imageBytes);
    return outputFile;
  }
  static Future<ImageInfo?> getImageInfo(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        return null;
      }
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }
      return ImageInfo(
        width: image.width,
        height: image.height,
        sizeBytes: bytes.length,
        sizeKB: bytes.length ~/ 1024,
        format: _getImageFormat(imageFile.path),
      );
    } catch (e) {
      return null;
    }
  }
  static String _getImageFormat(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'JPEG';
      case 'png':
        return 'PNG';
      case 'gif':
        return 'GIF';
      case 'bmp':
        return 'BMP';
      case 'webp':
        return 'WebP';
      default:
        return 'Unknown';
    }
  }
  static Future<int> estimateCompressedSize(
    File imageFile,
    int quality,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return bytes.length;
      }
      final compressed = img.encodeJpg(image, quality: quality);
      return compressed.length;
    } catch (e) {
      return 0;
    }
  }
}
class ProcessedImageResult {
  final Uint8List bytes;
  final int width;
  final int height;
  const ProcessedImageResult({
    required this.bytes,
    required this.width,
    required this.height,
  });
}
class ImageInfo {
  final int width;
  final int height;
  final int sizeBytes;
  final int sizeKB;
  final String format;
  const ImageInfo({
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.sizeKB,
    required this.format,
  });
  double get aspectRatio => height > 0 ? width / height : 1.0;
  String get formattedSize {
    if (sizeKB < 1024) {
      return '${sizeKB}KB';
    } else {
      final sizeMB = sizeKB / 1024;
      return '${sizeMB.toStringAsFixed(1)}MB';
    }
  }
  bool get isUnderSizeLimit => sizeKB <= 1024;
  @override
  String toString() {
    return 'ImageInfo(${width}x$height, $formattedSize, $format)';
  }
}
class ImageProcessingException implements Exception {
  final String message;
  final String details;
  const ImageProcessingException(this.message, this.details);
  @override
  String toString() => 'ImageProcessingException: $message - $details';
}