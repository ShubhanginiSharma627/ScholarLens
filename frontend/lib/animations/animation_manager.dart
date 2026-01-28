import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import 'animation_config.dart';
import 'managed_animation.dart';
import 'performance_metrics.dart';
import 'theme_integration.dart';

/// Centralized animation manager for coordinating all animations in the app
class AnimationManager {
  static final AnimationManager _instance = AnimationManager._internal();
  factory AnimationManager() => _instance;
  AnimationManager._internal();

  final AnimationRegistry _registry = AnimationRegistry();
  final AnimationPerformanceMonitor _performanceMonitor = 
      AnimationPerformanceMonitor();
  
  bool _reducedMotion = false;
  double _performanceScale = 1.0;
  bool _isInitialized = false;

  // Performance thresholds
  static const double _performanceThresholdGood = 0.8;
  static const double _performanceThresholdPoor = 0.4;
  static const int _maxConcurrentAnimations = 20;

  /// Initializes the animation manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check for reduced motion preference
    await _checkReducedMotionPreference();
    
    // Start performance monitoring
    _startPerformanceMonitoring();
    
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('AnimationManager initialized - '
          'reducedMotion: $_reducedMotion, '
          'performanceScale: $_performanceScale');
    }
  }

  /// Registers an animation controller with the manager
  String registerController({
    required AnimationController controller,
    required AnimationConfig config,
    required AnimationCategory category,
    String? customId,
  }) {
    if (!_isInitialized) {
      throw StateError('AnimationManager must be initialized before use');
    }

    final id = customId ?? _generateAnimationId(category);
    
    // Apply performance scaling to duration
    final scaledDuration = Duration(
      milliseconds: (config.duration.inMilliseconds * _performanceScale).round(),
    );
    
    final scaledConfig = config.copyWith(duration: scaledDuration);
    
    // Create the animation with the scaled config
    final animation = _createAnimation(controller, scaledConfig);
    
    final managedAnimation = ManagedAnimation(
      id: id,
      controller: controller,
      animation: animation,
      config: scaledConfig,
      category: category,
    );

    _registry.register(managedAnimation);
    
    // Set up controller listeners
    _setupControllerListeners(managedAnimation);
    
    if (kDebugMode) {
      debugPrint('Registered animation: $id (category: $category)');
    }
    
    return id;
  }

  /// Disposes an animation controller
  void disposeController(String id) {
    final animation = _registry.getAnimation(id);
    if (animation != null) {
      animation.dispose();
      _registry.unregister(id);
      
      if (kDebugMode) {
        debugPrint('Disposed animation: $id');
      }
    }
  }

  /// Starts an animation
  void startAnimation(String id) {
    final animation = _registry.getAnimation(id);
    if (animation != null) {
      // Check if reduced motion is enabled and animation respects it
      if (_reducedMotion && animation.config.respectReducedMotion) {
        // Skip animation or use reduced version
        _handleReducedMotionAnimation(animation);
        return;
      }

      // Check performance constraints
      if (!_canStartAnimation(animation)) {
        if (kDebugMode) {
          debugPrint('Skipping animation $id due to performance constraints');
        }
        return;
      }

      animation.start();
      animation.controller.forward();
      
      if (kDebugMode) {
        debugPrint('Started animation: $id');
      }
    }
  }

  /// Pauses all animations
  void pauseAll() {
    for (final animation in _registry.activeAnimations) {
      animation.pause();
      animation.controller.stop();
    }
    
    if (kDebugMode) {
      debugPrint('Paused all animations');
    }
  }

  /// Resumes all animations
  void resumeAll() {
    for (final animation in _registry.activeAnimations) {
      animation.resume();
      animation.controller.forward();
    }
    
    if (kDebugMode) {
      debugPrint('Resumed all animations');
    }
  }

  /// Pauses animations by category
  void pauseCategory(AnimationCategory category) {
    _registry.pauseCategory(category);
    
    if (kDebugMode) {
      debugPrint('Paused animations in category: $category');
    }
  }

  /// Resumes animations by category
  void resumeCategory(AnimationCategory category) {
    _registry.resumeCategory(category);
    
    if (kDebugMode) {
      debugPrint('Resumed animations in category: $category');
    }
  }

  /// Updates the performance scale factor
  void updatePerformanceScale(double scale) {
    _performanceScale = scale.clamp(0.1, 1.0);
    
    if (kDebugMode) {
      debugPrint('Updated performance scale: $_performanceScale');
    }
  }

  /// Gets current performance metrics
  AnimationPerformanceMetrics getCurrentPerformanceMetrics() {
    return _performanceMonitor.getCurrentMetrics(_registry.activeCount);
  }

  /// Gets theme-aware animation configuration
  AnimationConfig getThemeAwareConfig(BuildContext context, AnimationConfig baseConfig) {
    final theme = Theme.of(context);
    
    // Adjust duration based on theme brightness
    final adjustedDuration = theme.brightness == Brightness.dark 
        ? Duration(milliseconds: (baseConfig.duration.inMilliseconds * 0.9).round())
        : baseConfig.duration;
    
    return baseConfig.copyWith(duration: adjustedDuration);
  }

  /// Gets an animation by ID
  ManagedAnimation? getAnimation(String id) {
    return _registry.getAnimation(id);
  }

  /// Gets all animations in a category
  List<ManagedAnimation> getAnimationsByCategory(AnimationCategory category) {
    return _registry.getAnimationsByCategory(category);
  }

  /// Gets performance history
  List<AnimationPerformanceMetrics> get performanceHistory => 
      _performanceMonitor.history;

  /// Gets animation registry for debugging
  AnimationRegistry get registry => _registry;

  /// Whether reduced motion is enabled
  bool get isReducedMotionEnabled => _reducedMotion;

  /// Current performance scale
  double get performanceScale => _performanceScale;

  /// Whether the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Disposes the animation manager
  void dispose() {
    _registry.disposeAll();
    _performanceMonitor.reset();
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('AnimationManager disposed');
    }
  }

  // Private methods

  Future<void> _checkReducedMotionPreference() async {
    try {
      // Check system accessibility settings
      // For now, we'll use a simplified approach that can be extended
      // In a production app, you'd use platform channels or packages like
      // accessibility_tools to check actual system preferences
      
      // Check if we're in a test environment
      if (kDebugMode) {
        // In debug mode, default to false unless explicitly set
        _reducedMotion = false;
      } else {
        // In production, you would implement platform-specific checks here
        // For now, default to false
        _reducedMotion = false;
      }
      
      if (kDebugMode) {
        debugPrint('Reduced motion preference: $_reducedMotion');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking reduced motion preference: $e');
      }
      _reducedMotion = false;
    }
  }

  /// Manually set reduced motion preference (for testing or user settings)
  void setReducedMotionPreference(bool enabled) {
    _reducedMotion = enabled;
    if (kDebugMode) {
      debugPrint('Manually set reduced motion preference: $_reducedMotion');
    }
  }

  void _startPerformanceMonitoring() {
    // Start monitoring frame times
    WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
  }

  void _onFrameEnd(Duration timestamp) {
    // Record frame time (simplified)
    final frameTime = timestamp.inMicroseconds / 1000.0; // Convert to milliseconds
    _performanceMonitor.recordFrameTime(frameTime);
    
    // Update performance scale based on metrics
    final metrics = _performanceMonitor.getCurrentMetrics(_registry.activeCount);
    _updatePerformanceScaleFromMetrics(metrics);
    
    // Schedule next frame callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
  }

  void _updatePerformanceScaleFromMetrics(AnimationPerformanceMetrics metrics) {
    final recommendedScale = metrics.recommendedScale;
    
    // Only update if there's a significant change
    if ((recommendedScale - _performanceScale).abs() > 0.1) {
      updatePerformanceScale(recommendedScale);
    }
  }

  String _generateAnimationId(AnimationCategory category) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${category.name}_$timestamp';
  }

  Animation _createAnimation(AnimationController controller, AnimationConfig config) {
    // Create appropriate animation based on config
    if (config.scaleStart != null && config.scaleEnd != null) {
      return Tween<double>(
        begin: config.scaleStart!,
        end: config.scaleEnd!,
      ).animate(CurvedAnimation(parent: controller, curve: config.curve));
    }
    
    if (config.slideStart != null && config.slideEnd != null) {
      return Tween<Offset>(
        begin: config.slideStart!,
        end: config.slideEnd!,
      ).animate(CurvedAnimation(parent: controller, curve: config.curve));
    }
    
    if (config.fadeStart != null && config.fadeEnd != null) {
      return Tween<double>(
        begin: config.fadeStart!,
        end: config.fadeEnd!,
      ).animate(CurvedAnimation(parent: controller, curve: config.curve));
    }
    
    // Default to a simple double animation
    return Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: controller, curve: config.curve));
  }

  void _setupControllerListeners(ManagedAnimation animation) {
    animation.controller.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.forward:
          animation.start();
          break;
        case AnimationStatus.completed:
          animation.complete();
          break;
        case AnimationStatus.dismissed:
          animation.complete();
          break;
        case AnimationStatus.reverse:
          // Handle reverse if needed
          break;
      }
    });
  }

  bool _canStartAnimation(ManagedAnimation animation) {
    // Check if we're at the concurrent animation limit
    if (_registry.activeCount >= _maxConcurrentAnimations) {
      return false;
    }
    
    // Check performance constraints
    final metrics = _performanceMonitor.latestMetrics;
    if (metrics != null && !metrics.isPerformanceGood) {
      // Only allow high priority animations when performance is poor
      return animation.config.priority <= 2;
    }
    
    return true;
  }

  void _handleReducedMotionAnimation(ManagedAnimation animation) {
    // For reduced motion, we can either:
    // 1. Skip the animation entirely
    // 2. Use a much faster, simpler animation
    // 3. Use a fade-only animation instead of complex movements
    
    // For now, we'll use a simple fade with very short duration
    final reducedConfig = AnimationConfig(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      fadeStart: 0.0,
      fadeEnd: 1.0,
      priority: animation.config.priority,
    );
    
    // Update the animation to use reduced motion config
    animation.controller.duration = reducedConfig.duration;
    animation.start();
    animation.controller.forward();
  }
}

/// Extension methods for easier animation management
extension AnimationManagerExtensions on AnimationManager {
  /// Creates and registers a theme-aware scale animation
  String createThemeAwareScaleAnimation({
    required TickerProvider vsync,
    required BuildContext context,
    Duration? duration,
    double scaleStart = 1.0,
    double scaleEnd = 0.95,
    Curve? curve,
    AnimationCategory category = AnimationCategory.microInteraction,
  }) {
    final baseConfig = AnimationConfig(
      duration: duration ?? const Duration(milliseconds: 150),
      curve: curve ?? AnimationTheme.getContextualCurve(category),
      scaleStart: scaleStart,
      scaleEnd: scaleEnd,
    );
    
    final themeConfig = getThemeAwareConfig(context, baseConfig);
    
    final controller = AnimationController(
      duration: themeConfig.duration,
      vsync: vsync,
    );
    
    return registerController(
      controller: controller,
      config: themeConfig,
      category: category,
    );
  }

  /// Creates and registers a simple scale animation
  String createScaleAnimation({
    required TickerProvider vsync,
    Duration? duration,
    double scaleStart = 1.0,
    double scaleEnd = 0.95,
    Curve curve = Curves.easeInOut,
    AnimationCategory category = AnimationCategory.microInteraction,
  }) {
    final controller = AnimationController(
      duration: duration ?? const Duration(milliseconds: 150),
      vsync: vsync,
    );
    
    final config = AnimationConfig(
      duration: duration ?? const Duration(milliseconds: 150),
      curve: curve,
      scaleStart: scaleStart,
      scaleEnd: scaleEnd,
    );
    
    return registerController(
      controller: controller,
      config: config,
      category: category,
    );
  }

  /// Creates and registers a slide animation
  String createSlideAnimation({
    required TickerProvider vsync,
    Duration? duration,
    Offset slideStart = const Offset(1.0, 0.0),
    Offset slideEnd = Offset.zero,
    Curve curve = Curves.easeInOut,
    AnimationCategory category = AnimationCategory.transition,
  }) {
    final controller = AnimationController(
      duration: duration ?? const Duration(milliseconds: 300),
      vsync: vsync,
    );
    
    final config = AnimationConfig(
      duration: duration ?? const Duration(milliseconds: 300),
      curve: curve,
      slideStart: slideStart,
      slideEnd: slideEnd,
    );
    
    return registerController(
      controller: controller,
      config: config,
      category: category,
    );
  }

  /// Creates and registers a theme-aware slide animation
  String createThemeAwareSlideAnimation({
    required TickerProvider vsync,
    required BuildContext context,
    Duration? duration,
    Offset slideStart = const Offset(1.0, 0.0),
    Offset slideEnd = Offset.zero,
    Curve? curve,
    AnimationCategory category = AnimationCategory.transition,
  }) {
    final baseConfig = AnimationConfig(
      duration: duration ?? const Duration(milliseconds: 300),
      curve: curve ?? AnimationTheme.getContextualCurve(category),
      slideStart: slideStart,
      slideEnd: slideEnd,
    );
    
    final themeConfig = getThemeAwareConfig(context, baseConfig);
    
    final controller = AnimationController(
      duration: themeConfig.duration,
      vsync: vsync,
    );
    
    return registerController(
      controller: controller,
      config: themeConfig,
      category: category,
    );
  }

  /// Creates and registers a fade animation
  String createFadeAnimation({
    required TickerProvider vsync,
    Duration? duration,
    double fadeStart = 0.0,
    double fadeEnd = 1.0,
    Curve curve = Curves.easeInOut,
    AnimationCategory category = AnimationCategory.content,
  }) {
    final controller = AnimationController(
      duration: duration ?? const Duration(milliseconds: 300),
      vsync: vsync,
    );
    
    final config = AnimationConfig(
      duration: duration ?? const Duration(milliseconds: 300),
      curve: curve,
      fadeStart: fadeStart,
      fadeEnd: fadeEnd,
    );
    
    return registerController(
      controller: controller,
      config: config,
      category: category,
    );
  }

  /// Creates and registers a theme-aware fade animation
  String createThemeAwareFadeAnimation({
    required TickerProvider vsync,
    required BuildContext context,
    Duration? duration,
    double fadeStart = 0.0,
    double fadeEnd = 1.0,
    Curve? curve,
    AnimationCategory category = AnimationCategory.content,
  }) {
    final baseConfig = AnimationConfig(
      duration: duration ?? const Duration(milliseconds: 300),
      curve: curve ?? AnimationTheme.getContextualCurve(category),
      fadeStart: fadeStart,
      fadeEnd: fadeEnd,
    );
    
    final themeConfig = getThemeAwareConfig(context, baseConfig);
    
    final controller = AnimationController(
      duration: themeConfig.duration,
      vsync: vsync,
    );
    
    return registerController(
      controller: controller,
      config: themeConfig,
      category: category,
    );
  }
}