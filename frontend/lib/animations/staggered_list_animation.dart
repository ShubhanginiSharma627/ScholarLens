import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'animation_manager.dart';
import 'animation_config.dart';

/// A widget that provides staggered animations for list items with customizable
/// timing, direction, and animation effects.
/// 
/// This widget implements:
/// - Staggered item appearance with 50ms delays
/// - Support for both vertical and horizontal staggering
/// - Customizable duration and curve options
/// - Integration with AnimationManager for performance optimization
/// - Accessibility compliance with reduced motion support
class StaggeredListAnimation extends StatefulWidget {
  /// The list of child widgets to animate
  final List<Widget> children;
  
  /// Delay between each item animation start
  final Duration staggerDelay;
  
  /// Duration for each individual item animation
  final Duration itemDuration;
  
  /// Animation curve for item animations
  final Curve curve;
  
  /// Direction of staggering (vertical or horizontal)
  final Axis direction;
  
  /// Whether to animate items on first build or wait for trigger
  final bool autoStart;
  
  /// Whether to reverse the stagger order (last item first)
  final bool reverse;
  
  /// Type of animation to apply to items
  final StaggerAnimationType animationType;
  
  /// Distance for slide animations
  final double slideDistance;
  
  /// Scale factor for scale animations
  final double scaleStart;
  
  /// Rotation angle for rotation animations (in radians)
  final double rotationAngle;
  
  /// Whether to enable viewport-based triggering
  final bool triggerOnVisible;
  
  /// Threshold for viewport triggering (0.0 to 1.0)
  final double visibilityThreshold;
  
  /// Callback when all animations complete
  final VoidCallback? onComplete;
  
  /// Priority for animation performance management
  final int animationPriority;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.direction = Axis.vertical,
    this.autoStart = true,
    this.reverse = false,
    this.animationType = StaggerAnimationType.fadeSlide,
    this.slideDistance = 30.0,
    this.scaleStart = 0.8,
    this.rotationAngle = 0.1,
    this.triggerOnVisible = false,
    this.visibilityThreshold = 0.3,
    this.onComplete,
    this.animationPriority = 2,
  });

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with TickerProviderStateMixin {
  
  final AnimationManager _animationManager = AnimationManager();
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];
  final List<Animation<double>> _rotationAnimations = [];
  final List<String> _animationIds = [];
  
  bool _hasStarted = false;
  int _completedAnimations = 0;

  @override
  void initState() {
    super.initState();
    
    _animationManager.initialize();
    _initializeAnimations();
    
    if (widget.autoStart && !widget.triggerOnVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimations();
      });
    }
  }

  void _initializeAnimations() {
    // Clear existing animations
    _disposeAnimations();
    
    // Create animation controllers for each child
    for (int i = 0; i < widget.children.length; i++) {
      final controller = AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      );
      
      // Create fade animation
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
      
      // Create slide animation based on direction
      final slideOffset = _getSlideOffset();
      final slideAnimation = Tween<Offset>(
        begin: slideOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
      
      // Create scale animation
      final scaleAnimation = Tween<double>(
        begin: widget.scaleStart,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
      
      // Create rotation animation
      final rotationAnimation = Tween<double>(
        begin: widget.rotationAngle,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
      
      _controllers.add(controller);
      _fadeAnimations.add(fadeAnimation);
      _slideAnimations.add(slideAnimation);
      _scaleAnimations.add(scaleAnimation);
      _rotationAnimations.add(rotationAnimation);
      
      // Listen for animation completion
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedAnimations++;
          if (_completedAnimations == widget.children.length) {
            widget.onComplete?.call();
          }
        }
      });
    }
    
    // Register animations with manager
    _registerAnimations();
  }

  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      for (int i = 0; i < _controllers.length; i++) {
        final config = AnimationConfigs.listItemStagger.copyWith(
          duration: widget.itemDuration,
          curve: widget.curve,
          priority: widget.animationPriority,
        );
        
        final animationId = _animationManager.registerController(
          controller: _controllers[i],
          config: config,
          category: AnimationCategory.content,
        );
        
        _animationIds.add(animationId);
      }
    }
  }

  Offset _getSlideOffset() {
    switch (widget.direction) {
      case Axis.vertical:
        return Offset(0.0, widget.slideDistance / 100);
      case Axis.horizontal:
        return Offset(widget.slideDistance / 100, 0.0);
    }
  }

  @override
  void didUpdateWidget(StaggeredListAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reinitialize if children changed
    if (widget.children.length != oldWidget.children.length) {
      _initializeAnimations();
      
      if (widget.autoStart && !widget.triggerOnVisible) {
        _startAnimations();
      }
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  void _disposeAnimations() {
    // Dispose through animation manager
    for (final animationId in _animationIds) {
      _animationManager.disposeController(animationId);
    }
    _animationIds.clear();
    
    // Dispose controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    _fadeAnimations.clear();
    _slideAnimations.clear();
    _scaleAnimations.clear();
    _rotationAnimations.clear();
    
    _completedAnimations = 0;
  }

  void _startAnimations() {
    if (_hasStarted || !mounted) return;
    _hasStarted = true;
    _completedAnimations = 0;
    
    final indices = widget.reverse 
        ? List.generate(widget.children.length, (i) => widget.children.length - 1 - i)
        : List.generate(widget.children.length, (i) => i);
    
    for (int i = 0; i < indices.length; i++) {
      final index = indices[i];
      final delay = widget.staggerDelay * i;
      
      Future.delayed(delay, () {
        if (mounted && index < _controllers.length) {
          if (_animationIds.isNotEmpty && index < _animationIds.length) {
            _animationManager.startAnimation(_animationIds[index]);
          } else {
            _controllers[index].forward();
          }
        }
      });
    }
  }

  void _resetAnimations() {
    _hasStarted = false;
    _completedAnimations = 0;
    
    for (final controller in _controllers) {
      controller.reset();
    }
  }

  /// Manually trigger the stagger animation
  void startAnimation() {
    _resetAnimations();
    _startAnimations();
  }

  /// Reset all animations to initial state
  void resetAnimation() {
    _resetAnimations();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.triggerOnVisible) {
      return _buildWithVisibilityTrigger();
    }
    
    return _buildAnimatedList();
  }

  Widget _buildWithVisibilityTrigger() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Check if widget is visible and trigger animation
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null && !_hasStarted) {
              final position = renderBox.localToGlobal(Offset.zero);
              final screenHeight = MediaQuery.of(context).size.height;
              final visibleHeight = screenHeight - position.dy;
              final threshold = renderBox.size.height * widget.visibilityThreshold;
              
              if (visibleHeight >= threshold) {
                _startAnimations();
              }
            }
            return false;
          },
          child: _buildAnimatedList(),
        );
      },
    );
  }

  Widget _buildAnimatedList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.children.length, (index) {
        if (index >= _controllers.length) {
          return widget.children[index];
        }
        
        return _buildAnimatedItem(index);
      }),
    );
  }

  Widget _buildAnimatedItem(int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimations[index],
        _slideAnimations[index],
        _scaleAnimations[index],
        _rotationAnimations[index],
      ]),
      builder: (context, child) {
        Widget animatedChild = widget.children[index];
        
        // Apply animations based on type
        switch (widget.animationType) {
          case StaggerAnimationType.fade:
            animatedChild = FadeTransition(
              opacity: _fadeAnimations[index],
              child: animatedChild,
            );
            break;
            
          case StaggerAnimationType.slide:
            animatedChild = SlideTransition(
              position: _slideAnimations[index],
              child: animatedChild,
            );
            break;
            
          case StaggerAnimationType.scale:
            animatedChild = ScaleTransition(
              scale: _scaleAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: animatedChild,
              ),
            );
            break;
            
          case StaggerAnimationType.rotation:
            animatedChild = Transform.rotate(
              angle: _rotationAnimations[index].value,
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: animatedChild,
              ),
            );
            break;
            
          case StaggerAnimationType.fadeSlide:
          default:
            animatedChild = FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: animatedChild,
              ),
            );
            break;
            
          case StaggerAnimationType.scaleSlide:
            animatedChild = ScaleTransition(
              scale: _scaleAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: animatedChild,
                ),
              ),
            );
            break;
            
          case StaggerAnimationType.all:
            animatedChild = Transform.rotate(
              angle: _rotationAnimations[index].value,
              child: ScaleTransition(
                scale: _scaleAnimations[index],
                child: FadeTransition(
                  opacity: _fadeAnimations[index],
                  child: SlideTransition(
                    position: _slideAnimations[index],
                    child: animatedChild,
                  ),
                ),
              ),
            );
            break;
        }
        
        return animatedChild;
      },
    );
  }
}

/// Types of stagger animations available
enum StaggerAnimationType {
  fade,
  slide,
  scale,
  rotation,
  fadeSlide,
  scaleSlide,
  all,
}

/// Extension methods for easier usage of StaggeredListAnimation
extension StaggeredListAnimationExtensions on List<Widget> {
  /// Creates a staggered list animation with default settings
  Widget asStaggeredList({
    Duration staggerDelay = const Duration(milliseconds: 50),
    Duration itemDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    Axis direction = Axis.vertical,
    bool autoStart = true,
    bool reverse = false,
    StaggerAnimationType animationType = StaggerAnimationType.fadeSlide,
    double slideDistance = 30.0,
    double scaleStart = 0.8,
    double rotationAngle = 0.1,
    bool triggerOnVisible = false,
    double visibilityThreshold = 0.3,
    VoidCallback? onComplete,
    int animationPriority = 2,
  }) {
    return StaggeredListAnimation(
      staggerDelay: staggerDelay,
      itemDuration: itemDuration,
      curve: curve,
      direction: direction,
      autoStart: autoStart,
      reverse: reverse,
      animationType: animationType,
      slideDistance: slideDistance,
      scaleStart: scaleStart,
      rotationAngle: rotationAngle,
      triggerOnVisible: triggerOnVisible,
      visibilityThreshold: visibilityThreshold,
      onComplete: onComplete,
      animationPriority: animationPriority,
      children: this,
    );
  }
  
  /// Creates a fast staggered list animation
  Widget asStaggeredListFast({
    StaggerAnimationType animationType = StaggerAnimationType.fadeSlide,
    Axis direction = Axis.vertical,
    bool autoStart = true,
    VoidCallback? onComplete,
  }) {
    return asStaggeredList(
      staggerDelay: const Duration(milliseconds: 25),
      itemDuration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      direction: direction,
      autoStart: autoStart,
      animationType: animationType,
      onComplete: onComplete,
    );
  }
  
  /// Creates a slow staggered list animation for dramatic effect
  Widget asStaggeredListSlow({
    StaggerAnimationType animationType = StaggerAnimationType.scaleSlide,
    Axis direction = Axis.vertical,
    bool autoStart = true,
    VoidCallback? onComplete,
  }) {
    return asStaggeredList(
      staggerDelay: const Duration(milliseconds: 100),
      itemDuration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      direction: direction,
      autoStart: autoStart,
      animationType: animationType,
      onComplete: onComplete,
    );
  }
  
  /// Creates a staggered list that triggers when visible
  Widget asStaggeredListOnVisible({
    double visibilityThreshold = 0.3,
    StaggerAnimationType animationType = StaggerAnimationType.fadeSlide,
    Axis direction = Axis.vertical,
    VoidCallback? onComplete,
  }) {
    return asStaggeredList(
      triggerOnVisible: true,
      visibilityThreshold: visibilityThreshold,
      autoStart: false,
      direction: direction,
      animationType: animationType,
      onComplete: onComplete,
    );
  }
}

/// Predefined staggered list animation configurations
class StaggeredListAnimationConfigs {
  /// Standard fade-slide animation for most lists
  static Widget standard(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      staggerDelay: const Duration(milliseconds: 50),
      itemDuration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      animationType: StaggerAnimationType.fadeSlide,
      onComplete: onComplete,
    );
  }
  
  /// Fast animation for quick loading lists
  static Widget fast(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredListFast(
      onComplete: onComplete,
    );
  }
  
  /// Dramatic animation with scale and elastic curve
  static Widget dramatic(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredListSlow(
      animationType: StaggerAnimationType.scaleSlide,
      onComplete: onComplete,
    );
  }
  
  /// Horizontal stagger for grid-like layouts
  static Widget horizontal(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      direction: Axis.horizontal,
      animationType: StaggerAnimationType.fadeSlide,
      onComplete: onComplete,
    );
  }
  
  /// Reverse order animation (last item first)
  static Widget reverse(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      reverse: true,
      animationType: StaggerAnimationType.fadeSlide,
      onComplete: onComplete,
    );
  }
  
  /// Scale-focused animation for cards
  static Widget cards(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      animationType: StaggerAnimationType.scale,
      scaleStart: 0.7,
      itemDuration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      onComplete: onComplete,
    );
  }
  
  /// Rotation animation for playful effects
  static Widget playful(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      animationType: StaggerAnimationType.all,
      rotationAngle: 0.2,
      scaleStart: 0.6,
      itemDuration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      onComplete: onComplete,
    );
  }
  
  /// Visibility-triggered animation for scroll lists
  static Widget onScroll(List<Widget> children, {
    double visibilityThreshold = 0.3,
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredListOnVisible(
      visibilityThreshold: visibilityThreshold,
      onComplete: onComplete,
    );
  }
}