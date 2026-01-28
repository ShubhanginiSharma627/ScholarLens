import 'package:flutter/material.dart';
import 'dart:ui';
import '../../animations/animation_manager.dart';
import '../../animations/animation_config.dart';

/// Enhanced speed dial with improved animations and backdrop blur
class EnhancedSpeedDial extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final VoidCallback? onClose;
  final Color? backgroundColor;
  final Color? backdropColor;
  final double? blurSigma;

  const EnhancedSpeedDial({
    super.key,
    required this.actions,
    this.onClose,
    this.backgroundColor,
    this.backdropColor,
    this.blurSigma,
  });

  @override
  State<EnhancedSpeedDial> createState() => _EnhancedSpeedDialState();
}

class _EnhancedSpeedDialState extends State<EnhancedSpeedDial>
    with TickerProviderStateMixin {
  late AnimationManager _animationManager;
  late String _backdropAnimationId;
  late String _containerAnimationId;
  final Map<int, String> _actionAnimationIds = {};
  final Map<int, String> _actionScaleIds = {};
  
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationManager = AnimationManager();
    _initializeAnimations();
    _showSpeedDial();
  }

  void _initializeAnimations() {
    // Backdrop fade animation
    _backdropAnimationId = _animationManager.createFadeAnimation(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      fadeStart: 0.0,
      fadeEnd: 1.0,
      curve: Curves.easeOut,
      category: AnimationCategory.transition,
    );

    // Container slide animation
    _containerAnimationId = _animationManager.createSlideAnimation(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      slideStart: const Offset(0.0, 0.3),
      slideEnd: Offset.zero,
      curve: Curves.easeOutCubic,
      category: AnimationCategory.transition,
    );

    // Individual action animations
    for (int i = 0; i < widget.actions.length; i++) {
      // Slide animation for each action
      _actionAnimationIds[i] = _animationManager.createSlideAnimation(
        vsync: this,
        duration: Duration(milliseconds: 250 + (i * 50)), // Staggered timing
        slideStart: const Offset(0.0, 0.5),
        slideEnd: Offset.zero,
        curve: Curves.easeOutBack,
        category: AnimationCategory.content,
      );

      // Scale animation for tap feedback
      _actionScaleIds[i] = _animationManager.createScaleAnimation(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        scaleStart: 1.0,
        scaleEnd: 0.95,
        curve: Curves.easeInOut,
        category: AnimationCategory.microInteraction,
      );
    }
  }

  void _showSpeedDial() {
    setState(() {
      _isVisible = true;
    });

    // Start backdrop animation
    _animationManager.startAnimation(_backdropAnimationId);
    
    // Start container animation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationManager.startAnimation(_containerAnimationId);
      }
    });

    // Start staggered action animations
    for (int i = 0; i < widget.actions.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + (i * 50)), () {
        if (mounted) {
          _animationManager.startAnimation(_actionAnimationIds[i]!);
        }
      });
    }
  }

  void _hideSpeedDial() {
    // Reverse all animations
    final backdropAnimation = _animationManager.getAnimation(_backdropAnimationId);
    final containerAnimation = _animationManager.getAnimation(_containerAnimationId);
    
    backdropAnimation?.controller.reverse();
    containerAnimation?.controller.reverse();

    for (int i = 0; i < widget.actions.length; i++) {
      final actionAnimation = _animationManager.getAnimation(_actionAnimationIds[i]!);
      actionAnimation?.controller.reverse();
    }

    // Close after animation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onClose?.call();
      }
    });
  }

  void _onActionTap(int index, VoidCallback? onTap) {
    // Animate button press
    final scaleAnimation = _animationManager.getAnimation(_actionScaleIds[index]!);
    if (scaleAnimation != null) {
      scaleAnimation.controller.forward().then((_) {
        scaleAnimation.controller.reverse();
      });
    }

    // Execute action after brief delay for visual feedback
    Future.delayed(const Duration(milliseconds: 100), () {
      onTap?.call();
      _hideSpeedDial();
    });
  }

  @override
  void dispose() {
    // Dispose all animations
    _animationManager.disposeController(_backdropAnimationId);
    _animationManager.disposeController(_containerAnimationId);
    for (final id in _actionAnimationIds.values) {
      _animationManager.disposeController(id);
    }
    for (final id in _actionScaleIds.values) {
      _animationManager.disposeController(id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = MediaQuery.of(context).padding.bottom + 80;
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Enhanced backdrop with blur
          _buildAnimatedBackdrop(bottomNavHeight),
          // Speed dial actions
          _buildSpeedDialActions(bottomNavHeight),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackdrop(double bottomNavHeight) {
    return AnimatedBuilder(
      animation: _animationManager.getAnimation(_backdropAnimationId)?.controller ?? 
          const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final fadeAnimation = _animationManager.getAnimation(_backdropAnimationId)?.animation as Animation<double>?;
        final opacity = fadeAnimation?.value ?? 0.0;
        
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomNavHeight,
          child: GestureDetector(
            onTap: _hideSpeedDial,
            child: Opacity(
              opacity: opacity,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (widget.blurSigma ?? 12) * opacity,
                  sigmaY: (widget.blurSigma ?? 12) * opacity,
                ),
                child: Container(
                  color: (widget.backdropColor ?? Colors.black.withValues(alpha: 0.15))
                      .withValues(alpha: (widget.backdropColor?.alpha ?? 0.15) * opacity),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedDialActions(double bottomNavHeight) {
    return AnimatedBuilder(
      animation: _animationManager.getAnimation(_containerAnimationId)?.controller ?? 
          const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final slideAnimation = _animationManager.getAnimation(_containerAnimationId)?.animation as Animation<Offset>?;
        final slideOffset = slideAnimation?.value ?? const Offset(0.0, 0.3);
        
        return Positioned(
          left: 40,
          right: 40,
          bottom: bottomNavHeight + 20,
          child: Transform.translate(
            offset: slideOffset * 50, // Scale the offset
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                return _buildAnimatedAction(index, action);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAction(int index, SpeedDialAction action) {
    return AnimatedBuilder(
      animation: _animationManager.getAnimation(_actionAnimationIds[index]!)?.controller ?? 
          const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final slideAnimation = _animationManager.getAnimation(_actionAnimationIds[index]!)?.animation as Animation<Offset>?;
        final scaleAnimation = _animationManager.getAnimation(_actionScaleIds[index]!)?.animation as Animation<double>?;
        
        final slideOffset = slideAnimation?.value ?? const Offset(0.0, 0.5);
        final scale = scaleAnimation?.value ?? 1.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Transform.translate(
            offset: slideOffset * 30, // Scale the offset
            child: Transform.scale(
              scale: scale,
              child: _buildSpeedDialButton(action, () => _onActionTap(index, action.onTap)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedDialButton(SpeedDialAction action, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: action.backgroundColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: action.backgroundColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              color: action.foregroundColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              action.label,
              style: TextStyle(
                color: action.foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Speed dial action configuration
class SpeedDialAction {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.onTap,
  });
}

/// Helper function to show enhanced speed dial
void showEnhancedSpeedDial(
  BuildContext context, {
  required List<SpeedDialAction> actions,
  Color? backgroundColor,
  Color? backdropColor,
  double? blurSigma,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => EnhancedSpeedDial(
      actions: actions,
      backgroundColor: backgroundColor,
      backdropColor: backdropColor,
      blurSigma: blurSigma,
      onClose: () => overlayEntry.remove(),
    ),
  );
  
  overlay.insert(overlayEntry);
}