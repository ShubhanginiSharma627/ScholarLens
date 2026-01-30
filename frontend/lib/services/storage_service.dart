import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';
class StorageService {
  final ApiService _apiService = ApiService();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  Future<StorageUploadResponse> uploadFile({
    required File file,
    String? folder,
    bool makePublic = false,
    Function(double)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw StorageException('File does not exist');
      }
      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB limit
        throw StorageException('File size exceeds 100MB limit');
      }
      if (onProgress != null) {
        onProgress(0.0);
      }
      final response = await _apiService.uploadFile(
        file: file,
        folder: folder,
        makePublic: makePublic,
      );
      if (onProgress != null) {
        onProgress(1.0);
      }
      return response;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Upload failed: $e');
    }
  }
  Future<String> getDownloadUrl({
    required String fileName,
    DateTime? expires,
    bool public = false,
  }) async {
    try {
      return await _apiService.getFileDownloadUrl(
        fileName: fileName,
        expires: expires,
        public: public,
      );
    } catch (e) {
      throw StorageException('Failed to get download URL: $e');
    }
  }
  Future<void> deleteFile({required String fileName}) async {
    try {
      await _apiService.deleteFile(fileName: fileName);
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }
  Future<List<StorageFile>> listFiles({
    String? folder,
    int maxResults = 100,
  }) async {
    try {
      return await _apiService.listFiles(
        folder: folder,
        maxResults: maxResults,
      );
    } catch (e) {
      throw StorageException('Failed to list files: $e');
    }
  }
  Future<Map<String, dynamic>> getStorageStatus() async {
    try {
      return await _apiService.getStorageStatus();
    } catch (e) {
      throw StorageException('Failed to get storage status: $e');
    }
  }
  Future<Map<String, dynamic>> uploadAndScanSyllabus({
    required File file,
    String? prompt,
  }) async {
    try {
      final fileName = file.path.toLowerCase();
      if (!fileName.endsWith('.pdf')) {
        throw StorageException('Only PDF files are supported for syllabus scanning');
      }
      return await _apiService.scanSyllabus(
        file: file,
        prompt: prompt,
      );
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Syllabus scan failed: $e');
    }
  }
  Future<List<StorageUploadResponse>> uploadMultipleFiles({
    required List<File> files,
    String? folder,
    bool makePublic = false,
    Function(double)? onProgress,
    Function(StorageUploadResponse)? onFileComplete,
  }) async {
    final results = <StorageUploadResponse>[];
    final errors = <String>[];
    for (int i = 0; i < files.length; i++) {
      try {
        final response = await uploadFile(
          file: files[i],
          folder: folder,
          makePublic: makePublic,
        );
        results.add(response);
        onFileComplete?.call(response);
        onProgress?.call((i + 1) / files.length);
      } catch (e) {
        errors.add('${files[i].path}: $e');
      }
    }
    if (errors.isNotEmpty && results.isEmpty) {
      throw StorageException('All uploads failed: ${errors.join(', ')}');
    } else if (errors.isNotEmpty) {
      debugPrint('Some uploads failed: ${errors.join(', ')}');
    }
    return results;
  }
  FileCategory getFileCategory(StorageFile file) {
    if (file.isImage) return FileCategory.image;
    if (file.isVideo) return FileCategory.video;
    if (file.isAudio) return FileCategory.audio;
    if (file.isDocument) return FileCategory.document;
    return FileCategory.other;
  }
  bool isSupportedFileType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const supportedExtensions = {
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg',
      'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt',
      'mp3', 'wav', 'aac', 'ogg', 'm4a',
      'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm',
      'zip', 'rar', '7z', 'tar', 'gz',
    };
    return supportedExtensions.contains(extension);
  }
  int get maxFileSize => 100 * 1024 * 1024; // 100MB
  String get supportedExtensions => 
      'PDF, DOC, DOCX, TXT, JPG, PNG, MP3, MP4, ZIP and more';
}
enum FileCategory {
  image,
  document,
  video,
  audio,
  other,
}
class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}