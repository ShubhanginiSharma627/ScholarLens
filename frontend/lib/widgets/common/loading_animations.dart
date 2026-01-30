import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../animations/animation_manager.dart';
import '../../animations/animation_config.dart';
class LoadingAnimations {
  static Widget circularLoader({
    double size = 24.0,
    Color? color,
    double strokeWidth = 3.0,
    LoadingContext context = LoadingContext.general,
    bool showLabel = false,
    String? label,
  }) {
    final effectiveColor = color ?? _getContextColor(context);
    final effectiveStrokeWidth = strokeWidth * (size / 24.0);
    Widget loader = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: effectiveStrokeWidth,
        strokeCap: StrokeCap.round, // Rounded ends for better appearance
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );
    if (showLabel && label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: effectiveColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }
    return loader;
  }
  static Widget pulsingDots({
    Color? color,
    double size = 8.0,
    int dotCount = 3,
    LoadingContext context = LoadingContext.general,
    Duration pulseDuration = const Duration(milliseconds: 800),
  }) {
    final effectiveColor = color ?? _getContextColor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotCount, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: size * 0.25),
          child: _EnhancedPulsingDot(
            size: size,
            color: effectiveColor,
            delay: Duration(milliseconds: (index * 150)), // Staggered animation
            pulseDuration: pulseDuration,
          ),
        );
      }),
    );
  }
  static Widget shimmerCard({
    double height = 120.0,
    double width = double.infinity,
    BorderRadius? borderRadius,
    LoadingContext context = LoadingContext.content,
  }) {
    return _EnhancedShimmerWidget(
      context: context,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: _getShimmerBaseColor(context),
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }
  static Widget shimmerText({
    double height = 16.0,
    double width = double.infinity,
    BorderRadius? borderRadius,
    LoadingContext context = LoadingContext.content,
    double? widthFactor, // For varied line lengths
  }) {
    final effectiveWidth = widthFactor != null ? width * widthFactor : width;
    return _EnhancedShimmerWidget(
      context: context,
      child: Container(
        height: height,
        width: effectiveWidth,
        decoration: BoxDecoration(
          color: _getShimmerBaseColor(context),
          borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
  static Widget contextualLoader({
    required LoadingContext context,
    double size = 32.0,
    String? message,
    bool showProgress = false,
    double? progress, // 0.0 to 1.0
  }) {
    Widget loader;
    switch (context) {
      case LoadingContext.network:
        loader = _NetworkLoadingIndicator(size: size, progress: progress);
        break;
      case LoadingContext.processing:
        loader = _ProcessingLoadingIndicator(size: size);
        break;
      case LoadingContext.upload:
        loader = _UploadLoadingIndicator(size: size, progress: progress);
        break;
      case LoadingContext.download:
        loader = _DownloadLoadingIndicator(size: size, progress: progress);
        break;
      case LoadingContext.camera:
        loader = _CameraLoadingIndicator(size: size);
        break;
      case LoadingContext.ai:
        loader = _AILoadingIndicator(size: size);
        break;
      default:
        loader = circularLoader(size: size, context: context);
    }
    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: _getContextColor(context).withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return loader;
  }
  static Widget skeletonLoader({
    required Widget child,
    bool isLoading = true,
    LoadingContext context = LoadingContext.content,
    Duration animationDuration = const Duration(milliseconds: 1200),
  }) {
    if (!isLoading) return child;
    return _SkeletonLoader(
      context: context,
      animationDuration: animationDuration,
      child: child,
    );
  }
  static Widget staggeredLoader({
    required List<Widget> items,
    Duration itemDelay = const Duration(milliseconds: 100),
    Duration itemDuration = const Duration(milliseconds: 300),
    LoadingContext context = LoadingContext.content,
  }) {
    return Column(
      children: List.generate(items.length, (index) {
        return _StaggeredLoadingItem(
          delay: itemDelay * index,
          duration: itemDuration,
          context: context,
          child: items[index],
        );
      }),
    );
  }
  static Widget loadingOverlay({
    required Widget child,
    bool isLoading = false,
    LoadingContext context = LoadingContext.general,
    String? message,
    Color? overlayColor,
    double overlayOpacity = 0.7,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (overlayColor ?? Colors.black).withValues(alpha: overlayOpacity),
            child: Center(
              child: contextualLoader(
                context: context,
                message: message,
                size: 48.0,
              ),
            ),
          ),
      ],
    );
  }
  static Widget animatedProgressBar({
    required double progress, // 0.0 to 1.0
    double height = 8.0,
    Color? backgroundColor,
    Color? progressColor,
    BorderRadius? borderRadius,
    Duration animationDuration = const Duration(milliseconds: 500),
    Curve animationCurve = Curves.easeInOut,
    bool showPercentage = false,
    TextStyle? percentageStyle,
    LoadingContext context = LoadingContext.general,
  }) {
    final effectiveProgressColor = progressColor ?? _getContextColor(context);
    final effectiveBackgroundColor = backgroundColor ?? Colors.grey[300]!;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(height / 2);
    Widget progressBar = _AnimatedProgressBar(
      progress: progress.clamp(0.0, 1.0),
      height: height,
      backgroundColor: effectiveBackgroundColor,
      progressColor: effectiveProgressColor,
      borderRadius: effectiveBorderRadius,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
    );
    if (showPercentage) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${(progress * 100).round()}%',
            style: percentageStyle ?? TextStyle(
              fontSize: 12,
              color: effectiveProgressColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          progressBar,
        ],
      );
    }
    return progressBar;
  }
  static Widget animatedCircularProgress({
    required double progress, // 0.0 to 1.0
    double size = 48.0,
    double strokeWidth = 4.0,
    Color? backgroundColor,
    Color? progressColor,
    Duration animationDuration = const Duration(milliseconds: 500),
    Curve animationCurve = Curves.easeInOut,
    bool showPercentage = false,
    TextStyle? percentageStyle,
    LoadingContext context = LoadingContext.general,
    Widget? centerWidget,
  }) {
    final effectiveProgressColor = progressColor ?? _getContextColor(context);
    final effectiveBackgroundColor = backgroundColor ?? Colors.grey[300]!;
    return _AnimatedCircularProgress(
      progress: progress.clamp(0.0, 1.0),
      size: size,
      strokeWidth: strokeWidth,
      backgroundColor: effectiveBackgroundColor,
      progressColor: effectiveProgressColor,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      showPercentage: showPercentage,
      percentageStyle: percentageStyle,
      centerWidget: centerWidget,
    );
  }
  static Widget networkSkeletonLoader({
    required List<Widget> skeletonItems,
    bool isLoading = true,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration shimmerDuration = const Duration(milliseconds: 1200),
  }) {
    if (!isLoading) {
      return Column(children: skeletonItems);
    }
    return Column(
      children: List.generate(skeletonItems.length, (index) {
        return _NetworkSkeletonItem(
          delay: staggerDelay * index,
          shimmerDuration: shimmerDuration,
          child: skeletonItems[index],
        );
      }),
    );
  }
  static Widget stepProgressIndicator({
    required List<String> steps,
    required int currentStep, // 0-based index
    Color? activeColor,
    Color? inactiveColor,
    Color? completedColor,
    double stepSize = 32.0,
    double lineHeight = 2.0,
    TextStyle? labelStyle,
    Duration animationDuration = const Duration(milliseconds: 400),
    LoadingContext context = LoadingContext.general,
  }) {
    final effectiveActiveColor = activeColor ?? _getContextColor(context);
    final effectiveCompletedColor = completedColor ?? Colors.green;
    final effectiveInactiveColor = inactiveColor ?? Colors.grey[300]!;
    return _StepProgressIndicator(
      steps: steps,
      currentStep: currentStep.clamp(0, steps.length - 1),
      activeColor: effectiveActiveColor,
      inactiveColor: effectiveInactiveColor,
      completedColor: effectiveCompletedColor,
      stepSize: stepSize,
      lineHeight: lineHeight,
      labelStyle: labelStyle,
      animationDuration: animationDuration,
    );
  }
  static Widget waveProgressIndicator({
    required double progress, // 0.0 to 1.0
    double width = 200.0,
    double height = 40.0,
    Color? waveColor,
    int waveCount = 20,
    Duration animationDuration = const Duration(milliseconds: 300),
    LoadingContext context = LoadingContext.processing,
  }) {
    final effectiveWaveColor = waveColor ?? _getContextColor(context);
    return _WaveProgressIndicator(
      progress: progress.clamp(0.0, 1.0),
      width: width,
      height: height,
      waveColor: effectiveWaveColor,
      waveCount: waveCount,
      animationDuration: animationDuration,
    );
  }
  static Widget loadingToContentTransition({
    required Widget loadingWidget,
    required Widget contentWidget,
    required bool isLoading,
    Duration transitionDuration = const Duration(milliseconds: 400),
    Curve transitionCurve = Curves.easeInOut,
    LoadingTransitionType transitionType = LoadingTransitionType.fadeScale,
    Duration contentDelay = const Duration(milliseconds: 100),
  }) {
    return _LoadingToContentTransition(
      loadingWidget: loadingWidget,
      contentWidget: contentWidget,
      isLoading: isLoading,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      transitionType: transitionType,
      contentDelay: contentDelay,
    );
  }
  static Widget fadeInContent({
    required Widget child,
    required bool show,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
    VoidCallback? onComplete,
  }) {
    return _FadeInContent(
      show: show,
      duration: duration,
      delay: delay,
      curve: curve,
      onComplete: onComplete,
      child: child,
    );
  }
  static Widget slideInContent({
    required Widget child,
    required bool show,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
    Offset slideDirection = const Offset(0.0, 0.3),
    VoidCallback? onComplete,
  }) {
    return _SlideInContent(
      show: show,
      duration: duration,
      delay: delay,
      curve: curve,
      slideDirection: slideDirection,
      onComplete: onComplete,
      child: child,
    );
  }
  static Widget scaleInContent({
    required Widget child,
    required bool show,
    Duration duration = const Duration(milliseconds: 350),
    Duration delay = Duration.zero,
    Curve curve = Curves.elasticOut,
    double scaleStart = 0.8,
    VoidCallback? onComplete,
  }) {
    return _ScaleInContent(
      show: show,
      duration: duration,
      delay: delay,
      curve: curve,
      scaleStart: scaleStart,
      onComplete: onComplete,
      child: child,
    );
  }
  static Widget staggeredContentReveal({
    required List<Widget> children,
    required bool show,
    Duration itemDuration = const Duration(milliseconds: 300),
    Duration itemDelay = const Duration(milliseconds: 80),
    Duration initialDelay = Duration.zero,
    Curve curve = Curves.easeOut,
    StaggerDirection direction = StaggerDirection.topToBottom,
    VoidCallback? onComplete,
  }) {
    return _StaggeredContentReveal(
      children: children,
      show: show,
      itemDuration: itemDuration,
      itemDelay: itemDelay,
      initialDelay: initialDelay,
      curve: curve,
      direction: direction,
      onComplete: onComplete,
    );
  }
  static Widget morphingContent({
    required Widget placeholderWidget,
    required Widget contentWidget,
    required bool showContent,
    Duration morphDuration = const Duration(milliseconds: 500),
    Curve morphCurve = Curves.easeInOut,
    VoidCallback? onMorphComplete,
  }) {
    return _MorphingContent(
      placeholderWidget: placeholderWidget,
      contentWidget: contentWidget,
      showContent: showContent,
      morphDuration: morphDuration,
      morphCurve: morphCurve,
      onMorphComplete: onMorphComplete,
    );
  }
  static Color _getContextColor(LoadingContext context) {
    switch (context) {
      case LoadingContext.success:
        return Colors.green;
      case LoadingContext.error:
        return Colors.red;
      case LoadingContext.warning:
        return Colors.orange;
      case LoadingContext.network:
        return Colors.blue;
      case LoadingContext.processing:
        return Colors.purple;
      case LoadingContext.upload:
        return Colors.teal;
      case LoadingContext.download:
        return Colors.indigo;
      case LoadingContext.camera:
        return Colors.cyan;
      case LoadingContext.ai:
        return Colors.deepPurple;
      default:
        return AppTheme.primaryColor;
    }
  }
  static Color _getShimmerBaseColor(LoadingContext context) {
    switch (context) {
      case LoadingContext.content:
        return Colors.grey[300]!;
      case LoadingContext.card:
        return Colors.grey[200]!;
      case LoadingContext.text:
        return Colors.grey[350]!;
      default:
        return Colors.grey[300]!;
    }
  }
  static Widget bouncingButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _BouncingButton(
      onPressed: onPressed,
      duration: duration,
      child: child,
    );
  }
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return _FadeInWidget(
      duration: duration,
      delay: delay,
      child: child,
    );
  }
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
    Offset begin = const Offset(0.0, 0.3),
  }) {
    return _SlideInWidget(
      duration: duration,
      delay: delay,
      begin: begin,
      child: child,
    );
  }
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return _ScaleInWidget(
      duration: duration,
      delay: delay,
      child: child,
    );
  }
  static Animation<double> _createPulseAnimation(int index) {
    return AlwaysStoppedAnimation(1.0);
  }
}
enum LoadingContext {
  general,     // General purpose loading
  network,     // Network requests
  processing,  // Data processing
  upload,      // File uploads
  download,    // File downloads
  camera,      // Camera operations
  ai,          // AI processing
  content,     // Content loading
  card,        // Card loading
  text,        // Text loading
  success,     // Success states
  error,       // Error states
  warning,     // Warning states
}
enum LoadingTransitionType {
  fade,        // Simple fade transition
  fadeScale,   // Fade with scale effect
  slideUp,     // Slide up transition
  slideDown,   // Slide down transition
  slideLeft,   // Slide left transition
  slideRight,  // Slide right transition
  morph,       // Morphing transition
  reveal,      // Reveal transition
}
enum StaggerDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  center,
}
class _EnhancedPulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  final Duration delay;
  final Duration pulseDuration;
  const _EnhancedPulsingDot({
    required this.size,
    required this.color,
    required this.delay,
    required this.pulseDuration,
  });
  @override
  State<_EnhancedPulsingDot> createState() => _EnhancedPulsingDotState();
}
class _EnhancedPulsingDotState extends State<_EnhancedPulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final AnimationManager _animationManager = AnimationManager();
  String? _animationId;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    if (_animationManager.isInitialized) {
      _animationId = _animationManager.registerController(
        controller: _controller,
        config: AnimationConfigs.loadingSpinner.copyWith(
          duration: widget.pulseDuration,
        ),
        category: AnimationCategory.feedback,
      );
    }
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }
  @override
  void dispose() {
    if (_animationId != null) {
      _animationManager.disposeController(_animationId!);
    }
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _opacityAnimation.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
class _EnhancedShimmerWidget extends StatefulWidget {
  final Widget child;
  final LoadingContext context;
  const _EnhancedShimmerWidget({
    required this.child,
    required this.context,
  });
  @override
  State<_EnhancedShimmerWidget> createState() => _EnhancedShimmerWidgetState();
}
class _EnhancedShimmerWidgetState extends State<_EnhancedShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final AnimationManager _animationManager = AnimationManager();
  String? _animationId;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // More realistic timing
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    if (_animationManager.isInitialized) {
      _animationId = _animationManager.registerController(
        controller: _controller,
        config: AnimationConfigs.skeletonShimmer,
        category: AnimationCategory.feedback,
      );
    }
    _controller.repeat();
  }
  @override
  void dispose() {
    if (_animationId != null) {
      _animationManager.disposeController(_animationId!);
    }
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.8),
                Colors.white.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                (_animation.value - 0.2).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.2).clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
class _NetworkLoadingIndicator extends StatefulWidget {
  final double size;
  final double? progress;
  const _NetworkLoadingIndicator({
    required this.size,
    this.progress,
  });
  @override
  State<_NetworkLoadingIndicator> createState() => _NetworkLoadingIndicatorState();
}
class _NetworkLoadingIndicatorState extends State<_NetworkLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);
    _waveController.repeat();
  }
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _NetworkLoadingPainter(
              progress: _waveAnimation.value,
              color: LoadingAnimations._getContextColor(LoadingContext.network),
            ),
          );
        },
      ),
    );
  }
}
class _ProcessingLoadingIndicator extends StatefulWidget {
  final double size;
  const _ProcessingLoadingIndicator({required this.size});
  @override
  State<_ProcessingLoadingIndicator> createState() => _ProcessingLoadingIndicatorState();
}
class _ProcessingLoadingIndicatorState extends State<_ProcessingLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_controller);
    _controller.repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Icon(
              Icons.settings,
              size: widget.size,
              color: LoadingAnimations._getContextColor(LoadingContext.processing),
            ),
          );
        },
      ),
    );
  }
}
class _UploadLoadingIndicator extends StatefulWidget {
  final double size;
  final double? progress;
  const _UploadLoadingIndicator({
    required this.size,
    this.progress,
  });
  @override
  State<_UploadLoadingIndicator> createState() => _UploadLoadingIndicatorState();
}
class _UploadLoadingIndicatorState extends State<_UploadLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));
    _controller.repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.progress != null)
            CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation(
                LoadingAnimations._getContextColor(LoadingContext.upload),
              ),
            ),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -5 * _bounceAnimation.value),
                child: Icon(
                  Icons.cloud_upload,
                  size: widget.size * 0.6,
                  color: LoadingAnimations._getContextColor(LoadingContext.upload),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
class _DownloadLoadingIndicator extends StatefulWidget {
  final double size;
  final double? progress;
  const _DownloadLoadingIndicator({
    required this.size,
    this.progress,
  });
  @override
  State<_DownloadLoadingIndicator> createState() => _DownloadLoadingIndicatorState();
}
class _DownloadLoadingIndicatorState extends State<_DownloadLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));
    _controller.repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.progress != null)
            CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation(
                LoadingAnimations._getContextColor(LoadingContext.download),
              ),
            ),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 5 * _bounceAnimation.value),
                child: Icon(
                  Icons.cloud_download,
                  size: widget.size * 0.6,
                  color: LoadingAnimations._getContextColor(LoadingContext.download),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
class _CameraLoadingIndicator extends StatefulWidget {
  final double size;
  const _CameraLoadingIndicator({required this.size});
  @override
  State<_CameraLoadingIndicator> createState() => _CameraLoadingIndicatorState();
}
class _CameraLoadingIndicatorState extends State<_CameraLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: LoadingAnimations._getContextColor(LoadingContext.camera),
                  width: 3.0,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: widget.size * 0.5,
                color: LoadingAnimations._getContextColor(LoadingContext.camera),
              ),
            ),
          );
        },
      ),
    );
  }
}
class _AILoadingIndicator extends StatefulWidget {
  final double size;
  const _AILoadingIndicator({required this.size});
  @override
  State<_AILoadingIndicator> createState() => _AILoadingIndicatorState();
}
class _AILoadingIndicatorState extends State<_AILoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _waveController.repeat();
    _pulseController.repeat(reverse: true);
  }
  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: CustomPaint(
              painter: _AILoadingPainter(
                progress: _waveAnimation.value,
                color: LoadingAnimations._getContextColor(LoadingContext.ai),
              ),
            ),
          );
        },
      ),
    );
  }
}
class _SkeletonLoader extends StatefulWidget {
  final Widget child;
  final LoadingContext context;
  final Duration animationDuration;
  const _SkeletonLoader({
    required this.child,
    required this.context,
    required this.animationDuration,
  });
  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}
class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                LoadingAnimations._getShimmerBaseColor(widget.context),
                Colors.white.withValues(alpha: 0.8),
                LoadingAnimations._getShimmerBaseColor(widget.context),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
class _StaggeredLoadingItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final LoadingContext context;
  const _StaggeredLoadingItem({
    required this.child,
    required this.delay,
    required this.duration,
    required this.context,
  });
  @override
  State<_StaggeredLoadingItem> createState() => _StaggeredLoadingItemState();
}
class _StaggeredLoadingItemState extends State<_StaggeredLoadingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}
class _NetworkLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _NetworkLoadingPainter({
    required this.progress,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    for (int i = 0; i < 3; i++) {
      final currentRadius = radius + (i * 8);
      final opacity = (math.sin(progress + i * 0.5) + 1) / 2;
      paint.color = color.withValues(alpha: opacity * 0.7);
      canvas.drawCircle(center, currentRadius, paint);
    }
    paint.style = PaintingStyle.fill;
    paint.color = color;
    canvas.drawCircle(center, 4, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class _AILoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _AILoadingPainter({
    required this.progress,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;
    final path = Path();
    for (double i = 0; i < size.width; i += 2) {
      final x = i;
      final y = center.dy + 
          math.sin((i / size.width) * 4 * math.pi + progress) * radius * 0.3 +
          math.sin((i / size.width) * 8 * math.pi + progress * 2) * radius * 0.1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final double height;
  final Color backgroundColor;
  final Color progressColor;
  final BorderRadius borderRadius;
  final Duration animationDuration;
  final Curve animationCurve;
  const _AnimatedProgressBar({
    required this.progress,
    required this.height,
    required this.backgroundColor,
    required this.progressColor,
    required this.borderRadius,
    required this.animationDuration,
    required this.animationCurve,
  });
  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}
class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  final AnimationManager _animationManager = AnimationManager();
  String? _animationId;
  double _currentProgress = 0.0;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));
    if (_animationManager.isInitialized) {
      _animationId = _animationManager.registerController(
        controller: _controller,
        config: AnimationConfigs.progressBar.copyWith(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
        ),
        category: AnimationCategory.feedback,
      );
    }
    _currentProgress = widget.progress;
    _controller.forward();
  }
  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ));
      _currentProgress = widget.progress;
      _controller.reset();
      _controller.forward();
    }
  }
  @override
  void dispose() {
    if (_animationId != null) {
      _animationManager.disposeController(_animationId!);
    }
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.progressColor,
                borderRadius: widget.borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}
class _AnimatedCircularProgress extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showPercentage;
  final TextStyle? percentageStyle;
  final Widget? centerWidget;
  const _AnimatedCircularProgress({
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    required this.animationDuration,
    required this.animationCurve,
    required this.showPercentage,
    this.percentageStyle,
    this.centerWidget,
  });
  @override
  State<_AnimatedCircularProgress> createState() => _AnimatedCircularProgressState();
}
class _AnimatedCircularProgressState extends State<_AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  final AnimationManager _animationManager = AnimationManager();
  String? _animationId;
  double _currentProgress = 0.0;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));
    if (_animationManager.isInitialized) {
      _animationId = _animationManager.registerController(
        controller: _controller,
        config: AnimationConfigs.progressBar.copyWith(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
        ),
        category: AnimationCategory.feedback,
      );
    }
    _currentProgress = widget.progress;
    _controller.forward();
  }
  @override
  void didUpdateWidget(_AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ));
      _currentProgress = widget.progress;
      _controller.reset();
      _controller.forward();
    }
  }
  @override
  void dispose() {
    if (_animationId != null) {
      _animationManager.disposeController(_animationId!);
    }
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: widget.strokeWidth,
            valueColor: AlwaysStoppedAnimation(widget.backgroundColor),
          ),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _progressAnimation.value,
                strokeWidth: widget.strokeWidth,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(widget.progressColor),
              );
            },
          ),
          if (widget.centerWidget != null)
            widget.centerWidget!
          else if (widget.showPercentage)
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).round()}%',
                  style: widget.percentageStyle ?? TextStyle(
                    fontSize: widget.size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: widget.progressColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
class _NetworkSkeletonItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration shimmerDuration;
  const _NetworkSkeletonItem({
    required this.child,
    required this.delay,
    required this.shimmerDuration,
  });
  @override
  State<_NetworkSkeletonItem> createState() => _NetworkSkeletonItemState();
}
class _NetworkSkeletonItemState extends State<_NetworkSkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.shimmerDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        _controller.repeat();
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.white.withValues(alpha: 0.8),
                Colors.grey[300]!,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
class _StepProgressIndicator extends StatefulWidget {
  final List<String> steps;
  final int currentStep;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;
  final double stepSize;
  final double lineHeight;
  final TextStyle? labelStyle;
  final Duration animationDuration;
  const _StepProgressIndicator({
    required this.steps,
    required this.currentStep,
    required this.activeColor,
    required this.inactiveColor,
    required this.completedColor,
    required this.stepSize,
    required this.lineHeight,
    this.labelStyle,
    required this.animationDuration,
  });
  @override
  State<_StepProgressIndicator> createState() => _StepProgressIndicatorState();
}
class _StepProgressIndicatorState extends State<_StepProgressIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _stepControllers;
  late List<Animation<double>> _stepAnimations;
  final AnimationManager _animationManager = AnimationManager();
  final List<String> _animationIds = [];
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _stepControllers = List.generate(widget.steps.length, (index) {
      return AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
    });
    _stepAnimations = _stepControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();
    for (int i = 0; i < _stepControllers.length; i++) {
      if (_animationManager.isInitialized) {
        final animationId = _animationManager.registerController(
          controller: _stepControllers[i],
          config: AnimationConfigs.progressBar.copyWith(
            duration: widget.animationDuration,
            curve: Curves.elasticOut,
          ),
          category: AnimationCategory.feedback,
        );
        _animationIds.add(animationId);
      }
    }
    _updateStepAnimations();
  }
  @override
  void didUpdateWidget(_StepProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep) {
      _updateStepAnimations();
    }
  }
  void _updateStepAnimations() {
    for (int i = 0; i < _stepControllers.length; i++) {
      if (i <= widget.currentStep) {
        _stepControllers[i].forward();
      } else {
        _stepControllers[i].reverse();
      }
    }
  }
  @override
  void dispose() {
    for (final animationId in _animationIds) {
      _animationManager.disposeController(animationId);
    }
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(widget.steps.length * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              return AnimatedBuilder(
                animation: _stepAnimations[stepIndex],
                builder: (context, child) {
                  Color stepColor;
                  if (stepIndex < widget.currentStep) {
                    stepColor = widget.completedColor;
                  } else if (stepIndex == widget.currentStep) {
                    stepColor = widget.activeColor;
                  } else {
                    stepColor = widget.inactiveColor;
                  }
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _stepAnimations[stepIndex].value),
                    child: Container(
                      width: widget.stepSize,
                      height: widget.stepSize,
                      decoration: BoxDecoration(
                        color: stepColor,
                        shape: BoxShape.circle,
                      ),
                      child: stepIndex < widget.currentStep
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: widget.stepSize * 0.6,
                            )
                          : Center(
                              child: Text(
                                '${stepIndex + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.stepSize * 0.4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              );
            } else {
              final lineIndex = index ~/ 2;
              return Expanded(
                child: Container(
                  height: widget.lineHeight,
                  color: lineIndex < widget.currentStep
                      ? widget.completedColor
                      : widget.inactiveColor,
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(widget.steps.length, (index) {
            return Expanded(
              child: Text(
                widget.steps[index],
                textAlign: TextAlign.center,
                style: widget.labelStyle ?? TextStyle(
                  fontSize: 12,
                  color: index <= widget.currentStep
                      ? widget.activeColor
                      : widget.inactiveColor,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
class _WaveProgressIndicator extends StatefulWidget {
  final double progress;
  final double width;
  final double height;
  final Color waveColor;
  final int waveCount;
  final Duration animationDuration;
  const _WaveProgressIndicator({
    required this.progress,
    required this.width,
    required this.height,
    required this.waveColor,
    required this.waveCount,
    required this.animationDuration,
  });
  @override
  State<_WaveProgressIndicator> createState() => _WaveProgressIndicatorState();
}
class _WaveProgressIndicatorState extends State<_WaveProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _currentProgress = widget.progress;
    _controller.forward();
  }
  @override
  void didUpdateWidget(_WaveProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _currentProgress = widget.progress;
      _controller.reset();
      _controller.forward();
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _WaveProgressPainter(
              progress: _progressAnimation.value,
              waveColor: widget.waveColor,
              waveCount: widget.waveCount,
            ),
          );
        },
      ),
    );
  }
}
class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color waveColor;
  final int waveCount;
  _WaveProgressPainter({
    required this.progress,
    required this.waveColor,
    required this.waveCount,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;
    final waveWidth = size.width / waveCount;
    final activeWaves = (waveCount * progress).floor();
    final partialWave = (waveCount * progress) - activeWaves;
    for (int i = 0; i < waveCount; i++) {
      final x = i * waveWidth;
      double waveHeight;
      if (i < activeWaves) {
        waveHeight = size.height;
      } else if (i == activeWaves) {
        waveHeight = size.height * partialWave;
      } else {
        waveHeight = size.height * 0.1;
      }
      final opacity = i < activeWaves ? 1.0 : 
                     i == activeWaves ? partialWave : 0.3;
      paint.color = waveColor.withValues(alpha: opacity);
      final rect = Rect.fromLTWH(
        x + waveWidth * 0.1,
        size.height - waveHeight,
        waveWidth * 0.8,
        waveHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(waveWidth * 0.1)),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class _LoadingToContentTransition extends StatefulWidget {
  final Widget loadingWidget;
  final Widget contentWidget;
  final bool isLoading;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final LoadingTransitionType transitionType;
  final Duration contentDelay;
  const _LoadingToContentTransition({
    required this.loadingWidget,
    required this.contentWidget,
    required this.isLoading,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.transitionType,
    required this.contentDelay,
  });
  @override
  State<_LoadingToContentTransition> createState() => _LoadingToContentTransitionState();
}
class _LoadingToContentTransitionState extends State<_LoadingToContentTransition>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _contentController;
  late Animation<double> _loadingFadeAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _contentScaleAnimation;
  late Animation<Offset> _contentSlideAnimation;
  final AnimationManager _animationManager = AnimationManager();
  String? _loadingAnimationId;
  String? _contentAnimationId;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _loadingController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _contentController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _setupAnimations();
    _registerAnimations();
    if (widget.isLoading) {
      _loadingController.value = 1.0;
      _contentController.value = 0.0;
    } else {
      _loadingController.value = 0.0;
      _contentController.value = 1.0;
    }
  }
  void _setupAnimations() {
    _loadingFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: widget.transitionCurve,
    ));
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: widget.transitionCurve,
    ));
    _contentScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: widget.transitionCurve,
    ));
    Offset slideOffset;
    switch (widget.transitionType) {
      case LoadingTransitionType.slideUp:
        slideOffset = const Offset(0.0, 0.3);
        break;
      case LoadingTransitionType.slideDown:
        slideOffset = const Offset(0.0, -0.3);
        break;
      case LoadingTransitionType.slideLeft:
        slideOffset = const Offset(0.3, 0.0);
        break;
      case LoadingTransitionType.slideRight:
        slideOffset = const Offset(-0.3, 0.0);
        break;
      default:
        slideOffset = const Offset(0.0, 0.1);
    }
    _contentSlideAnimation = Tween<Offset>(
      begin: slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: widget.transitionCurve,
    ));
  }
  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      _loadingAnimationId = _animationManager.registerController(
        controller: _loadingController,
        config: AnimationConfigs.fadeTransition.copyWith(
          duration: widget.transitionDuration,
          curve: widget.transitionCurve,
        ),
        category: AnimationCategory.content,
      );
      _contentAnimationId = _animationManager.registerController(
        controller: _contentController,
        config: AnimationConfigs.fadeTransition.copyWith(
          duration: widget.transitionDuration,
          curve: widget.transitionCurve,
        ),
        category: AnimationCategory.content,
      );
    }
  }
  @override
  void didUpdateWidget(_LoadingToContentTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _contentController.reverse();
        _loadingController.forward();
      } else {
        _loadingController.reverse();
        Future.delayed(widget.contentDelay, () {
          if (mounted) {
            _contentController.forward();
          }
        });
      }
    }
  }
  @override
  void dispose() {
    if (_loadingAnimationId != null) {
      _animationManager.disposeController(_loadingAnimationId!);
    }
    if (_contentAnimationId != null) {
      _animationManager.disposeController(_contentAnimationId!);
    }
    _loadingController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _contentFadeAnimation,
            _contentScaleAnimation,
            _contentSlideAnimation,
          ]),
          builder: (context, child) {
            if (_contentFadeAnimation.value == 0.0) {
              return const SizedBox.shrink();
            }
            Widget content = widget.contentWidget;
            switch (widget.transitionType) {
              case LoadingTransitionType.fadeScale:
                content = Transform.scale(
                  scale: _contentScaleAnimation.value,
                  child: content,
                );
                break;
              case LoadingTransitionType.slideUp:
              case LoadingTransitionType.slideDown:
              case LoadingTransitionType.slideLeft:
              case LoadingTransitionType.slideRight:
                content = SlideTransition(
                  position: _contentSlideAnimation,
                  child: content,
                );
                break;
              default:
                break;
            }
            return Opacity(
              opacity: _contentFadeAnimation.value,
              child: content,
            );
          },
        ),
        AnimatedBuilder(
          animation: _loadingFadeAnimation,
          builder: (context, child) {
            if (_loadingFadeAnimation.value == 0.0) {
              return const SizedBox.shrink();
            }
            return Opacity(
              opacity: _loadingFadeAnimation.value,
              child: widget.loadingWidget,
            );
          },
        ),
      ],
    );
  }
}
class _PulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  final Animation<double> animation;
  const _PulsingDot({
    required this.size,
    required this.color,
    required this.animation,
  });
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});
  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}
class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  const _BouncingButton({
    required this.child,
    required this.onPressed,
    required this.duration,
  });
  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}
class _BouncingButtonState extends State<_BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  void _onTapCancel() {
    _controller.reverse();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
class _FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  const _FadeInWidget({
    required this.child,
    required this.duration,
    required this.delay,
  });
  @override
  State<_FadeInWidget> createState() => _FadeInWidgetState();
}
class _FadeInWidgetState extends State<_FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
class _SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;
  const _SlideInWidget({
    required this.child,
    required this.duration,
    required this.delay,
    required this.begin,
  });
  @override
  State<_SlideInWidget> createState() => _SlideInWidgetState();
}
class _SlideInWidgetState extends State<_SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SlideTransition(
          position: _animation,
          child: widget.child,
        );
      },
    );
  }
}
class _ScaleInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  const _ScaleInWidget({
    required this.child,
    required this.duration,
    required this.delay,
  });
  @override
  State<_ScaleInWidget> createState() => _ScaleInWidgetState();
}
class _ScaleInWidgetState extends State<_ScaleInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
class _FadeInContent extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final VoidCallback? onComplete;
  const _FadeInContent({
    required this.child,
    required this.show,
    required this.duration,
    required this.delay,
    required this.curve,
    this.onComplete,
  });
  @override
  State<_FadeInContent> createState() => _FadeInContentState();
}
class _FadeInContentState extends State<_FadeInContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    if (widget.show) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }
  @override
  void didUpdateWidget(_FadeInContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        _controller.reverse();
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
class _SlideInContent extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset slideDirection;
  final VoidCallback? onComplete;
  const _SlideInContent({
    required this.child,
    required this.show,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.slideDirection,
    this.onComplete,
  });
  @override
  State<_SlideInContent> createState() => _SlideInContentState();
}
class _SlideInContentState extends State<_SlideInContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.slideDirection,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    if (widget.show) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }
  @override
  void didUpdateWidget(_SlideInContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        _controller.reverse();
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}
class _ScaleInContent extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double scaleStart;
  final VoidCallback? onComplete;
  const _ScaleInContent({
    required this.child,
    required this.show,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.scaleStart,
    this.onComplete,
  });
  @override
  State<_ScaleInContent> createState() => _ScaleInContentState();
}
class _ScaleInContentState extends State<_ScaleInContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: widget.scaleStart,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    if (widget.show) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }
  @override
  void didUpdateWidget(_ScaleInContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        _controller.reverse();
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}
class _StaggeredContentReveal extends StatefulWidget {
  final List<Widget> children;
  final bool show;
  final Duration itemDuration;
  final Duration itemDelay;
  final Duration initialDelay;
  final Curve curve;
  final StaggerDirection direction;
  final VoidCallback? onComplete;
  const _StaggeredContentReveal({
    required this.children,
    required this.show,
    required this.itemDuration,
    required this.itemDelay,
    required this.initialDelay,
    required this.curve,
    required this.direction,
    this.onComplete,
  });
  @override
  State<_StaggeredContentReveal> createState() => _StaggeredContentRevealState();
}
class _StaggeredContentRevealState extends State<_StaggeredContentReveal>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  int _completedAnimations = 0;
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (index) {
      return AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      );
    });
    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();
    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: _getSlideOffset(),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();
    for (final controller in _controllers) {
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedAnimations++;
          if (_completedAnimations >= _controllers.length) {
            widget.onComplete?.call();
          }
        }
      });
    }
    if (widget.show) {
      _startStaggeredAnimation();
    }
  }
  Offset _getSlideOffset() {
    switch (widget.direction) {
      case StaggerDirection.topToBottom:
        return const Offset(0.0, -0.3);
      case StaggerDirection.bottomToTop:
        return const Offset(0.0, 0.3);
      case StaggerDirection.leftToRight:
        return const Offset(-0.3, 0.0);
      case StaggerDirection.rightToLeft:
        return const Offset(0.3, 0.0);
      case StaggerDirection.center:
        return const Offset(0.0, 0.0);
    }
  }
  void _startStaggeredAnimation() {
    _completedAnimations = 0;
    for (int i = 0; i < _controllers.length; i++) {
      final delay = widget.initialDelay + (widget.itemDelay * i);
      Future.delayed(delay, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }
  @override
  void didUpdateWidget(_StaggeredContentReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _startStaggeredAnimation();
      } else {
        for (final controller in _controllers) {
          controller.reverse();
        }
      }
    }
  }
  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            _fadeAnimations[index],
            _slideAnimations[index],
          ]),
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
}
class _MorphingContent extends StatefulWidget {
  final Widget placeholderWidget;
  final Widget contentWidget;
  final bool showContent;
  final Duration morphDuration;
  final Curve morphCurve;
  final VoidCallback? onMorphComplete;
  const _MorphingContent({
    required this.placeholderWidget,
    required this.contentWidget,
    required this.showContent,
    required this.morphDuration,
    required this.morphCurve,
    this.onMorphComplete,
  });
  @override
  State<_MorphingContent> createState() => _MorphingContentState();
}
class _MorphingContentState extends State<_MorphingContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _morphAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.morphDuration,
      vsync: this,
    );
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.morphCurve,
    ));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onMorphComplete?.call();
      }
    });
    if (widget.showContent) {
      _controller.forward();
    }
  }
  @override
  void didUpdateWidget(_MorphingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showContent != oldWidget.showContent) {
      if (widget.showContent) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Opacity(
              opacity: 1.0 - _morphAnimation.value,
              child: Transform.scale(
                scale: 1.0 - (_morphAnimation.value * 0.1),
                child: widget.placeholderWidget,
              ),
            ),
            Opacity(
              opacity: _morphAnimation.value,
              child: Transform.scale(
                scale: 0.9 + (_morphAnimation.value * 0.1),
                child: widget.contentWidget,
              ),
            ),
          ],
        );
      },
    );
  }
}