import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/camera_error_handler.dart';
import '../models/processed_image.dart';
import '../animations/camera_animations.dart';

/// Screen for camera capture with live preview and controls
class CameraScreen extends StatefulWidget {
  final String? title;
  final Function(ProcessedImage)? onImageCaptured;
  
  const CameraScreen({
    super.key,
    this.title,
    this.onImageCaptured,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, CameraErrorHandlerMixin {
  late CameraService _cameraService;
  late AnimationController _entranceController;
  late AnimationController _captureController;
  late AnimationController _scanningController;
  late AnimationController _processingController;
  late AnimationController _retakeController;
  
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  bool _showRetakeOption = false;
  ProcessedImage? _capturedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraServiceImpl();
    
    // Initialize animation controllers
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _captureController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scanningController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _processingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _retakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _entranceController.dispose();
    _captureController.dispose();
    _scanningController.dispose();
    _processingController.dispose();
    _retakeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      await _cameraService.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        // Start entrance animation
        _entranceController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        handleCameraError(e, onRetry: _initializeCamera);
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || !_cameraService.isInitialized) return;

    try {
      setState(() {
        _isCapturing = true;
        _errorMessage = null;
      });

      // Trigger capture flash animation
      await CameraAnimations.triggerCaptureEffect(_captureController);
      
      // Start scanning animation
      setState(() {
        _isScanning = true;
      });
      CameraAnimations.triggerScanningSequence(_scanningController);
      
      // Simulate scanning delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Stop scanning and start processing
      CameraAnimations.stopScanning(_scanningController);
      setState(() {
        _isScanning = false;
        _isProcessing = true;
      });
      
      CameraAnimations.triggerProcessingAnimation(_processingController);

      final processedImage = await _cameraService.captureAndProcess(
        cropTitle: widget.title ?? 'Crop Study Material',
      );

      // Stop processing animation
      CameraAnimations.stopProcessing(_processingController);
      setState(() {
        _isProcessing = false;
        _capturedImage = processedImage;
        _showRetakeOption = true;
      });

      // Show success animation briefly
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Call callback if provided
        widget.onImageCaptured?.call(processedImage);
        
        // Navigate back with result
        Navigator.of(context).pop(processedImage);
      }
    } catch (e) {
      // Stop all animations on error
      CameraAnimations.stopScanning(_scanningController);
      CameraAnimations.stopProcessing(_processingController);
      
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isScanning = false;
          _isProcessing = false;
        });
        handleCameraError(e, onRetry: _captureImage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _retakePhoto() async {
    // Start retake animation
    await CameraAnimations.triggerRetakeAnimation(_retakeController);
    
    setState(() {
      _showRetakeOption = false;
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? 'Capture Study Material'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_cameraService.isInitialized) {
      return const Center(
        child: Text(
          'Camera not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Build camera view with entrance animation
    Widget cameraView = Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraService.controller!),
        ),
        
        // Overlay with capture controls
        Positioned.fill(
          child: _buildCameraOverlay(),
        ),
        
        // Capture flash animation
        if (_isCapturing)
          CameraAnimations.createCaptureFlashAnimation(
            child: Container(),
            controller: _captureController,
          ),
        
        // Scanning animation
        if (_isScanning)
          CameraAnimations.createScanningAnimation(
            child: Container(),
            controller: _scanningController,
          ),
        
        // Processing animation
        if (_isProcessing)
          CameraAnimations.createProcessingAnimation(
            child: Container(),
            controller: _processingController,
            message: 'Processing image...',
          ),
      ],
    );

    // Wrap with entrance animation
    return CameraAnimations.createCameraEntranceAnimation(
      child: cameraView,
      controller: _entranceController,
    );
  }

  Widget _buildCameraOverlay() {
    return Column(
      children: [
        // Top instruction area
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Position your study material in the frame and tap capture',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
        
        // Spacer to push controls to bottom
        const Spacer(),
        
        // Bottom controls
        Container(
          padding: const EdgeInsets.all(24),
          child: _showRetakeOption ? _buildRetakeControls() : _buildCameraControls(),
        ),
      ],
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Cancel button
        _buildControlButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.black54,
        ),
        
        // Capture button with animation
        _buildAnimatedCaptureButton(),
        
        // Gallery button (placeholder for future implementation)
        _buildControlButton(
          icon: Icons.photo_library,
          onPressed: () {
            // TODO: Implement gallery selection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gallery selection coming soon'),
              ),
            );
          },
          backgroundColor: Colors.black54,
        ),
      ],
    );
  }

  Widget _buildRetakeControls() {
    return CameraAnimations.createRetakeTransition(
      oldPhoto: _capturedImage != null 
          ? Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_capturedImage!.file),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Container(),
      newCameraView: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Use photo button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_capturedImage != null) {
                  widget.onImageCaptured?.call(_capturedImage!);
                  Navigator.of(context).pop(_capturedImage);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Use Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Retake button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _retakePhoto,
              icon: const Icon(Icons.refresh),
              label: const Text('Retake'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      controller: _retakeController,
    );
  }

  Widget _buildAnimatedCaptureButton() {
    return CameraAnimations.createCameraButtonAnimation(
      onPressed: _captureImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: _isCapturing || _isScanning || _isProcessing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.black54,
  }) {
    return CameraAnimations.createCameraButtonAnimation(
      onPressed: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Widget for displaying camera preview with crop overlay
class CameraPreviewWithOverlay extends StatelessWidget {
  final CameraController controller;
  final Rect? cropRect;
  
  const CameraPreviewWithOverlay({
    super.key,
    required this.controller,
    this.cropRect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(controller),
        if (cropRect != null) _buildCropOverlay(),
      ],
    );
  }

  Widget _buildCropOverlay() {
    return CustomPaint(
      painter: CropOverlayPainter(cropRect!),
      child: Container(),
    );
  }
}

/// Custom painter for crop overlay
class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  
  CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final cropPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw overlay (darken areas outside crop)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
    
    // Draw crop rectangle border
    canvas.drawRect(cropRect, cropPaint);
    
    // Draw corner indicators
    _drawCornerIndicators(canvas, cropRect);
  }

  void _drawCornerIndicators(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerSize = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerSize, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.top + cornerSize),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerSize),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerSize),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerSize, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerSize),
      Offset(rect.right, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}