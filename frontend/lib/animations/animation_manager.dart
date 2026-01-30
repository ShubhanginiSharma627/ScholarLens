import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/accessibility_service.dart';
import 'animation_config.dart';
import 'managed_animation.dart';
import 'performance_metrics.dart';
import 'theme_integration.dart';
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
  int _animationCounter = 0;
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _accessibilityService.initialize();
    _performanceMonitor.initialize();
    _setupAccessibilityListeners();
    _setupPerformanceListeners();
    _reducedMotion = _accessibilityService.isReducedMotionEnabled;
    _startPerformanceMonitoring();
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('AnimationManager initialized - '
          'reducedMotion: $_reducedMotion, '
          'performanceScale: $_performanceScale, '
          'deviceTier: ${_performanceMonitor.deviceTier}');
    }
  }
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
    if (_registry.getAnimation(id) != null) {
      final newId = _generateAnimationId(category);
      if (kDebugMode) {
        debugPrint('Animation ID collision detected, using new ID: $newId instead of $id');
      }
      return registerController(
        controller: controller,
        config: config,
        category: category,
        customId: newId,
      );
    }
    final optimizedDuration = PerformanceOptimizer.optimizeDuration(
      originalDuration: config.duration,
      quality: _performanceMonitor.currentQuality,
      deviceTier: _performanceMonitor.deviceTier,
    );
    final scaledConfig = config.copyWith(duration: optimizedDuration);
    final animation = _createAnimation(controller, scaledConfig);
    final managedAnimation = ManagedAnimation(
      id: id,
      controller: controller,
      animation: animation,
      config: scaledConfig,
      category: category,
    );
    _registry.register(managedAnimation);
    _setupControllerListeners(managedAnimation);
    if (kDebugMode) {
      debugPrint('Registered animation: $id (category: $category, '
          'quality: ${_performanceMonitor.currentQuality})');
    }
    return id;
  }
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
  void startAnimation(String id) {
    final animation = _registry.getAnimation(id);
    if (animation == null) return;
    final metrics = _performanceMonitor.getCurrentMetrics(_registry.activeCount);
    if (PerformanceOptimizer.shouldSkipAnimation(
      metrics: metrics,
      animationPriority: animation.config.priority,
    )) {
      _completeAnimationInstantly(animation);
      return;
    }
    final accessibleConfig = _getAccessibleAnimationConfig(animation);
    switch (accessibleConfig.alternative) {
      case AnimationAlternative.skip:
        _completeAnimationInstantly(animation);
        return;
      case AnimationAlternative.instant:
        _completeAnimationInstantly(animation);
        return;
      case AnimationAlternative.simple:
        _startSimplifiedAnimation(animation, accessibleConfig);
        return;
      case AnimationAlternative.fade:
        _startFadeAlternative(animation, accessibleConfig);
        return;
      case AnimationAlternative.normal:
        break;
    }
    if (!_canStartAnimation(animation)) {
      if (kDebugMode) {
        debugPrint('Skipping animation $id due to performance constraints');
      }
      return;
    }
    _applyAccessibilityTiming(animation, accessibleConfig);
    animation.start();
    animation.controller.forward();
    if (kDebugMode) {
      debugPrint('Started animation: $id (accessibility: ${accessibleConfig.alternative}, '
          'quality: ${_performanceMonitor.currentQuality})');
    }
  }
  void pauseAll() {
    for (final animation in _registry.activeAnimations) {
      animation.pause();
      animation.controller.stop();
    }
    if (kDebugMode) {
      debugPrint('Paused all animations');
    }
  }
  void resumeAll() {
    for (final animation in _registry.activeAnimations) {
      animation.resume();
      animation.controller.forward();
    }
    if (kDebugMode) {
      debugPrint('Resumed all animations');
    }
  }
  void pauseCategory(AnimationCategory category) {
    _registry.pauseCategory(category);
    if (kDebugMode) {
      debugPrint('Paused animations in category: $category');
    }
  }
  void resumeCategory(AnimationCategory category) {
    _registry.resumeCategory(category);
    if (kDebugMode) {
      debugPrint('Resumed animations in category: $category');
    }
  }
  void updatePerformanceScale(double scale) {
    _performanceScale = scale.clamp(0.1, 1.0);
    if (kDebugMode) {
      debugPrint('Updated performance scale: $_performanceScale');
    }
  }
  AnimationPerformanceMetrics getCurrentPerformanceMetrics() {
    return _performanceMonitor.getCurrentMetrics(_registry.activeCount);
  }
  AnimationConfig getThemeAwareConfig(BuildContext context, AnimationConfig baseConfig) {
    final theme = Theme.of(context);
    final adjustedDuration = theme.brightness == Brightness.dark 
        ? Duration(milliseconds: (baseConfig.duration.inMilliseconds * 0.9).round())
        : baseConfig.duration;
    return baseConfig.copyWith(duration: adjustedDuration);
  }
  ManagedAnimation? getAnimation(String id) {
    return _registry.getAnimation(id);
  }
  List<ManagedAnimation> getAnimationsByCategory(AnimationCategory category) {
    return _registry.getAnimationsByCategory(category);
  }
  List<AnimationPerformanceMetrics> get performanceHistory => 
      _performanceMonitor.history;
  AnimationRegistry get registry => _registry;
  bool get isReducedMotionEnabled => _accessibilityService.isReducedMotionEnabled;
  bool get isHighContrastEnabled => _accessibilityService.isHighContrastEnabled;
  double get textScaleFactor => _accessibilityService.textScaleFactor;
  double get performanceScale => _performanceScale;
  bool get isInitialized => _isInitialized;
  AccessibilityService get accessibilityService => _accessibilityService;
  void dispose() {
    _registry.disposeAll();
    _performanceMonitor.dispose();
    _accessibilityService.dispose();
    _isInitialized = false;
    if (kDebugMode) {
      debugPrint('AnimationManager disposed');
    }
  }
  void _setupAccessibilityListeners() {
    _accessibilityService.addReducedMotionListener(() {
      _reducedMotion = _accessibilityService.isReducedMotionEnabled;
      if (kDebugMode) {
        debugPrint('Reduced motion preference changed: $_reducedMotion');
      }
      _handleAccessibilityChange();
    });
    _accessibilityService.addHighContrastListener(() {
      if (kDebugMode) {
        debugPrint('High contrast preference changed: ${_accessibilityService.isHighContrastEnabled}');
      }
    });
  }
  void _setupPerformanceListeners() {
    _performanceMonitor.addQualityChangeListener((quality) {
      if (kDebugMode) {
        debugPrint('Animation quality changed to: $quality');
      }
      _handleQualityChange(quality);
    });
    _performanceMonitor.addMemoryPressureListener(() {
      if (kDebugMode) {
        debugPrint('Memory pressure detected - reducing animation complexity');
      }
      _handleMemoryPressure();
    });
  }
  void _handleQualityChange(AnimationQuality newQuality) {
    final runningAnimations = _registry.activeAnimations;
    for (final animation in runningAnimations) {
      if (!newQuality.enableComplexEffects && _isComplexAnimation(animation)) {
        _convertToAccessibleAnimation(animation);
      }
    }
  }
  void _handleMemoryPressure() {
    final lowPriorityAnimations = _registry.activeAnimations.where(
      (animation) => animation.config.priority > 2
    );
    for (final animation in lowPriorityAnimations) {
      animation.pause();
      animation.controller.stop();
    }
  }
  void _handleAccessibilityChange() {
    if (_reducedMotion) {
      final complexAnimations = _registry.activeAnimations.where(
        (animation) => animation.config.respectReducedMotion && 
                      _isComplexAnimation(animation)
      );
      for (final animation in complexAnimations) {
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
    animation.controller.value = 1.0;
    animation.complete();
    if (kDebugMode) {
      debugPrint('Completed animation instantly: ${animation.id}');
    }
  }
  void _startSimplifiedAnimation(ManagedAnimation animation, AccessibleAnimationConfig config) {
    animation.controller.duration = config.effectiveDuration;
    animation.start();
    animation.controller.forward();
  }
  void _startFadeAlternative(ManagedAnimation animation, AccessibleAnimationConfig config) {
    animation.controller.duration = config.effectiveDuration;
    animation.start();
    animation.controller.forward();
  }
  void _applyAccessibilityTiming(ManagedAnimation animation, AccessibleAnimationConfig config) {
    animation.controller.duration = config.effectiveDuration;
  }
  void setReducedMotionPreference(bool enabled) {
    _accessibilityService.setReducedMotionPreference(enabled);
    _reducedMotion = enabled;
    if (kDebugMode) {
      debugPrint('Manually set reduced motion preference: $_reducedMotion');
    }
  }
  void _startPerformanceMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
  }
  void _onFrameEnd(Duration timestamp) {
    final frameTime = timestamp.inMicroseconds / 1000.0;
    _performanceMonitor.recordFrameTime(frameTime);
    final metrics = _performanceMonitor.getCurrentMetrics(_registry.activeCount);
    _updatePerformanceScaleFromMetrics(metrics);
    WidgetsBinding.instance.addPostFrameCallback(_onFrameEnd);
  }
  void _updatePerformanceScaleFromMetrics(AnimationPerformanceMetrics metrics) {
    final recommendedScale = metrics.recommendedScale;
    if ((recommendedScale - _performanceScale).abs() > 0.1) {
      updatePerformanceScale(recommendedScale);
    }
  }
  String _generateAnimationId(AnimationCategory category) {
    _animationCounter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${category.name}_${timestamp}_$_animationCounter';
  }
  Animation _createAnimation(AnimationController controller, AnimationConfig config) {
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
          break;
      }
    });
  }
  bool _canStartAnimation(ManagedAnimation animation) {
    final maxAnimations = _performanceMonitor.deviceTier.maxConcurrentAnimations;
    if (_registry.activeCount >= maxAnimations) {
      return false;
    }
    final qualityLimit = _performanceMonitor.currentQuality.maxSimultaneousAnimations;
    if (_registry.activeCount >= qualityLimit) {
      return false;
    }
    final metrics = _performanceMonitor.latestMetrics;
    if (metrics != null && metrics.isPerformancePoor) {
      return animation.config.priority <= 2;
    }
    return true;
  }
}
extension AnimationManagerExtensions on AnimationManager {
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