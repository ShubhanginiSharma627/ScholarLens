import 'package:flutter/material.dart';
import '../screens/camera_screen.dart';
import '../models/processed_image.dart';
import '../animations/camera_animations.dart';

/// Widget for triggering camera capture functionality
class CameraCaptureWidget extends StatelessWidget {
  final String? title;
  final Function(ProcessedImage)? onImageCaptured;
  final Widget? child;
  final String buttonText;
  final IconData buttonIcon;

  const CameraCaptureWidget({
    super.key,
    this.title,
    this.onImageCaptured,
    this.child,
    this.buttonText = 'Capture Image',
    this.buttonIcon = Icons.camera_alt,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return GestureDetector(
        onTap: () => _openCamera(context),
        child: child!,
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _openCamera(context),
      icon: Icon(buttonIcon),
      label: Text(buttonText),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    try {
      final result = await Navigator.of(context).push<ProcessedImage>(
        CameraAnimations.createCameraOpenTransition<ProcessedImage>(
          CameraScreen(
            title: title,
            onImageCaptured: onImageCaptured,
          ),
        ),
      );

      if (result != null && onImageCaptured != null) {
        onImageCaptured!(result);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Floating action button for camera capture
class CameraCaptureFAB extends StatelessWidget {
  final String? title;
  final Function(ProcessedImage)? onImageCaptured;
  final String? heroTag;

  const CameraCaptureFAB({
    super.key,
    this.title,
    this.onImageCaptured,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => _openCamera(context),
      child: const Icon(Icons.camera_alt),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    try {
      final result = await Navigator.of(context).push<ProcessedImage>(
        CameraAnimations.createCameraOpenTransition<ProcessedImage>(
          CameraScreen(
            title: title,
            onImageCaptured: onImageCaptured,
          ),
        ),
      );

      if (result != null && onImageCaptured != null) {
        onImageCaptured!(result);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Card widget for displaying processed image information
class ProcessedImageCard extends StatelessWidget {
  final ProcessedImage processedImage;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ProcessedImageCard({
    super.key,
    required this.processedImage,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.image,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Processed Image',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Size', processedImage.formattedSize),
              _buildInfoRow('Processed', _formatDateTime(processedImage.processedAt)),
              if (processedImage.metadata.wasCropped)
                _buildInfoRow('Cropped', 'Yes'),
              if (processedImage.metadata.wasCompressed)
                _buildInfoRow('Compressed', '${(processedImage.metadata.compressionRatio * 100).toStringAsFixed(1)}%'),
              _buildInfoRow(
                'Dimensions',
                '${processedImage.metadata.processedWidth} × ${processedImage.metadata.processedHeight}',
              ),
              if (!processedImage.isUnderSizeLimit)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Size exceeds 1MB limit',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}