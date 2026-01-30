import 'package:flutter/material.dart';
import 'animation_manager.dart';
import 'animation_config.dart';
class StaggeredListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final Axis direction;
  final bool autoStart;
  final bool reverse;
  final StaggerAnimationType animationType;
  final double slideDistance;
  final double scaleStart;
  final double rotationAngle;
  final bool triggerOnVisible;
  final double visibilityThreshold;
  final VoidCallback? onComplete;
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
    _disposeAnimations();
    for (int i = 0; i < widget.children.length; i++) {
      final controller = AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      );
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
      final slideOffset = _getSlideOffset();
      final slideAnimation = Tween<Offset>(
        begin: slideOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
      final scaleAnimation = Tween<double>(
        begin: widget.scaleStart,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
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
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedAnimations++;
          if (_completedAnimations == widget.children.length) {
            widget.onComplete?.call();
          }
        }
      });
    }
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
    for (final animationId in _animationIds) {
      _animationManager.disposeController(animationId);
    }
    _animationIds.clear();
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
  void startAnimation() {
    _resetAnimations();
    _startAnimations();
  }
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
          default:
            animatedChild = FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: animatedChild,
              ),
            );
            break;
        }
        return animatedChild;
      },
    );
  }
}
enum StaggerAnimationType {
  fade,
  slide,
  scale,
  rotation,
  fadeSlide,
  scaleSlide,
  all,
}
extension StaggeredListAnimationExtensions on List<Widget> {
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
class StaggeredListAnimationConfigs {
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
  static Widget fast(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredListFast(
      onComplete: onComplete,
    );
  }
  static Widget dramatic(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredListSlow(
      animationType: StaggerAnimationType.scaleSlide,
      onComplete: onComplete,
    );
  }
  static Widget horizontal(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      direction: Axis.horizontal,
      animationType: StaggerAnimationType.fadeSlide,
      onComplete: onComplete,
    );
  }
  static Widget reverse(List<Widget> children, {
    VoidCallback? onComplete,
  }) {
    return children.asStaggeredList(
      reverse: true,
      animationType: StaggerAnimationType.fadeSlide,
      onComplete: onComplete,
    );
  }
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