import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/storage_service.dart';
class FileManagerWidget extends StatefulWidget {
  final String? folder;
  final Function(StorageFile)? onFileSelected;
  final Function(StorageFile)? onFileDeleted;
  final bool showDeleteButton;
  final bool showDownloadButton;
  const FileManagerWidget({
    super.key,
    this.folder,
    this.onFileSelected,
    this.onFileDeleted,
    this.showDeleteButton = true,
    this.showDownloadButton = true,
  });
  @override
  State<FileManagerWidget> createState() => _FileManagerWidgetState();
}
class _FileManagerWidgetState extends State<FileManagerWidget> {
  final StorageService _storageService = StorageService();
  List<StorageFile> _files = [];
  bool _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadFiles();
  }
  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final files = await _storageService.listFiles(
        folder: widget.folder,
        maxResults: 100,
      );
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load files',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No files found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.folder != null 
                  ? 'No files in ${widget.folder} folder'
                  : 'No files uploaded yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFiles,
      child: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return FileListItem(
            file: file,
            onTap: () => widget.onFileSelected?.call(file),
            onDelete: widget.showDeleteButton 
                ? () => _deleteFile(file)
                : null,
            onDownload: widget.showDownloadButton 
                ? () => _downloadFile(file)
                : null,
          );
        },
      ),
    );
  }
  Future<void> _deleteFile(StorageFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.originalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _storageService.deleteFile(fileName: file.name);
        setState(() {
          _files.removeWhere((f) => f.name == file.name);
        });
        widget.onFileDeleted?.call(file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${file.originalName} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  Future<void> _downloadFile(StorageFile file) async {
    try {
      final url = await _storageService.getDownloadUrl(
        fileName: file.name,
        public: file.isPublic,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download URL: $url'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get download URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
class FileListItem extends StatelessWidget {
  final StorageFile file;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  const FileListItem({
    super.key,
    required this.file,
    this.onTap,
    this.onDelete,
    this.onDownload,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFileTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(),
            color: _getFileTypeColor(),
            size: 20,
          ),
        ),
        title: Text(
          file.originalName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${file.formattedSize} • ${_formatDate(file.timeCreated)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (file.folder != null)
              Text(
                'Folder: ${file.folder}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDownload != null)
              IconButton(
                icon: const Icon(Icons.download, size: 20),
                onPressed: onDownload,
                tooltip: 'Download',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: onDelete,
                color: Colors.red[400],
                tooltip: 'Delete',
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
  IconData _getFileTypeIcon() {
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.video_file;
    if (file.isAudio) return Icons.audio_file;
    if (file.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }
  Color _getFileTypeColor() {
    if (file.isImage) return Colors.green;
    if (file.isVideo) return Colors.purple;
    if (file.isAudio) return Colors.orange;
    if (file.isDocument) return Colors.blue;
    return Colors.grey;
  }
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}