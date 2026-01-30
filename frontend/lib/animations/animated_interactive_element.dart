import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_manager.dart';
import 'animation_config.dart';
import 'theme_integration.dart';
class AnimatedInteractiveElement extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration tapDuration;
  final Duration releaseDuration;
  final Curve tapCurve;
  final Curve releaseCurve;
  final double scaleDown;
  final bool enableHaptics;
  final bool enableHover;
  final Color? highlightColor;
  final Color? splashColor;
  final BorderRadius? borderRadius;
  final bool semanticButton;
  final String? semanticLabel;
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
  late AnimationController _scaleController;
  late AnimationController _hoverController;
  String? _scaleAnimationId;
  String? _hoverAnimationId;
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverAnimation;
  bool _isFocused = false;
  bool _isHovered = false;
  @override
  void initState() {
    super.initState();
    _animationManager = AnimationManager();
    _initializeAnimations();
  }
  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: widget.tapDuration,
      vsync: this,
    );
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
      _animationManager.initialize().then((_) {
        if (mounted) {
          _registerAnimations();
        }
      });
    }
    _createLocalAnimations();
  }
  void _registerAnimations() {
    try {
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
      final scaleAnim = _animationManager.getAnimation(_scaleAnimationId!);
      final hoverAnim = _animationManager.getAnimation(_hoverAnimationId!);
      if (scaleAnim != null && hoverAnim != null) {
        _scaleAnimation = scaleAnim.animation as Animation<double>;
        _hoverAnimation = hoverAnim.animation as Animation<double>;
      } else {
        _createLocalAnimations();
      }
    } catch (e) {
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
    if (_scaleAnimationId != null) {
      _animationManager.disposeController(_scaleAnimationId!);
    }
    if (_hoverAnimationId != null) {
      _animationManager.disposeController(_hoverAnimationId!);
    }
    _scaleController.dispose();
    _hoverController.dispose();
    super.dispose();
  }
  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
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
    _scaleController.duration = widget.releaseDuration;
    final releaseAnimation = Tween<double>(
      begin: widget.scaleDown,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.releaseCurve,
    ));
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
    child = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        double scale = _scaleAnimation.value;
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
    if (widget.enableHover) {
      child = MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        child: child,
      );
    }
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
extension AnimatedInteractiveElementExtensions on Widget {
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