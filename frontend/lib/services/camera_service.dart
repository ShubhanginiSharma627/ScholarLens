import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import '../models/processed_image.dart';
import 'image_processing_pipeline.dart';
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
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw ScholarLensCameraException('No cameras available', 'No camera devices found on this device');
      }
      final firstCamera = _cameras!.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // Ensure JPEG format
      );
      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      _controller = null;
      if (e.toString().contains('permission')) {
        throw ScholarLensCameraException('Camera permission denied', 'Please grant camera permission in device settings');
      } else if (e.toString().contains('camera')) {
        throw ScholarLensCameraException('Camera unavailable', 'Camera is being used by another app or is not available');
      } else {
        throw ScholarLensCameraException('Camera initialization failed', e.toString());
      }
    }
  }
  @override
  Future<File> captureImage() async {
    if (!isInitialized) {
      throw ScholarLensCameraException('Camera not initialized', 'Call initialize() first');
    }
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        throw ScholarLensCameraException('Camera not ready', 'Camera controller is not properly initialized');
      }
      if (_controller!.value.isTakingPicture) {
        throw ScholarLensCameraException('Camera busy', 'Camera is already taking a picture');
      }
      final XFile image = await _controller!.takePicture();
      final file = File(image.path);
      if (!file.existsSync()) {
        throw ScholarLensCameraException('Image capture failed', 'Image file was not created');
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw ScholarLensCameraException('Image capture failed', 'Image file is empty');
      }
      return file;
    } catch (e) {
      if (e is ScholarLensCameraException) {
        rethrow;
      }
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
      final capturedImage = await captureImage();
      final originalPath = capturedImage.path;
      File? croppedImage = await cropImage(capturedImage, title: cropTitle);
      final imageToProcess = croppedImage ?? capturedImage;
      final processedImage = await ImageProcessingPipeline.processImage(
        imageToProcess,
        originalPath: originalPath,
      );
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
class ScholarLensCameraException implements Exception {
  final String message;
  final String details;
  const ScholarLensCameraException(this.message, this.details);
  @override
  String toString() => 'ScholarLensCameraException: $message - $details';
}