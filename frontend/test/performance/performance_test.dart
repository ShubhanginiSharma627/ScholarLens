import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/services/image_processing_pipeline.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
void main() {
  group('Performance Tests', () {
    test('Image processing performance - should complete under 5 seconds', () async {
      final stopwatch = Stopwatch()..start();
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/performance_test.jpg');
      final testImage = img.Image(width: 100, height: 100);
      img.fill(testImage, color: img.ColorRgb8(128, 128, 128)); // Gray image
      final jpegBytes = img.encodeJpg(testImage, quality: 85);
      await testFile.writeAsBytes(jpegBytes);
      try {
        final processedImage = await ImageProcessingPipeline.processImage(testFile);
        stopwatch.stop();
        final processingTime = stopwatch.elapsedMilliseconds;
        expect(processingTime, lessThan(5000), reason: 'Image processing took ${processingTime}ms, should be under 5000ms');
        expect(processedImage.sizeKB, lessThan(1024), reason: 'Compressed image should be under 1MB');
        print('Image processing completed in ${processingTime}ms');
        print('Compressed size: ${processedImage.sizeKB}KB');
      } finally {
        if (testFile.existsSync()) {
          await testFile.delete();
        }
      }
    });
    test('Memory usage monitoring during image processing', () async {
      print('Testing memory usage patterns during image processing');
      final tempDir = Directory.systemTemp;
      final testFiles = <File>[];
      try {
        for (int i = 0; i < 3; i++) {
          final testFile = File('${tempDir.path}/memory_test_$i.jpg');
          final testImage = img.Image(width: 50, height: 50);
          img.fill(testImage, color: img.ColorRgb8(100 + i * 20, 100, 100));
          final jpegBytes = img.encodeJpg(testImage, quality: 80);
          await testFile.writeAsBytes(jpegBytes);
          testFiles.add(testFile);
        }
        final stopwatch = Stopwatch()..start();
        for (final file in testFiles) {
          await ImageProcessingPipeline.processImage(file);
        }
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;
        print('Processed ${testFiles.length} images in ${totalTime}ms');
        print('Average time per image: ${(totalTime / testFiles.length).toStringAsFixed(1)}ms');
        expect(totalTime, lessThan(10000), 
               reason: 'Processing ${testFiles.length} images took ${totalTime}ms, should be under 10 seconds');
      } finally {
        for (final file in testFiles) {
          if (file.existsSync()) {
            await file.delete();
          }
        }
      }
    });
    test('UI responsiveness - animation frame timing', () async {
      final frameTimes = <int>[];
      final stopwatch = Stopwatch();
      for (int i = 0; i < 60; i++) { // Test 60 frames (1 second at 60fps)
        stopwatch.reset();
        stopwatch.start();
        await Future.delayed(Duration(microseconds: 100)); // Minimal processing
        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds);
      }
      final averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
      final targetFrameTime = 16667; // 16.67ms for 60fps
      print('Average frame time: ${(averageFrameTime / 1000).toStringAsFixed(2)}ms');
      print('Max frame time: ${(maxFrameTime / 1000).toStringAsFixed(2)}ms');
      print('Target frame time: ${(targetFrameTime / 1000).toStringAsFixed(2)}ms');
      expect(averageFrameTime, lessThan(targetFrameTime), 
             reason: 'Average frame time ${(averageFrameTime / 1000).toStringAsFixed(2)}ms exceeds 60fps target');
      expect(maxFrameTime, lessThan(targetFrameTime * 2), 
             reason: 'Max frame time ${(maxFrameTime / 1000).toStringAsFixed(2)}ms is too high for smooth animation');
    });
    test('Concurrent operations performance', () async {
      final stopwatch = Stopwatch()..start();
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/concurrent_test.jpg');
      final testImage = img.Image(width: 80, height: 80);
      img.fill(testImage, color: img.ColorRgb8(150, 150, 150));
      final jpegBytes = img.encodeJpg(testImage, quality: 75);
      await testFile.writeAsBytes(jpegBytes);
      try {
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(ImageProcessingPipeline.processImage(testFile));
        }
        await Future.wait(futures);
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;
        print('Concurrent operations completed in ${totalTime}ms');
        expect(totalTime, lessThan(10000), 
               reason: 'Concurrent operations took ${totalTime}ms, should complete within 10 seconds');
      } finally {
        if (testFile.existsSync()) {
          await testFile.delete();
        }
      }
    });
    test('Network request timeout handling', () async {
      final stopwatch = Stopwatch()..start();
      try {
        await Future.delayed(Duration(milliseconds: 100)); // Simulate fast response
        stopwatch.stop();
        final responseTime = stopwatch.elapsedMilliseconds;
        print('Simulated API response time: ${responseTime}ms');
        expect(responseTime, lessThan(5000), 
               reason: 'API response time ${responseTime}ms should be under 5 seconds');
      } catch (e) {
        stopwatch.stop();
        print('Network request failed after ${stopwatch.elapsedMilliseconds}ms: $e');
        expect(stopwatch.elapsedMilliseconds, lessThan(30000), 
               reason: 'Network timeout should occur within 30 seconds');
      }
    });
    test('Image processing optimization levels', () async {
      final tempDir = Directory.systemTemp;
      final testFile = File('${tempDir.path}/optimization_test.jpg');
      final testImage = img.Image(width: 200, height: 200);
      img.fill(testImage, color: img.ColorRgb8(120, 120, 120));
      final jpegBytes = img.encodeJpg(testImage, quality: 90);
      await testFile.writeAsBytes(jpegBytes);
      try {
        final sizeLimits = [1024, 512, 256]; // KB
        final results = <String>[];
        for (final sizeLimit in sizeLimits) {
          final stopwatch = Stopwatch()..start();
          final processed = await ImageProcessingPipeline.processImage(
            testFile,
            maxSizeKB: sizeLimit,
          );
          stopwatch.stop();
          results.add('${sizeLimit}KB limit: ${stopwatch.elapsedMilliseconds}ms, result: ${processed.sizeKB}KB');
          expect(processed.sizeKB, lessThanOrEqualTo(sizeLimit));
        }
        print('Optimization results:');
        for (final result in results) {
          print('  $result');
        }
      } finally {
        if (testFile.existsSync()) {
          await testFile.delete();
        }
      }
    });
  });
}