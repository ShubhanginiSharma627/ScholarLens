import 'package:flutter/material.dart';
import '../animations/animation_manager.dart';
import '../animations/animation_config.dart';

/// Animated typing indicator widget for chat interface
class ChatTypingIndicator extends StatefulWidget {
  /// Whether the typing indicator is visible
  final bool isVisible;
  
  /// Custom message to display (default: "AI is typing...")
  final String? message;
  
  /// Duration for the bounce animation of dots
  final Duration bounceDuration;
  
  /// Delay between each dot's bounce animation
  final Duration bounceDelay;
  
  /// Size of the typing dots
  final double dotSize;
  
  /// Color of the typing dots
  final Color? dotColor;
  
  /// Background color of the indicator
  final Color? backgroundColor;
  
  /// Border radius of the indicator container
  final BorderRadius? borderRadius;
  
  /// Padding inside the indicator container
  final EdgeInsets? padding;

  const ChatTypingIndicator({
    super.key,
    required this.isVisible,
    this.message,
    this.bounceDuration = const Duration(milliseconds: 600),
    this.bounceDelay = const Duration(milliseconds: 200),
    this.dotSize = 8.0,
    this.dotColor,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
  });

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with TickerProviderStateMixin {
  
  late final AnimationManager _animationManager;
  late AnimationController _fadeController;
  late AnimationController _dot1Controller;
  late AnimationController _dot2Controller;
  late AnimationController _dot3Controller;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;
  
  String? _fadeAnimationId;
  final List<String> _dotAnimationIds = [];
  
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _animationManager = AnimationManager();
    _initializeAnimations();
    
    if (widget.isVisible) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    // Initialize fade controller for show/hide
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize dot bounce controllers
    _dot1Controller = AnimationController(
      duration: widget.bounceDuration,
      vsync: this,
    );
    
    _dot2Controller = AnimationController(
      duration: widget.bounceDuration,
      vsync: this,
    );
    
    _dot3Controller = AnimationController(
      duration: widget.bounceDuration,
      vsync: this,
    );
    
    // Register animations with manager if initialized
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
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
      // Register fade animation
      final fadeConfig = AnimationConfigs.fadeTransition;
      _fadeAnimationId = _animationManager.registerController(
        controller: _fadeController,
        config: fadeConfig,
        category: AnimationCategory.feedback,
      );
      
      // Register dot bounce animations
      final bounceConfig = AnimationConfigs.typingIndicator;
      
      for (int i = 0; i < 3; i++) {
        final controller = [_dot1Controller, _dot2Controller, _dot3Controller][i];
        final animationId = _animationManager.registerController(
          controller: controller,
          config: bounceConfig,
          category: AnimationCategory.feedback,
        );
        _dotAnimationIds.add(animationId);
      }
      
      // Get managed animations
      final fadeAnim = _animationManager.getAnimation(_fadeAnimationId!);
      if (fadeAnim != null) {
        _fadeAnimation = fadeAnim.animation as Animation<double>;
      } else {
        _createLocalAnimations();
      }
      
      // Get dot animations
      if (_dotAnimationIds.length == 3) {
        final dot1Anim = _animationManager.getAnimation(_dotAnimationIds[0]);
        final dot2Anim = _animationManager.getAnimation(_dotAnimationIds[1]);
        final dot3Anim = _animationManager.getAnimation(_dotAnimationIds[2]);
        
        if (dot1Anim != null && dot2Anim != null && dot3Anim != null) {
          _dot1Animation = dot1Anim.animation as Animation<double>;
          _dot2Animation = dot2Anim.animation as Animation<double>;
          _dot3Animation = dot3Anim.animation as Animation<double>;
        } else {
          _createLocalAnimations();
        }
      } else {
        _createLocalAnimations();
      }
    } catch (e) {
      debugPrint('Failed to register typing indicator animations: $e');
      _createLocalAnimations();
    }
  }

  void _createLocalAnimations() {
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Create bouncing dot animations
    final bounceTween = Tween<double>(begin: 0.0, end: 1.0);
    final bounceCurve = CurvedAnimation(
      parent: _dot1Controller,
      curve: Curves.easeInOut,
    );
    
    _dot1Animation = bounceTween.animate(bounceCurve);
    
    _dot2Animation = bounceTween.animate(CurvedAnimation(
      parent: _dot2Controller,
      curve: Curves.easeInOut,
    ));
    
    _dot3Animation = bounceTween.animate(CurvedAnimation(
      parent: _dot3Controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(ChatTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    if (_isAnimating) return;
    _isAnimating = true;
    
    // Start fade in
    if (_fadeAnimationId != null) {
      _animationManager.startAnimation(_fadeAnimationId!);
    } else {
      _fadeController.forward();
    }
    
    // Start dot bounce animations with staggered delays
    _startDotBounceLoop();
  }

  void _startDotBounceLoop() {
    if (!mounted || !widget.isVisible) return;
    
    // Start first dot immediately
    if (_dotAnimationIds.isNotEmpty) {
      _animationManager.startAnimation(_dotAnimationIds[0]);
    } else {
      _dot1Controller.forward();
    }
    
    // Start second dot after delay
    Future.delayed(widget.bounceDelay, () {
      if (mounted && widget.isVisible) {
        if (_dotAnimationIds.length > 1) {
          _animationManager.startAnimation(_dotAnimationIds[1]);
        } else {
          _dot2Controller.forward();
        }
      }
    });
    
    // Start third dot after double delay
    Future.delayed(widget.bounceDelay * 2, () {
      if (mounted && widget.isVisible) {
        if (_dotAnimationIds.length > 2) {
          _animationManager.startAnimation(_dotAnimationIds[2]);
        } else {
          _dot3Controller.forward();
        }
      }
    });
    
    // Reset and repeat after full cycle
    Future.delayed(widget.bounceDuration + (widget.bounceDelay * 3), () {
      if (mounted && widget.isVisible) {
        _dot1Controller.reset();
        _dot2Controller.reset();
        _dot3Controller.reset();
        _startDotBounceLoop();
      }
    });
  }

  void _stopAnimations() {
    _isAnimating = false;
    
    // Fade out
    _fadeController.reverse();
    
    // Stop dot animations
    _dot1Controller.stop();
    _dot2Controller.stop();
    _dot3Controller.stop();
  }

  @override
  void dispose() {
    // Dispose animations through manager
    if (_fadeAnimationId != null) {
      _animationManager.disposeController(_fadeAnimationId!);
    }
    
    for (final animationId in _dotAnimationIds) {
      _animationManager.disposeController(animationId);
    }
    
    // Dispose controllers
    _fadeController.dispose();
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: widget.padding ?? const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.grey[100],
              borderRadius: widget.borderRadius ?? BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // AI avatar
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Typing message (if provided)
                if (widget.message != null) ...[
                  Text(
                    widget.message!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Bouncing dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBouncingDot(_dot1Animation, 0),
                    const SizedBox(width: 4),
                    _buildBouncingDot(_dot2Animation, 1),
                    const SizedBox(width: 4),
                    _buildBouncingDot(_dot3Animation, 2),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBouncingDot(Animation<double> animation, int index) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 1.0 + (animation.value * 0.5);
        final opacity = 0.4 + (animation.value * 0.6);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (widget.dotColor ?? Colors.grey[600])?.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

/// Extension methods for easier usage of ChatTypingIndicator
extension ChatTypingIndicatorExtensions on Widget {
  /// Wraps this widget with a typing indicator that shows when isTyping is true
  Widget withTypingIndicator({
    required bool isTyping,
    String? typingMessage,
    Duration bounceDuration = const Duration(milliseconds: 600),
    Duration bounceDelay = const Duration(milliseconds: 200),
    double dotSize = 8.0,
    Color? dotColor,
    Color? backgroundColor,
  }) {
    return Column(
      children: [
        this,
        ChatTypingIndicator(
          isVisible: isTyping,
          message: typingMessage,
          bounceDuration: bounceDuration,
          bounceDelay: bounceDelay,
          dotSize: dotSize,
          dotColor: dotColor,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}