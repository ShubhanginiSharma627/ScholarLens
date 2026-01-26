import 'package:flutter/material.dart';
import '../widgets/camera_capture_widget.dart';
import '../models/processed_image.dart';

/// Demo screen showing camera capture functionality
class CameraDemoScreen extends StatefulWidget {
  const CameraDemoScreen({super.key});

  @override
  State<CameraDemoScreen> createState() => _CameraDemoScreenState();
}

class _CameraDemoScreenState extends State<CameraDemoScreen> {
  ProcessedImage? _capturedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Camera Capture Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This demo shows the camera capture functionality with image processing pipeline.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Camera capture button
            CameraCaptureWidget(
              title: 'Capture Study Material',
              buttonText: 'Open Camera',
              buttonIcon: Icons.camera_alt,
              onImageCaptured: (processedImage) {
                setState(() {
                  _capturedImage = processedImage;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Image captured and processed! Size: ${processedImage.formattedSize}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Display captured image info
            if (_capturedImage != null) ...[
              const Text(
                'Last Captured Image:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ProcessedImageCard(
                processedImage: _capturedImage!,
                onTap: () {
                  _showImageDetails(_capturedImage!);
                },
                onDelete: () {
                  setState(() {
                    _capturedImage = null;
                  });
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No image captured yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // Info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Features Demonstrated:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Camera capture with live preview'),
                  Text('• Image cropping interface'),
                  Text('• Automatic compression to 1MB limit'),
                  Text('• Error handling for permissions'),
                  Text('• Processing metadata tracking'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetails(ProcessedImage image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File Size', image.formattedSize),
            _buildDetailRow('Dimensions', '${image.metadata.processedWidth} × ${image.metadata.processedHeight}'),
            _buildDetailRow('Original Size', '${image.metadata.originalWidth} × ${image.metadata.originalHeight}'),
            _buildDetailRow('Was Cropped', image.metadata.wasCropped ? 'Yes' : 'No'),
            _buildDetailRow('Was Compressed', image.metadata.wasCompressed ? 'Yes' : 'No'),
            if (image.metadata.wasCompressed)
              _buildDetailRow('Compression Ratio', '${(image.metadata.compressionRatio * 100).toStringAsFixed(1)}%'),
            _buildDetailRow('Processed At', _formatDateTime(image.processedAt)),
            _buildDetailRow('Under Size Limit', image.isUnderSizeLimit ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}