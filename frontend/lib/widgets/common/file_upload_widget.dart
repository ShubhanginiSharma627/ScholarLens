import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
class FileUploadWidget extends StatefulWidget {
  final String? folder;
  final bool makePublic;
  final List<String>? allowedExtensions;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Function(StorageUploadResponse)? onUploadComplete;
  final Function(String)? onUploadError;
  final Function(double)? onProgress;
  final bool allowMultiple;
  const FileUploadWidget({
    super.key,
    this.folder,
    this.makePublic = false,
    this.allowedExtensions,
    this.title,
    this.subtitle,
    this.icon,
    this.onUploadComplete,
    this.onUploadError,
    this.onProgress,
    this.allowMultiple = false,
  });
  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}
class _FileUploadWidgetState extends State<FileUploadWidget> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _currentFileName;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isUploading ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _isUploading 
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon ?? Icons.upload_file,
              size: 32,
              color: _isUploading 
                  ? Theme.of(context).primaryColor
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title ?? 'Upload File',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle ?? 'Select a file to upload',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentFileName != null 
                  ? 'Uploading $_currentFileName... ${(_uploadProgress * 100).toInt()}%'
                  : 'Uploading... ${(_uploadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _selectAndUploadFile,
              icon: const Icon(Icons.upload),
              label: Text(widget.allowMultiple ? 'Choose Files' : 'Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported: ${_getSupportedExtensionsText()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
  String _getSupportedExtensionsText() {
    if (widget.allowedExtensions != null && widget.allowedExtensions!.isNotEmpty) {
      return widget.allowedExtensions!.map((ext) => ext.toUpperCase()).join(', ');
    }
    return _storageService.supportedExtensions;
  }
  Future<void> _selectAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: widget.allowedExtensions != null 
            ? FileType.custom 
            : FileType.any,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );
      if (result != null) {
        if (widget.allowMultiple) {
          await _uploadMultipleFiles(result.files);
        } else {
          await _uploadSingleFile(result.files.first);
        }
      }
    } catch (e) {
      _handleError('Failed to select file: $e');
    }
  }
  Future<void> _uploadSingleFile(PlatformFile platformFile) async {
    if (platformFile.path == null) {
      _handleError('Failed to access selected file');
      return;
    }
    final file = File(platformFile.path!);
    if (!_storageService.isSupportedFileType(file)) {
      _handleError('Unsupported file type');
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentFileName = platformFile.name;
    });
    try {
      final response = await _storageService.uploadFile(
        file: file,
        folder: widget.folder,
        makePublic: widget.makePublic,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
          widget.onProgress?.call(progress);
        },
      );
      widget.onUploadComplete?.call(response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${platformFile.name} uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handleError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _currentFileName = null;
        });
      }
    }
  }
  Future<void> _uploadMultipleFiles(List<PlatformFile> platformFiles) async {
    final files = platformFiles
        .where((pf) => pf.path != null)
        .map((pf) => File(pf.path!))
        .toList();
    if (files.isEmpty) {
      _handleError('No valid files selected');
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentFileName = '${files.length} files';
    });
    try {
      final responses = await _storageService.uploadMultipleFiles(
        files: files,
        folder: widget.folder,
        makePublic: widget.makePublic,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
          widget.onProgress?.call(progress);
        },
        onFileComplete: (response) {
          widget.onUploadComplete?.call(response);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${responses.length} files uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handleError('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _currentFileName = null;
        });
      }
    }
  }
  void _handleError(String message) {
    widget.onUploadError?.call(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}