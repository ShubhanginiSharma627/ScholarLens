import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/image_processing_pipeline.dart';

void main() {
  group('ImageProcessingPipeline', () {
    test('ImageProcessingException should contain message and details', () {
      const exception = ImageProcessingException('Test message', 'Test details');
      
      expect(exception.message, equals('Test message'));
      expect(exception.details, equals('Test details'));
      expect(exception.toString(), contains('Test message'));
      expect(exception.toString(), contains('Test details'));
    });

    test('ImageInfo should calculate aspect ratio correctly', () {
      const imageInfo = ImageInfo(
        width: 1920,
        height: 1080,
        sizeBytes: 1024000,
        sizeKB: 1000,
        format: 'JPEG',
      );
      
      expect(imageInfo.aspectRatio, closeTo(1.777, 0.001));
      expect(imageInfo.formattedSize, equals('1000KB'));
      expect(imageInfo.isUnderSizeLimit, isTrue); // 1000KB is under 1024KB limit
    });

    test('ImageInfo should format size correctly for MB', () {
      const imageInfo = ImageInfo(
        width: 1920,
        height: 1080,
        sizeBytes: 2048000,
        sizeKB: 2000,
        format: 'JPEG',
      );
      
      expect(imageInfo.formattedSize, equals('2.0MB'));
      expect(imageInfo.isUnderSizeLimit, isFalse); // 2000KB is over 1024KB limit
    });

    test('ImageInfo should identify images under size limit', () {
      const imageInfo = ImageInfo(
        width: 800,
        height: 600,
        sizeBytes: 512000,
        sizeKB: 500,
        format: 'JPEG',
      );
      
      expect(imageInfo.isUnderSizeLimit, isTrue);
    });

    test('ProcessedImageResult should store image data correctly', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      const width = 100;
      const height = 200;
      
      final result = ProcessedImageResult(
        bytes: bytes,
        width: width,
        height: height,
      );
      
      expect(result.bytes, equals(bytes));
      expect(result.width, equals(width));
      expect(result.height, equals(height));
    });
  });
}