import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'animation_config.dart';
import 'animation_manager.dart';

/// Smart page route builder that provides adaptive transition selection based on context
class SmartTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionType type;
  final Duration duration;
  final Duration reverseDuration;
  final Offset? slideDirection;
  final Curve curve;
  final Curve reverseCurve;
  final bool maintainState;
  final bool fullscreenDialog;
  final bool opaque;
  final Color? barrierColor;
  final String? barrierLabel;
  final bool barrierDismissible;
  final AnimationManager? animationManager;

  SmartTransition({
    required this.child,
    this.type = TransitionType.adaptive,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 300),
    this.slideDirection,
    this.curve = Curves.easeInOut,
    this.reverseCurve = Curves.easeInOut,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierColor,
    this.barrierLabel,
    this.barrierDismissible = false,
    this.animationManager,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          opaque: opaque,
          barrierColor: barrierColor,
          barrierLabel: barrierLabel,
          barrierDismissible: barrierDismissible,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
        );

  /// Factory constructor for slide transitions
  factory SmartTransition.slide({
    required Widget child,
    Offset direction = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
    bool maintainState = true,
  }) {
    return SmartTransition<T>(
      child: child,
      type: TransitionType.slide,
      slideDirection: direction,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
    );
  }

  /// Factory constructor for fade transitions
  factory SmartTransition.fade({
    required Widget child,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
    bool maintainState = true,
  }) {
    return SmartTransition<T>(
      child: child,
      type: TransitionType.fade,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
    );
  }

  /// Factory constructor for scale transitions
  factory SmartTransition.scale({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
    bool maintainState = true,
  }) {
    return SmartTransition<T>(
      child: child,
      type: TransitionType.scale,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
    );
  }

  /// Factory constructor for slide-up (modal) transitions
  factory SmartTransition.slideUp({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = true,
  }) {
    return SmartTransition<T>(
      child: child,
      type: TransitionType.slideUp,
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Factory constructor for hero transitions with shared elements
  factory SmartTransition.hero({
    required Widget child,
    required String heroTag,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
    bool maintainState = true,
  }) {
    return SmartTransition<T>(
      child: Hero(
        tag: heroTag,
        child: child,
      ),
      type: TransitionType.fade, // Hero transitions work best with fade
      duration: duration,
      curve: curve,
      settings: settings,
      maintainState: maintainState,
    );
  }

  /// Factory constructor for adaptive transitions that choose based on context
  factory SmartTransition.adaptive({
    required Widget child,
    required BuildContext context,
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    final adaptiveType = _determineAdaptiveTransition(context, fullscreenDialog);
    final adaptiveDuration = duration ?? _getAdaptiveDuration(adaptiveType);
    final adaptiveCurve = curve ?? _getAdaptiveCurve(adaptiveType);

    return SmartTransition<T>(
      child: child,
      type: adaptiveType,
      duration: adaptiveDuration,
      curve: adaptiveCurve,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check if reduced motion is enabled
    final manager = animationManager ?? AnimationManager();
    if (manager.isReducedMotionEnabled) {
      return _buildReducedMotionTransition(animation, child);
    }

    // Apply performance scaling if available
    final scaledAnimation = manager.isInitialized
        ? Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                0.0,
                manager.performanceScale,
                curve: curve,
              ),
            ),
          )
        : animation;

    switch (_getEffectiveTransitionType(context)) {
      case TransitionType.slide:
        return _buildSlideTransition(scaledAnimation, secondaryAnimation, child);
      case TransitionType.fade:
        return _buildFadeTransition(scaledAnimation, child);
      case TransitionType.scale:
        return _buildScaleTransition(scaledAnimation, child);
      case TransitionType.slideUp:
        return _buildSlideUpTransition(scaledAnimation, child);
      case TransitionType.custom:
        return _buildCustomTransition(scaledAnimation, secondaryAnimation, child);
      case TransitionType.adaptive:
      default:
        return _buildAdaptiveTransition(context, scaledAnimation, secondaryAnimation, child);
    }
  }

  Widget _buildReducedMotionTransition(Animation<double> animation, Widget child) {
    // For reduced motion, use a simple fade with very short duration
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideOffset = slideDirection ?? const Offset(1.0, 0.0);
    
    // Primary slide animation
    final primarySlide = SlideTransition(
      position: Tween<Offset>(
        begin: slideOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );

    // Secondary slide animation for the previous page
    final secondarySlide = SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: Offset(-slideOffset.dx * 0.3, -slideOffset.dy * 0.3),
      ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve)),
      child: primarySlide,
    );

    return secondarySlide;
  }

  Widget _buildFadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: child,
    );
  }

  Widget _buildScaleTransition(Animation<double> animation, Widget child) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: curve),
        child: child,
      ),
    );
  }

  Widget _buildSlideUpTransition(Animation<double> animation, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  }

  Widget _buildCustomTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Default custom transition - can be overridden by subclasses
    return _buildFadeTransition(animation, child);
  }

  Widget _buildAdaptiveTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final adaptiveType = _determineAdaptiveTransition(context, fullscreenDialog);
    
    switch (adaptiveType) {
      case TransitionType.slide:
        return _buildSlideTransition(animation, secondaryAnimation, child);
      case TransitionType.fade:
        return _buildFadeTransition(animation, child);
      case TransitionType.scale:
        return _buildScaleTransition(animation, child);
      case TransitionType.slideUp:
        return _buildSlideUpTransition(animation, child);
      default:
        return _buildFadeTransition(animation, child);
    }
  }

  TransitionType _getEffectiveTransitionType(BuildContext context) {
    if (type == TransitionType.adaptive) {
      return _determineAdaptiveTransition(context, fullscreenDialog);
    }
    return type;
  }

  static TransitionType _determineAdaptiveTransition(
    BuildContext context,
    bool isModal,
  ) {
    // Determine transition based on context and platform
    final theme = Theme.of(context);
    final platform = theme.platform;
    final mediaQuery = MediaQuery.of(context);
    
    // Modal presentations should slide up
    if (isModal) {
      return TransitionType.slideUp;
    }
    
    // Camera and scanner screens should use fade to avoid jarring changes
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null && 
        (routeName.contains('camera') || routeName.contains('scanner'))) {
      return TransitionType.fade;
    }
    
    // Tablet and desktop prefer fade transitions
    if (mediaQuery.size.width > 768) {
      return TransitionType.fade;
    }
    
    // iOS prefers slide transitions
    if (platform == TargetPlatform.iOS) {
      return TransitionType.slide;
    }
    
    // Android prefers slide for navigation, scale for dialogs
    if (platform == TargetPlatform.android) {
      return TransitionType.slide;
    }
    
    // Default to slide
    return TransitionType.slide;
  }

  static Duration _getAdaptiveDuration(TransitionType type) {
    switch (type) {
      case TransitionType.fade:
        return const Duration(milliseconds: 250);
      case TransitionType.scale:
        return const Duration(milliseconds: 300);
      case TransitionType.slideUp:
        return const Duration(milliseconds: 300);
      case TransitionType.slide:
      default:
        return const Duration(milliseconds: 300);
    }
  }

  static Curve _getAdaptiveCurve(TransitionType type) {
    switch (type) {
      case TransitionType.slideUp:
        return Curves.easeOut;
      case TransitionType.scale:
        return Curves.elasticOut;
      case TransitionType.fade:
      case TransitionType.slide:
      default:
        return Curves.easeInOut;
    }
  }
}

/// Extension methods for easier navigation with SmartTransition
extension SmartNavigationExtensions on NavigatorState {
  /// Push a route with smart transition
  Future<T?> pushSmart<T extends Object?>(
    Widget child, {
    TransitionType type = TransitionType.adaptive,
    Duration? duration,
    Curve? curve,
    Offset? slideDirection,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return push<T>(
      SmartTransition<T>(
        child: child,
        type: type,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOut,
        slideDirection: slideDirection,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// Push a slide transition
  Future<T?> pushSlide<T extends Object?>(
    Widget child, {
    Offset direction = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return push<T>(
      SmartTransition.slide<T>(
        child: child,
        direction: direction,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
    );
  }

  /// Push a fade transition
  Future<T?> pushFade<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return push<T>(
      SmartTransition.fade<T>(
        child: child,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
    );
  }

  /// Push a scale transition
  Future<T?> pushScale<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return push<T>(
      SmartTransition.scale<T>(
        child: child,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
    );
  }

  /// Push a slide-up (modal) transition
  Future<T?> pushSlideUp<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    RouteSettings? settings,
  }) {
    return push<T>(
      SmartTransition.slideUp<T>(
        child: child,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
    );
  }

  /// Push with hero transition
  Future<T?> pushHero<T extends Object?>(
    Widget child, {
    required String heroTag,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return push<T>(
      SmartTransition.hero<T>(
        child: child,
        heroTag: heroTag,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
    );
  }

  /// Push with adaptive transition that chooses based on context
  Future<T?> pushAdaptive<T extends Object?>(
    Widget child, {
    required BuildContext context,
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return push<T>(
      SmartTransition.adaptive<T>(
        child: child,
        context: context,
        duration: duration,
        curve: curve,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }
}

/// Extension methods for BuildContext navigation
extension SmartContextNavigationExtensions on BuildContext {
  /// Push a route with smart transition
  Future<T?> pushSmart<T extends Object?>(
    Widget child, {
    TransitionType type = TransitionType.adaptive,
    Duration? duration,
    Curve? curve,
    Offset? slideDirection,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(this).pushSmart<T>(
      child,
      type: type,
      duration: duration,
      curve: curve,
      slideDirection: slideDirection,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Push a slide transition
  Future<T?> pushSlide<T extends Object?>(
    Widget child, {
    Offset direction = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushSlide<T>(
      child,
      direction: direction,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// Push a fade transition
  Future<T?> pushFade<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushFade<T>(
      child,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// Push a scale transition
  Future<T?> pushScale<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushScale<T>(
      child,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// Push a slide-up (modal) transition
  Future<T?> pushSlideUp<T extends Object?>(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushSlideUp<T>(
      child,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// Push with hero transition
  Future<T?> pushHero<T extends Object?>(
    Widget child, {
    required String heroTag,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushHero<T>(
      child,
      heroTag: heroTag,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// Push with adaptive transition that chooses based on context
  Future<T?> pushAdaptive<T extends Object?>(
    Widget child, {
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(this).pushAdaptive<T>(
      child,
      context: this,
      duration: duration,
      curve: curve,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

/// Utility class for common transition configurations
class SmartTransitionConfigs {
  /// Bottom navigation tab transitions
  static SmartTransition<T> bottomNavTab<T>(Widget child) {
    return SmartTransition.slide<T>(
      child: child,
      direction: const Offset(1.0, 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Modal presentation transitions
  static SmartTransition<T> modal<T>(Widget child) {
    return SmartTransition.slideUp<T>(
      child: child,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Camera screen transitions
  static SmartTransition<T> camera<T>(Widget child) {
    return SmartTransition.fade<T>(
      child: child,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  /// Back navigation transitions
  static SmartTransition<T> back<T>(Widget child) {
    return SmartTransition.slide<T>(
      child: child,
      direction: const Offset(-1.0, 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Dialog transitions
  static SmartTransition<T> dialog<T>(Widget child) {
    return SmartTransition.scale<T>(
      child: child,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
    );
  }
}