import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/accessibility_service.dart';
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
  final AccessibilityService _accessibilityService = AccessibilityService();
  
  bool _reducedMotion = false;
  double _performanceScale = 1.0;
  bool _isInitialized = false;

  /// Initializes the animation manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize accessibility service first
    await _accessibilityService.initialize();
    
    // Initialize performance monitoring
    _performanceMonitor.initialize();
    
    // Set up accessibility listeners
    _setupAccessibilityListeners();
    
    // Set up performance listeners
    _setupPerformanceListeners();

    // Check for reduced motion preference from accessibility service
    _reducedMotion = _accessibilityService.isReducedMotionEnabled;
    
    // Start performance monitoring
    _startPerformanceMonitoring();
    
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('AnimationManager initialized - '
          'reducedMotion: $_reducedMotion, '
          'performanceScale: $_performanceScale, '
          'deviceTier: ${_performanceMonitor.deviceTier}');
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
    final optimizedDuration = PerformanceOptimizer.optimizeDuration(
      originalDuration: config.duration,
      quality: _performanceMonitor.currentQuality,
      deviceTier: _performanceMonitor.deviceTier,
    );
    
    final scaledConfig = config.copyWith(duration: optimizedDuration);
    
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
      debugPrint('Registered animation: $id (category: $category, '
          'quality: ${_performanceMonitor.currentQuality})');
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

  /// Starts an animation with accessibility considerations
  void startAnimation(String id) {
    final animation = _registry.getAnimation(id);
    if (animation == null) return;

    // Check if animation should be skipped due to performance
    final metrics = _performanceMonitor.getCurrentMetrics(_registry.activeCount);
    if (PerformanceOptimizer.shouldSkipAnimation(
      metrics: metrics,
      animationPriority: animation.config.priority,
    )) {
      _completeAnimationInstantly(animation);
      return;
    }

    // Get accessibility configuration
    final accessibleConfig = _getAccessibleAnimationConfig(animation);
    
    // Handle different accessibility alternatives
    switch (accessibleConfig.alternative) {
      case AnimationAlternative.skip:
        // Skip animation entirely - just complete immediately
        _completeAnimationInstantly(animation);
        return;
        
      case AnimationAlternative.instant:
        // Show final state immediately
        _completeAnimationInstantly(animation);
        return;
        
      case AnimationAlternative.simple:
        // Use simplified animation
        _startSimplifiedAnimation(animation, accessibleConfig);
        return;
        
      case AnimationAlternative.fade:
        // Convert to fade animation
        _startFadeAlternative(animation, accessibleConfig);
        return;
        
      case AnimationAlternative.normal:
        // Use normal animation with accessibility adjustments
        break;
    }

    // Check performance constraints
    if (!_canStartAnimation(animation)) {
      if (kDebugMode) {
        debugPrint('Skipping animation $id due to performance constraints');
      }
      return;
    }

    // Apply accessibility-adjusted timing
    _applyAccessibilityTiming(animation, accessibleConfig);

    animation.start();
    animation.controller.forward();
    
    if (kDebugMode) {
      debugPrint('Started animation: $id (accessibility: ${accessibleConfig.alternative}, '
          'quality: ${_performanceMonitor.currentQuality})');
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
  bool get isReducedMotionEnabled => _accessibilityService.isReducedMotionEnabled;

  /// Whether high contrast is enabled
  bool get isHighContrastEnabled => _accessibilityService.isHighContrastEnabled;

  /// Current text scale factor
  double get textScaleFactor => _accessibilityService.textScaleFactor;

  /// Current performance scale
  double get performanceScale => _performanceScale;

  /// Whether the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Gets the accessibility service
  AccessibilityService get accessibilityService => _accessibilityService;

  /// Disposes the animation manager
  void dispose() {
    _registry.disposeAll();
    _performanceMonitor.dispose();
    _accessibilityService.dispose();
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('AnimationManager disposed');
    }
  }

  // Private methods

  void _setupAccessibilityListeners() {
    // Listen for reduced motion changes
    _accessibilityService.addReducedMotionListener(() {
      _reducedMotion = _accessibilityService.isReducedMotionEnabled;
      if (kDebugMode) {
        debugPrint('Reduced motion preference changed: $_reducedMotion');
      }
      
      // Pause or adjust running animations based on new preference
      _handleAccessibilityChange();
    });
    
    // Listen for high contrast changes
    _accessibilityService.addHighContrastListener(() {
      if (kDebugMode) {
        debugPrint('High contrast preference changed: ${_accessibilityService.isHighContrastEnabled}');
      }
      // High contrast changes don't directly affect animations,
      // but could be used for theme adjustments
    });
  }

  void _setupPerformanceListeners() {
    // Listen for animation quality changes
    _performanceMonitor.addQualityChangeListener((quality) {
      if (kDebugMode) {
        debugPrint('Animation quality changed to: $quality');
      }
      
      // Adjust running animations based on new quality level
      _handleQualityChange(quality);
    });
    
    // Listen for memory pressure events
    _performanceMonitor.addMemoryPressureListener(() {
      if (kDebugMode) {
        debugPrint('Memory pressure detected - reducing animation complexity');
      }
      
      // Pause or simplify low-priority animations
      _handleMemoryPressure();
    });
  }

  void _handleQualityChange(AnimationQuality newQuality) {
    // Adjust running animations based on new quality level
    final runningAnimations = _registry.activeAnimations;
    
    for (final animation in runningAnimations) {
      if (!newQuality.enableComplexEffects && _isComplexAnimation(animation)) {
        // Convert complex animations to simpler ones
        _convertToAccessibleAnimation(animation);
      }
    }
  }

  void _handleMemoryPressure() {
    // Pause low-priority animations during memory pressure
    final lowPriorityAnimations = _registry.activeAnimations.where(
      (animation) => animation.config.priority > 2
    );
    
    for (final animation in lowPriorityAnimations) {
      animation.pause();
      animation.controller.stop();
    }
  }

  void _handleAccessibilityChange() {
    // If reduced motion was just enabled, pause complex animations
    if (_reducedMotion) {
      final complexAnimations = _registry.activeAnimations.where(
        (animation) => animation.config.respectReducedMotion && 
                      _isComplexAnimation(animation)
      );
      
      for (final animation in complexAnimations) {
        // Convert to simple fade or complete instantly
        _convertToAccessibleAnimation(animation);
      }
    }
  }

  bool _isComplexAnimation(ManagedAnimation animation) {
    final config = animation.config;
    return (config.scaleStart != null && config.scaleEnd != null) ||
           (config.slideStart != null && config.slideEnd != null) ||
           config.duration.inMilliseconds > 300;
  }

  void _convertToAccessibleAnimation(ManagedAnimation animation) {
    if (_accessibilityService.shouldSkipAnimation()) {
      _completeAnimationInstantly(animation);
    } else {
      // Convert to simple fade
      final accessibleConfig = _accessibilityService.createAccessibleConfig(
        duration: animation.config.duration,
        curve: animation.config.curve,
        type: AnimationType.fade,
        priority: animation.config.priority,
      );
      
      _applyAccessibilityTiming(animation, accessibleConfig);
    }
  }

  AccessibleAnimationConfig _getAccessibleAnimationConfig(ManagedAnimation animation) {
    // Determine animation type based on config
    AnimationType type = AnimationType.fade;
    
    if (animation.config.scaleStart != null && animation.config.scaleEnd != null) {
      type = AnimationType.scale;
    } else if (animation.config.slideStart != null && animation.config.slideEnd != null) {
      type = AnimationType.slide;
    }
    
    return _accessibilityService.createAccessibleConfig(
      duration: animation.config.duration,
      curve: animation.config.curve,
      type: type,
      priority: animation.config.priority,
    );
  }

  void _completeAnimationInstantly(ManagedAnimation animation) {
    // Set controller to end value immediately
    animation.controller.value = 1.0;
    animation.complete();
    
    if (kDebugMode) {
      debugPrint('Completed animation instantly: ${animation.id}');
    }
  }

  void _startSimplifiedAnimation(ManagedAnimation animation, AccessibleAnimationConfig config) {
    // Use much shorter duration and simple curve
    animation.controller.duration = config.effectiveDuration;
    animation.start();
    animation.controller.forward();
  }

  void _startFadeAlternative(ManagedAnimation animation, AccessibleAnimationConfig config) {
    // Convert any animation to a simple fade
    animation.controller.duration = config.effectiveDuration;
    animation.start();
    animation.controller.forward();
  }

  void _applyAccessibilityTiming(ManagedAnimation animation, AccessibleAnimationConfig config) {
    // Apply accessibility-adjusted duration and curve
    animation.controller.duration = config.effectiveDuration;
    // Note: Curve changes would require recreating the animation, which is complex
    // For now, we just adjust duration
  }

  /// Manually set reduced motion preference (for testing or user settings)
  void setReducedMotionPreference(bool enabled) {
    _accessibilityService.setReducedMotionPreference(enabled);
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
    // Check device-specific concurrent animation limits
    final maxAnimations = _performanceMonitor.deviceTier.maxConcurrentAnimations;
    if (_registry.activeCount >= maxAnimations) {
      return false;
    }
    
    // Check quality-specific limits
    final qualityLimit = _performanceMonitor.currentQuality.maxSimultaneousAnimations;
    if (_registry.activeCount >= qualityLimit) {
      return false;
    }
    
    // Check performance constraints
    final metrics = _performanceMonitor.latestMetrics;
    if (metrics != null && metrics.isPerformancePoor) {
      // Only allow high priority animations when performance is poor
      return animation.config.priority <= 2;
    }
    
    return true;
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