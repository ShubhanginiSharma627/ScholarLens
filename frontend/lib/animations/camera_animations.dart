import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Camera-specific animations for smooth transitions and feedback
class _CameraAnimationUtils {
  /// Creates a smooth transition animation for camera opening
  static PageRouteBuilder<T> createCameraOpenTransition<T>(Widget child) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Creates a capture feedback animation with flash effect
  static Widget createCaptureFlashAnimation({
    required Widget child,
    required AnimationController controller,
    Color flashColor = Colors.white,
  }) {
    final flashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    final fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    return Stack(
      children: [
        child,
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final flashOpacity = flashAnimation.value * fadeAnimation.value;
            return Positioned.fill(
              child: Container(
                color: flashColor.withValues(alpha: flashOpacity * 0.8),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Creates a scanning progress animation with circular indicator
  static Widget createScanningAnimation({
    required Widget child,
    required AnimationController controller,
    Color scanColor = Colors.blue,
    double strokeWidth = 3.0,
  }) {
    final progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progressAnimation.value,
                      strokeWidth: strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(scanColor),
                      backgroundColor: scanColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Creates a processing animation with rotating indicator
  static Widget createProcessingAnimation({
    required Widget child,
    required AnimationController controller,
    String? message,
    Color indicatorColor = Colors.blue,
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Creates camera screen entrance animation
  static Widget createCameraEntranceAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }

  /// Creates a camera button animation with scale and haptic feedback
  static Widget createCameraButtonAnimation({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _AnimatedCameraButton(
      onPressed: onPressed,
      duration: duration,
      child: child,
    );
  }

  /// Creates a retake transition animation
  static Widget createRetakeTransition({
    required Widget oldPhoto,
    required Widget newCameraView,
    required AnimationController controller,
  }) {
    final slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    final slideInAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    return Stack(
      children: [
        SlideTransition(
          position: slideOutAnimation,
          child: oldPhoto,
        ),
        SlideTransition(
          position: slideInAnimation,
          child: newCameraView,
        ),
      ],
    );
  }

  /// Triggers capture feedback with haptic and visual effects
  static Future<void> triggerCaptureEffect(AnimationController controller) async {
    await HapticFeedback.heavyImpact();
    controller.reset();
    await controller.forward();
  }

  /// Triggers scanning animation sequence
  static Future<void> triggerScanningSequence(
    AnimationController controller, {
    Duration scanDuration = const Duration(seconds: 3),
  }) async {
    controller.duration = scanDuration;
    controller.reset();
    controller.repeat();
  }

  /// Stops scanning animation
  static void stopScanning(AnimationController controller) {
    controller.stop();
    controller.reset();
  }

  /// Triggers processing animation
  static Future<void> triggerProcessingAnimation(
    AnimationController controller, {
    Duration processingDuration = const Duration(seconds: 2),
  }) async {
    controller.duration = processingDuration;
    controller.reset();
    controller.repeat();
  }

  /// Stops processing animation
  static void stopProcessing(AnimationController controller) {
    controller.stop();
    controller.reset();
  }

  /// Triggers retake animation sequence
  static Future<void> triggerRetakeAnimation(
    AnimationController controller, {
    Duration retakeDuration = const Duration(milliseconds: 600),
  }) async {
    controller.duration = retakeDuration;
    controller.reset();
    await controller.forward();
  }
}

/// Internal animated camera button widget
class _AnimatedCameraButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;

  const _AnimatedCameraButton({
    required this.child,
    required this.onPressed,
    required this.duration,
  });

  @override
  State<_AnimatedCameraButton> createState() => _AnimatedCameraButtonState();
}

class _AnimatedCameraButtonState extends State<_AnimatedCameraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Public interface for camera animations
class CameraAnimations {
  /// Creates a smooth transition animation for camera opening
  static PageRouteBuilder<T> createCameraOpenTransition<T>(Widget child) {
    return _CameraAnimationUtils.createCameraOpenTransition<T>(child);
  }

  /// Creates a capture feedback animation with flash effect
  static Widget createCaptureFlashAnimation({
    required Widget child,
    required AnimationController controller,
    Color flashColor = Colors.white,
  }) {
    return _CameraAnimationUtils.createCaptureFlashAnimation(
      child: child,
      controller: controller,
      flashColor: flashColor,
    );
  }

  /// Creates a scanning progress animation with circular indicator
  static Widget createScanningAnimation({
    required Widget child,
    required AnimationController controller,
    Color scanColor = Colors.blue,
    double strokeWidth = 3.0,
  }) {
    return _CameraAnimationUtils.createScanningAnimation(
      child: child,
      controller: controller,
      scanColor: scanColor,
      strokeWidth: strokeWidth,
    );
  }

  /// Creates a processing animation with rotating indicator
  static Widget createProcessingAnimation({
    required Widget child,
    required AnimationController controller,
    String? message,
    Color indicatorColor = Colors.blue,
  }) {
    return _CameraAnimationUtils.createProcessingAnimation(
      child: child,
      controller: controller,
      message: message,
      indicatorColor: indicatorColor,
    );
  }

  /// Creates camera screen entrance animation
  static Widget createCameraEntranceAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    return _CameraAnimationUtils.createCameraEntranceAnimation(
      child: child,
      controller: controller,
    );
  }

  /// Creates a camera button animation with scale and haptic feedback
  static Widget createCameraButtonAnimation({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _CameraAnimationUtils.createCameraButtonAnimation(
      child: child,
      onPressed: onPressed,
      duration: duration,
    );
  }

  /// Creates a retake transition animation
  static Widget createRetakeTransition({
    required Widget oldPhoto,
    required Widget newCameraView,
    required AnimationController controller,
  }) {
    return _CameraAnimationUtils.createRetakeTransition(
      oldPhoto: oldPhoto,
      newCameraView: newCameraView,
      controller: controller,
    );
  }

  /// Triggers capture feedback with haptic and visual effects
  static Future<void> triggerCaptureEffect(AnimationController controller) {
    return _CameraAnimationUtils.triggerCaptureEffect(controller);
  }

  /// Triggers scanning animation sequence
  static Future<void> triggerScanningSequence(
    AnimationController controller, {
    Duration scanDuration = const Duration(seconds: 3),
  }) {
    return _CameraAnimationUtils.triggerScanningSequence(
      controller,
      scanDuration: scanDuration,
    );
  }

  /// Stops scanning animation
  static void stopScanning(AnimationController controller) {
    _CameraAnimationUtils.stopScanning(controller);
  }

  /// Triggers processing animation
  static Future<void> triggerProcessingAnimation(
    AnimationController controller, {
    Duration processingDuration = const Duration(seconds: 2),
  }) {
    return _CameraAnimationUtils.triggerProcessingAnimation(
      controller,
      processingDuration: processingDuration,
    );
  }

  /// Stops processing animation
  static void stopProcessing(AnimationController controller) {
    _CameraAnimationUtils.stopProcessing(controller);
  }

  /// Triggers retake animation sequence
  static Future<void> triggerRetakeAnimation(
    AnimationController controller, {
    Duration retakeDuration = const Duration(milliseconds: 600),
  }) {
    return _CameraAnimationUtils.triggerRetakeAnimation(
      controller,
      retakeDuration: retakeDuration,
    );
  }

  /// Triggers results reveal animation
  static Future<void> triggerResultsReveal(AnimationController controller) async {
    controller.reset();
    await controller.forward();
  }

  /// Triggers success animation
  static Future<void> triggerSuccessAnimation(AnimationController controller) async {
    await HapticFeedback.mediumImpact();
    controller.reset();
    await controller.forward();
  }

  /// Creates enhanced results reveal animation
  static Widget createEnhancedResultsReveal({
    required Widget child,
    required AnimationController controller,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}