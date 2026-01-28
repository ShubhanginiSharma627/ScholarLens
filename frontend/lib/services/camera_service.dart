import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import '../models/processed_image.dart';
import 'image_processing_pipeline.dart';

/// Service for handling camera operations including capture, crop, and compress
abstract class CameraService {
  Future<File> captureImage();
  Future<File?> cropImage(File image, {String? title});
  Future<File> compressImage(File image, {int maxSizeKB = 1024});
  Future<ProcessedImage> captureAndProcess({String? cropTitle});
  Future<void> initialize();
  void dispose();
  bool get isInitialized;
  CameraController? get controller;
}

class CameraServiceImpl implements CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  CameraController? get controller => _controller;

  @override
  bool get isInitialized => _isInitialized && _controller?.value.isInitialized == true;

  @override
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw ScholarLensCameraException('No cameras available', 'No camera devices found on this device');
      }

      // Use the first available camera (usually back camera)
      final firstCamera = _cameras!.first;
      
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      throw ScholarLensCameraException('Camera initialization failed', e.toString());
    }
  }

  @override
  Future<File> captureImage() async {
    if (!isInitialized) {
      throw ScholarLensCameraException('Camera not initialized', 'Call initialize() first');
    }

    try {
      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      throw ScholarLensCameraException('Image capture failed', e.toString());
    }
  }

  @override
  Future<File?> cropImage(File image, {String? title}) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title ?? 'Crop Image',
            toolbarColor: const Color(0xFF2196F3),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: title ?? 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      throw ScholarLensCameraException('Image cropping failed', e.toString());
    }
  }

  @override
  Future<File> compressImage(File image, {int maxSizeKB = 1024}) async {
    try {
      final processedImage = await ImageProcessingPipeline.processImage(
        image,
        maxSizeKB: maxSizeKB,
      );
      return processedImage.file;
    } catch (e) {
      throw ScholarLensCameraException('Image compression failed', e.toString());
    }
  }

  @override
  Future<ProcessedImage> captureAndProcess({String? cropTitle}) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Capture image
      final capturedImage = await captureImage();
      final originalPath = capturedImage.path;
      
      // Crop image (optional - user can cancel)
      File? croppedImage = await cropImage(capturedImage, title: cropTitle);
      final imageToProcess = croppedImage ?? capturedImage;
      
      // Process image through pipeline
      final processedImage = await ImageProcessingPipeline.processImage(
        imageToProcess,
        originalPath: originalPath,
      );
      
      // Update metadata to reflect cropping
      if (croppedImage != null) {
        final updatedMetadata = processedImage.metadata.copyWith(wasCropped: true);
        final result = processedImage.copyWith(metadata: updatedMetadata);
        
        stopwatch.stop();
        debugPrint('Camera capture and processing completed in ${stopwatch.elapsedMilliseconds}ms');
        
        return result;
      }
      
      stopwatch.stop();
      debugPrint('Camera capture and processing completed in ${stopwatch.elapsedMilliseconds}ms');
      
      return processedImage;
    } catch (e) {
      stopwatch.stop();
      debugPrint('Camera capture and processing failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      
      if (e is ScholarLensCameraException) {
        rethrow;
      }
      throw ScholarLensCameraException('Image processing failed', e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

/// Custom exception for camera-related errors
class ScholarLensCameraException implements Exception {
  final String message;
  final String details;
  
  const ScholarLensCameraException(this.message, this.details);
  
  @override
  String toString() => 'ScholarLensCameraException: $message - $details';
}