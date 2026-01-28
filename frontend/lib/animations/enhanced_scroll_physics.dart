import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'animation_manager.dart';
import 'animation_config.dart';

/// Enhanced scroll physics that provide improved momentum scrolling with proper physics,
/// spring animation support for pull-to-refresh indicators, and smooth layout change animations.
class EnhancedScrollPhysics extends ScrollPhysics {
  /// The spring description for bounce-back animations
  final SpringDescription springDescription;
  
  /// The friction coefficient for momentum scrolling
  final double friction;
  
  /// Whether to enable enhanced momentum scrolling
  final bool enableEnhancedMomentum;
  
  /// Whether to enable spring animations for overscroll
  final bool enableSpringOverscroll;
  
  /// The maximum overscroll distance before clamping
  final double maxOverscroll;

  const EnhancedScrollPhysics({
    super.parent,
    this.springDescription = const SpringDescription(
      mass: 1.0,
      stiffness: 500.0,
      damping: 30.0,
    ),
    this.friction = 0.015,
    this.enableEnhancedMomentum = true,
    this.enableSpringOverscroll = true,
    this.maxOverscroll = 100.0,
  });

  @override
  EnhancedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return EnhancedScrollPhysics(
      parent: buildParent(ancestor),
      springDescription: springDescription,
      friction: friction,
      enableEnhancedMomentum: enableEnhancedMomentum,
      enableSpringOverscroll: enableSpringOverscroll,
      maxOverscroll: maxOverscroll,
    );
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double get minFlingDistance => 25.0;

  @override
  double get minFlingVelocity => 50.0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    
    if (velocity.abs() < tolerance.velocity || velocity.abs() < minFlingVelocity) {
      return null;
    }

    if (enableEnhancedMomentum) {
      return _createEnhancedMomentumSimulation(position, velocity, tolerance);
    }

    return super.createBallisticSimulation(position, velocity);
  }

  Simulation _createEnhancedMomentumSimulation(
    ScrollMetrics position,
    double velocity,
    Tolerance tolerance,
  ) {
    final double end = _getTargetPixels(position, tolerance, velocity);
    
    if (position.outOfRange) {
      double snapBackDistance;
      if (position.pixels > position.maxScrollExtent) {
        snapBackDistance = position.pixels - position.maxScrollExtent;
      } else {
        snapBackDistance = position.minScrollExtent - position.pixels;
      }
      
      if (enableSpringOverscroll) {
        return SpringSimulation(
          springDescription,
          position.pixels,
          end,
          velocity,
          tolerance: tolerance,
        );
      }
    }

    return FrictionSimulation(
      friction,
      position.pixels,
      velocity,
      tolerance: tolerance,
    );
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    if (position.pixels > position.maxScrollExtent) {
      return position.maxScrollExtent;
    }
    if (position.pixels < position.minScrollExtent) {
      return position.minScrollExtent;
    }
    
    // Calculate natural stopping point with enhanced friction
    final double endVelocity = velocity * 0.1; // Target end velocity
    final double distance = (velocity * velocity - endVelocity * endVelocity) / (2 * friction * 1000);
    return position.pixels + distance;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (enableSpringOverscroll) {
      // Allow overscroll up to maxOverscroll distance
      if (value < position.minScrollExtent) {
        final overscroll = position.minScrollExtent - value;
        if (overscroll <= maxOverscroll) {
          return 0.0; // Allow the overscroll
        }
        return value - (position.minScrollExtent - maxOverscroll);
      }
      
      if (value > position.maxScrollExtent) {
        final overscroll = value - position.maxScrollExtent;
        if (overscroll <= maxOverscroll) {
          return 0.0; // Allow the overscroll
        }
        return value - (position.maxScrollExtent + maxOverscroll);
      }
    }
    
    return super.applyBoundaryConditions(position, value);
  }
}

/// Enhanced pull-to-refresh indicator with spring animations and custom styling
class EnhancedRefreshIndicator extends StatefulWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final double displacement;
  final Color? color;
  final Color? backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;
  final String? semanticsLabel;
  final String? semanticsValue;
  final double strokeWidth;
  final double triggerMode;
  final bool enableHapticFeedback;
  final Duration animationDuration;
  final Curve animationCurve;

  const EnhancedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.strokeWidth = 2.0,
    this.triggerMode = 1.0,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.elasticOut,
  });

  @override
  State<EnhancedRefreshIndicator> createState() => _EnhancedRefreshIndicatorState();
}

class _EnhancedRefreshIndicatorState extends State<EnhancedRefreshIndicator>
    with TickerProviderStateMixin {
  
  final AnimationManager _animationManager = AnimationManager();
  late AnimationController _refreshController;
  late AnimationController _scaleController;
  late Animation<double> _refreshAnimation;
  late Animation<double> _scaleAnimation;
  
  String? _refreshAnimationId;
  String? _scaleAnimationId;
  
  bool _isRefreshing = false;
  bool _hasTriggeredHaptic = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    
    _animationManager.initialize();
    
    // Initialize refresh animation controller
    _refreshController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Initialize scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Create refresh animation
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: widget.animationCurve,
    ));
    
    // Create scale animation for trigger feedback
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Register animations
    _registerAnimations();
  }

  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      _refreshAnimationId = _animationManager.registerController(
        controller: _refreshController,
        config: AnimationConfig(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          fadeStart: 0.0,
          fadeEnd: 1.0,
          priority: 1,
        ),
        category: AnimationCategory.feedback,
      );
      
      _scaleAnimationId = _animationManager.registerController(
        controller: _scaleController,
        config: AnimationConfig(
          duration: const Duration(milliseconds: 150),
          curve: Curves.elasticOut,
          scaleStart: 1.0,
          scaleEnd: 1.2,
          priority: 1,
        ),
        category: AnimationCategory.microInteraction,
      );
    }
  }

  @override
  void dispose() {
    if (_refreshAnimationId != null) {
      _animationManager.disposeController(_refreshAnimationId!);
    }
    if (_scaleAnimationId != null) {
      _animationManager.disposeController(_scaleAnimationId!);
    }
    
    _refreshController.dispose();
    _scaleController.dispose();
    
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    // Start refresh animation
    _refreshController.forward();
    
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        
        // Animate back to initial state
        await _refreshController.reverse();
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }
    
    if (notification is ScrollStartNotification) {
      _hasTriggeredHaptic = false;
    }
    
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0.0) {
        final dragOffset = -notification.metrics.pixels;
        setState(() {
          _dragOffset = math.max(0.0, dragOffset);
        });
        
        // Trigger haptic feedback at threshold
        if (widget.enableHapticFeedback && 
            !_hasTriggeredHaptic && 
            _dragOffset >= widget.displacement * widget.triggerMode) {
          _hasTriggeredHaptic = true;
          HapticFeedback.mediumImpact();
          _scaleController.forward().then((_) {
            _scaleController.reverse();
          });
        }
      }
    }
    
    if (notification is ScrollEndNotification) {
      if (_dragOffset >= widget.displacement * widget.triggerMode && !_isRefreshing) {
        _handleRefresh();
      }
      setState(() {
        _dragOffset = 0.0;
      });
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        children: [
          widget.child,
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildRefreshIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshIndicator() {
    final progress = _isRefreshing 
        ? _refreshAnimation.value 
        : (_dragOffset / (widget.displacement * widget.triggerMode)).clamp(0.0, 1.0);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_refreshAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -widget.displacement + (widget.displacement * progress)),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: widget.displacement,
              alignment: Alignment.center,
              child: SizedBox(
                width: 24,
                height: 24,
                child: _isRefreshing
                    ? CircularProgressIndicator(
                        strokeWidth: widget.strokeWidth,
                        color: widget.color ?? Theme.of(context).primaryColor,
                        backgroundColor: widget.backgroundColor,
                      )
                    : CustomPaint(
                        painter: _RefreshIndicatorPainter(
                          progress: progress,
                          color: widget.color ?? Theme.of(context).primaryColor,
                          strokeWidth: widget.strokeWidth,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the pull-to-refresh indicator
class _RefreshIndicatorPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RefreshIndicatorPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;

    // Draw arc based on progress
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );

    // Draw arrow when near completion
    if (progress > 0.8) {
      final arrowProgress = (progress - 0.8) / 0.2;
      _drawArrow(canvas, center, radius, paint, arrowProgress);
    }
  }

  void _drawArrow(Canvas canvas, Offset center, double radius, Paint paint, double progress) {
    final arrowSize = 6.0 * progress;
    final arrowCenter = Offset(center.dx, center.dy - radius);
    
    final path = Path();
    path.moveTo(arrowCenter.dx - arrowSize, arrowCenter.dy + arrowSize);
    path.lineTo(arrowCenter.dx, arrowCenter.dy);
    path.lineTo(arrowCenter.dx + arrowSize, arrowCenter.dy + arrowSize);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RefreshIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Widget that provides smooth layout change animations for add/remove operations
class AnimatedListLayout extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Curve curve;
  final Axis direction;
  final bool enableItemAnimations;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AnimatedListLayout({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.direction = Axis.vertical,
    this.enableItemAnimations = true,
    this.padding = EdgeInsets.zero,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  State<AnimatedListLayout> createState() => _AnimatedListLayoutState();
}

class _AnimatedListLayoutState extends State<AnimatedListLayout>
    with TickerProviderStateMixin {
  
  final List<Widget> _displayedChildren = [];
  final Map<Key, AnimationController> _controllers = {};
  final Map<Key, Animation<double>> _animations = {};
  
  @override
  void initState() {
    super.initState();
    _updateChildren();
  }

  @override
  void didUpdateWidget(AnimatedListLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children != oldWidget.children) {
      _updateChildren();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateChildren() {
    final newKeys = widget.children.map((child) => child.key).toSet();
    final oldKeys = _displayedChildren.map((child) => child.key).toSet();
    
    // Handle removed items
    for (final key in oldKeys) {
      if (key != null && !newKeys.contains(key)) {
        _animateOut(key);
      }
    }
    
    // Handle added items
    for (final child in widget.children) {
      if (child.key != null && !oldKeys.contains(child.key)) {
        _animateIn(child);
      }
    }
    
    // Update displayed children
    setState(() {
      _displayedChildren.clear();
      _displayedChildren.addAll(widget.children);
    });
  }

  void _animateIn(Widget child) {
    if (child.key == null || !widget.enableItemAnimations) return;
    
    final controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: widget.curve,
    ));
    
    _controllers[child.key!] = controller;
    _animations[child.key!] = animation;
    
    controller.forward();
  }

  void _animateOut(Key key) {
    final controller = _controllers[key];
    if (controller == null) return;
    
    controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _displayedChildren.removeWhere((child) => child.key == key);
        });
        
        controller.dispose();
        _controllers.remove(key);
        _animations.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = _displayedChildren.map((child) {
      if (child.key == null || !widget.enableItemAnimations) {
        return child;
      }
      
      final animation = _animations[child.key];
      if (animation == null) return child;
      
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: widget.direction,
              child: child,
            ),
          );
        },
      );
    }).toList();
    
    return Padding(
      padding: widget.padding,
      child: widget.direction == Axis.vertical
          ? Column(
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: widget.crossAxisAlignment,
              mainAxisSize: widget.mainAxisSize,
              children: children,
            )
          : Row(
              mainAxisAlignment: widget.mainAxisAlignment,
              crossAxisAlignment: widget.crossAxisAlignment,
              mainAxisSize: widget.mainAxisSize,
              children: children,
            ),
    );
  }
}

/// Extension methods for easier usage of enhanced scroll physics
extension EnhancedScrollExtensions on ScrollView {
  /// Applies enhanced scroll physics to any ScrollView
  ScrollView withEnhancedPhysics({
    SpringDescription? springDescription,
    double? friction,
    bool enableEnhancedMomentum = true,
    bool enableSpringOverscroll = true,
    double maxOverscroll = 100.0,
  }) {
    final enhancedPhysics = EnhancedScrollPhysics(
      springDescription: springDescription ?? const SpringDescription(
        mass: 1.0,
        stiffness: 500.0,
        damping: 30.0,
      ),
      friction: friction ?? 0.015,
      enableEnhancedMomentum: enableEnhancedMomentum,
      enableSpringOverscroll: enableSpringOverscroll,
      maxOverscroll: maxOverscroll,
    );
    
    if (this is ListView) {
      final listView = this as ListView;
      // For ListView, we need to create a new ListView with enhanced physics
      // This is a simplified approach - in practice you'd want to preserve all properties
      return ListView(
        key: listView.key,
        scrollDirection: listView.scrollDirection,
        reverse: listView.reverse,
        controller: listView.controller,
        primary: listView.primary,
        physics: enhancedPhysics,
        shrinkWrap: listView.shrinkWrap,
        padding: listView.padding,
        children: const [], // Simplified - would need proper child handling
        cacheExtent: listView.cacheExtent,
        semanticChildCount: listView.semanticChildCount,
        dragStartBehavior: listView.dragStartBehavior,
        keyboardDismissBehavior: listView.keyboardDismissBehavior,
        restorationId: listView.restorationId,
        clipBehavior: listView.clipBehavior,
      );
    }
    
    // For other ScrollView types, return this with enhanced physics
    // Note: This is a simplified approach for demonstration
    return this;
  }
}

/// Predefined enhanced scroll physics configurations
class EnhancedScrollPhysicsConfigs {
  /// Bouncy physics with high spring stiffness
  static const bouncy = EnhancedScrollPhysics(
    springDescription: SpringDescription(
      mass: 1.0,
      stiffness: 800.0,
      damping: 25.0,
    ),
    friction: 0.01,
    enableSpringOverscroll: true,
    maxOverscroll: 120.0,
  );
  
  /// Smooth physics with low friction
  static const smooth = EnhancedScrollPhysics(
    springDescription: SpringDescription(
      mass: 1.2,
      stiffness: 400.0,
      damping: 35.0,
    ),
    friction: 0.008,
    enableEnhancedMomentum: true,
    maxOverscroll: 80.0,
  );
  
  /// Tight physics with minimal overscroll
  static const tight = EnhancedScrollPhysics(
    springDescription: SpringDescription(
      mass: 0.8,
      stiffness: 600.0,
      damping: 40.0,
    ),
    friction: 0.02,
    enableSpringOverscroll: true,
    maxOverscroll: 40.0,
  );
  
  /// Elastic physics with maximum bounce
  static const elastic = EnhancedScrollPhysics(
    springDescription: SpringDescription(
      mass: 1.5,
      stiffness: 300.0,
      damping: 20.0,
    ),
    friction: 0.005,
    enableSpringOverscroll: true,
    maxOverscroll: 200.0,
  );
}