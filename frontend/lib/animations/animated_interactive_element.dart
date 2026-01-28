import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_manager.dart';
import 'animation_config.dart';
import 'theme_integration.dart';

/// A wrapper widget that provides consistent interactive feedback for any child widget.
/// 
/// This widget implements the following animations:
/// - Scale-down animation on tap with 150ms duration
/// - Elastic curve animation for release with proper timing
/// - Haptic feedback integration for long-press gestures
/// - Hover state support for desktop/web platforms
/// 
/// The widget integrates with the AnimationManager for performance optimization
/// and respects accessibility preferences for reduced motion.
class AnimatedInteractiveElement extends StatefulWidget {
  /// The child widget to wrap with interactive animations
  final Widget child;
  
  /// Callback when the element is tapped
  final VoidCallback? onTap;
  
  /// Callback when the element is long-pressed
  final VoidCallback? onLongPress;
  
  /// Duration for the scale-down animation (default: 150ms)
  final Duration tapDuration;
  
  /// Duration for the release animation (default: 200ms)
  final Duration releaseDuration;
  
  /// Curve for the tap animation (default: easeInOut)
  final Curve tapCurve;
  
  /// Curve for the release animation (default: elasticOut)
  final Curve releaseCurve;
  
  /// Scale factor when pressed (default: 0.95)
  final double scaleDown;
  
  /// Whether to enable haptic feedback on long press (default: true)
  final bool enableHaptics;
  
  /// Whether to enable hover effects on supported platforms (default: true)
  final bool enableHover;
  
  /// Custom highlight color for hover/press states
  final Color? highlightColor;
  
  /// Custom splash color for press feedback
  final Color? splashColor;
  
  /// Border radius for the interactive area
  final BorderRadius? borderRadius;
  
  /// Whether the element should be semantically treated as a button
  final bool semanticButton;
  
  /// Semantic label for accessibility
  final String? semanticLabel;
  
  /// Priority for animation performance management (1 = highest, 5 = lowest)
  final int animationPriority;

  const AnimatedInteractiveElement({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.tapDuration = const Duration(milliseconds: 150),
    this.releaseDuration = const Duration(milliseconds: 200),
    this.tapCurve = Curves.easeInOut,
    this.releaseCurve = Curves.elasticOut,
    this.scaleDown = 0.95,
    this.enableHaptics = true,
    this.enableHover = true,
    this.highlightColor,
    this.splashColor,
    this.borderRadius,
    this.semanticButton = true,
    this.semanticLabel,
    this.animationPriority = 1,
  }) : super(key: key);

  @override
  State<AnimatedInteractiveElement> createState() => _AnimatedInteractiveElementState();
}

class _AnimatedInteractiveElementState extends State<AnimatedInteractiveElement>
    with TickerProviderStateMixin {
  
  late final AnimationManager _animationManager;
  
  // Animation controllers and IDs
  late AnimationController _scaleController;
  late AnimationController _hoverController;
  String? _scaleAnimationId;
  String? _hoverAnimationId;
  
  // Animation values
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverAnimation;
  
  // State tracking
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _animationManager = AnimationManager();
    
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Initialize scale animation controller
    _scaleController = AnimationController(
      duration: widget.tapDuration,
      vsync: this,
    );
    
    // Initialize hover animation controller
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Register animations with the manager if it's initialized
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
      // Initialize the manager and then register animations
      _animationManager.initialize().then((_) {
        if (mounted) {
          _registerAnimations();
        }
      });
    }
    
    // Create local animations as fallback
    _createLocalAnimations();
  }

  void _registerAnimations() {
    try {
      // Register scale animation
      final scaleConfig = AnimationConfig(
        duration: widget.tapDuration,
        curve: widget.tapCurve,
        scaleStart: 1.0,
        scaleEnd: widget.scaleDown,
        priority: widget.animationPriority,
      );
      
      _scaleAnimationId = _animationManager.registerController(
        controller: _scaleController,
        config: scaleConfig,
        category: AnimationCategory.microInteraction,
      );
      
      // Register hover animation
      final hoverConfig = AnimationConfig(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        scaleStart: 1.0,
        scaleEnd: 1.02,
        priority: widget.animationPriority + 1,
      );
      
      _hoverAnimationId = _animationManager.registerController(
        controller: _hoverController,
        config: hoverConfig,
        category: AnimationCategory.microInteraction,
      );
      
      // Get the managed animations
      final scaleAnim = _animationManager.getAnimation(_scaleAnimationId!);
      final hoverAnim = _animationManager.getAnimation(_hoverAnimationId!);
      
      if (scaleAnim != null && hoverAnim != null) {
        _scaleAnimation = scaleAnim.animation as Animation<double>;
        _hoverAnimation = hoverAnim.animation as Animation<double>;
      } else {
        // Fallback to local animations
        _createLocalAnimations();
      }
    } catch (e) {
      // Fallback to local animations if registration fails
      debugPrint('Failed to register animations with manager: $e');
      _createLocalAnimations();
    }
  }

  void _createLocalAnimations() {
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.tapCurve,
    ));
    
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // Dispose animations through manager if registered
    if (_scaleAnimationId != null) {
      _animationManager.disposeController(_scaleAnimationId!);
    }
    if (_hoverAnimationId != null) {
      _animationManager.disposeController(_hoverAnimationId!);
    }
    
    // Dispose controllers
    _scaleController.dispose();
    _hoverController.dispose();
    
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    
    // Start scale-down animation
    _scaleController.duration = widget.tapDuration;
    
    if (_scaleAnimationId != null) {
      _animationManager.startAnimation(_scaleAnimationId!);
    } else {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    
    _handleRelease();
  }

  void _handleTapCancel() {
    if (!mounted) return;
    
    _handleRelease();
  }

  void _handleRelease() {
    // Start release animation with elastic curve
    _scaleController.duration = widget.releaseDuration;
    
    // Create a new animation with the release curve
    final releaseAnimation = Tween<double>(
      begin: widget.scaleDown,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.releaseCurve,
    ));
    
    // Reset controller and animate with release curve
    _scaleController.reset();
    _scaleAnimation = releaseAnimation;
    _scaleController.forward();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handleLongPress() {
    if (!mounted) return;
    
    // Provide haptic feedback for long press
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    
    if (widget.onLongPress != null) {
      widget.onLongPress!();
    }
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (!widget.enableHover || !mounted) return;
    
    setState(() {
      _isHovered = true;
    });
    
    if (_hoverAnimationId != null) {
      _animationManager.startAnimation(_hoverAnimationId!);
    } else {
      _hoverController.forward();
    }
  }

  void _handleHoverExit(PointerExitEvent event) {
    if (!widget.enableHover || !mounted) return;
    
    setState(() {
      _isHovered = false;
    });
    
    _hoverController.reverse();
  }

  Color _getHighlightColor(BuildContext context) {
    if (widget.highlightColor != null) {
      return widget.highlightColor!;
    }
    
    return AnimationTheme.getAnimationOverlayColor(context);
  }

  Color _getSplashColor(BuildContext context) {
    if (widget.splashColor != null) {
      return widget.splashColor!;
    }
    
    return AnimationTheme.getPrimaryAnimationColor(context).withValues(alpha: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    
    // Apply scale animation
    child = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        double scale = _scaleAnimation.value;
        
        // Combine with hover animation if enabled
        if (widget.enableHover) {
          return AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              final hoverScale = _isHovered ? _hoverAnimation.value : 1.0;
              final combinedScale = scale * hoverScale;
              
              return Transform.scale(
                scale: combinedScale,
                child: child,
              );
            },
            child: child,
          );
        }
        
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
    
    // Wrap with gesture detection and material feedback
    child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap != null ? _handleTap : null,
        onLongPress: widget.onLongPress != null ? _handleLongPress : null,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        highlightColor: _getHighlightColor(context),
        splashColor: _getSplashColor(context),
        borderRadius: widget.borderRadius,
        child: child,
      ),
    );
    
    // Add hover detection for desktop/web platforms
    if (widget.enableHover) {
      child = MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        child: child,
      );
    }
    
    // Add semantic information for accessibility
    if (widget.semanticButton) {
      child = Semantics(
        button: true,
        label: widget.semanticLabel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: child,
      );
    }
    
    return child;
  }
}

/// Extension methods for easier usage of AnimatedInteractiveElement
extension AnimatedInteractiveElementExtensions on Widget {
  /// Wraps this widget with AnimatedInteractiveElement using default settings
  Widget asInteractive({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enableHaptics = true,
    bool enableHover = true,
    double scaleDown = 0.95,
    Color? highlightColor,
    Color? splashColor,
    BorderRadius? borderRadius,
    String? semanticLabel,
  }) {
    return AnimatedInteractiveElement(
      onTap: onTap,
      onLongPress: onLongPress,
      enableHaptics: enableHaptics,
      enableHover: enableHover,
      scaleDown: scaleDown,
      highlightColor: highlightColor,
      splashColor: splashColor,
      borderRadius: borderRadius,
      semanticLabel: semanticLabel,
      child: this,
    );
  }
  
  /// Wraps this widget with AnimatedInteractiveElement using button-like settings
  Widget asInteractiveButton({
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool enableHaptics = true,
    double scaleDown = 0.95,
    BorderRadius? borderRadius,
    String? semanticLabel,
  }) {
    return AnimatedInteractiveElement(
      onTap: onTap,
      onLongPress: onLongPress,
      enableHaptics: enableHaptics,
      enableHover: true,
      scaleDown: scaleDown,
      borderRadius: borderRadius,
      semanticLabel: semanticLabel,
      animationPriority: 1, // High priority for buttons
      child: this,
    );
  }
  
  /// Wraps this widget with AnimatedInteractiveElement using card-like settings
  Widget asInteractiveCard({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enableHaptics = false,
    double scaleDown = 0.98,
    BorderRadius? borderRadius,
    String? semanticLabel,
  }) {
    return AnimatedInteractiveElement(
      onTap: onTap,
      onLongPress: onLongPress,
      enableHaptics: enableHaptics,
      enableHover: true,
      scaleDown: scaleDown,
      borderRadius: borderRadius,
      semanticLabel: semanticLabel,
      animationPriority: 2, // Medium priority for cards
      child: this,
    );
  }
  
  /// Wraps this widget with AnimatedInteractiveElement using list item settings
  Widget asInteractiveListItem({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enableHaptics = false,
    double scaleDown = 0.99,
    String? semanticLabel,
  }) {
    return AnimatedInteractiveElement(
      onTap: onTap,
      onLongPress: onLongPress,
      enableHaptics: enableHaptics,
      enableHover: true,
      scaleDown: scaleDown,
      semanticLabel: semanticLabel,
      animationPriority: 3, // Lower priority for list items
      child: this,
    );
  }
}