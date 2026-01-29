import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_service.dart';

/// Service for handling file storage operations using Google Cloud Storage
class StorageService {
  final ApiService _apiService = ApiService();
  
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Upload a file to Google Cloud Storage
  /// 
  /// [file] - The file to upload
  /// [folder] - Optional folder to organize files (e.g., 'documents', 'images')
  /// [makePublic] - Whether to make the file publicly accessible
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  /// 
  /// Returns [StorageUploadResponse] with file details and download URL
  Future<StorageUploadResponse> uploadFile({
    required File file,
    String? folder,
    bool makePublic = false,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate file
      if (!await file.exists()) {
        throw StorageException('File does not exist');
      }

      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) { // 100MB limit
        throw StorageException('File size exceeds 100MB limit');
      }

      // TODO: Implement progress tracking if needed
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

  /// Get a download URL for a file
  /// 
  /// [fileName] - The full file name/path in storage
  /// [expires] - Optional expiration time for the URL
  /// [public] - Whether to get a public URL (no authentication required)
  /// 
  /// Returns the download URL as a string
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

  /// Delete a file from storage
  /// 
  /// [fileName] - The full file name/path in storage
  Future<void> deleteFile({required String fileName}) async {
    try {
      await _apiService.deleteFile(fileName: fileName);
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }

  /// List files in a folder
  /// 
  /// [folder] - Optional folder to list files from
  /// [maxResults] - Maximum number of files to return (default: 100)
  /// 
  /// Returns a list of [StorageFile] objects
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

  /// Get storage service status
  /// 
  /// Returns a map with storage service configuration and status
  Future<Map<String, dynamic>> getStorageStatus() async {
    try {
      return await _apiService.getStorageStatus();
    } catch (e) {
      throw StorageException('Failed to get storage status: $e');
    }
  }

  /// Upload and scan a syllabus document
  /// 
  /// [file] - The syllabus file to upload and analyze
  /// [prompt] - Optional custom prompt for analysis
  /// 
  /// Returns analysis results from the AI service
  Future<Map<String, dynamic>> uploadAndScanSyllabus({
    required File file,
    String? prompt,
  }) async {
    try {
      // Validate file type
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

  /// Upload multiple files in batch
  /// 
  /// [files] - List of files to upload
  /// [folder] - Optional folder for all files
  /// [makePublic] - Whether to make all files public
  /// [onProgress] - Progress callback for overall progress
  /// [onFileComplete] - Callback when each individual file completes
  /// 
  /// Returns a list of [StorageUploadResponse] for successful uploads
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
        
        // Update overall progress
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

  /// Get file type category based on content type or extension
  /// 
  /// [file] - The storage file to categorize
  /// 
  /// Returns a [FileCategory] enum value
  FileCategory getFileCategory(StorageFile file) {
    if (file.isImage) return FileCategory.image;
    if (file.isVideo) return FileCategory.video;
    if (file.isAudio) return FileCategory.audio;
    if (file.isDocument) return FileCategory.document;
    return FileCategory.other;
  }

  /// Check if a file type is supported for upload
  /// 
  /// [file] - The file to check
  /// 
  /// Returns true if the file type is supported
  bool isSupportedFileType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const supportedExtensions = {
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg',
      // Documents
      'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt',
      // Audio
      'mp3', 'wav', 'aac', 'ogg', 'm4a',
      // Video
      'mp4', 'avi', 'mov', 'wmv', 'flv', 'webm',
      // Archives
      'zip', 'rar', '7z', 'tar', 'gz',
    };
    
    return supportedExtensions.contains(extension);
  }

  /// Get maximum allowed file size in bytes
  int get maxFileSize => 100 * 1024 * 1024; // 100MB

  /// Get supported file extensions as a formatted string
  String get supportedExtensions => 
      'PDF, DOC, DOCX, TXT, JPG, PNG, MP3, MP4, ZIP and more';
}

/// File category enumeration
enum FileCategory {
  image,
  document,
  video,
  audio,
  other,
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  
  StorageException(this.message);
  
  @override
  String toString() => 'StorageException: $message';
}