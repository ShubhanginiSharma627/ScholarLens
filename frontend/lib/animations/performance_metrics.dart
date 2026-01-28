import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;

/// Performance metrics for animation monitoring
class AnimationPerformanceMetrics {
  final double averageFrameTime;
  final double frameDropPercentage;
  final int activeAnimations;
  final double memoryUsage;
  final double cpuUsage;
  final DevicePerformanceTier deviceTier;
  final DateTime timestamp;

  const AnimationPerformanceMetrics({
    required this.averageFrameTime,
    required this.frameDropPercentage,
    required this.activeAnimations,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.deviceTier,
    required this.timestamp,
  });

  /// Returns true if performance is considered good (60fps target)
  bool get isPerformanceGood => 
      averageFrameTime <= 16.67 && frameDropPercentage < 5.0;

  /// Returns true if performance is poor and needs intervention
  bool get isPerformancePoor =>
      averageFrameTime > 33.33 || frameDropPercentage > 20.0;

  /// Returns performance quality score (0.0 to 1.0)
  double get performanceScore {
    final frameScore = (16.67 - averageFrameTime.clamp(0, 33.33)) / 16.67;
    final dropScore = (100 - frameDropPercentage.clamp(0, 100)) / 100;
    final animationScore = activeAnimations < 10 ? 1.0 : 10.0 / activeAnimations;
    final memoryScore = memoryUsage < 50 ? 1.0 : (100 - memoryUsage.clamp(0, 100)) / 50;
    final cpuScore = cpuUsage < 50 ? 1.0 : (100 - cpuUsage.clamp(0, 100)) / 50;
    
    return (frameScore + dropScore + animationScore + memoryScore + cpuScore) / 5.0;
  }

  /// Returns recommended performance scale factor (0.1 to 1.0)
  double get recommendedScale {
    final score = performanceScore;
    final deviceMultiplier = deviceTier.performanceMultiplier;
    
    double baseScale;
    if (score > 0.8) {
      baseScale = 1.0;
    } else if (score > 0.6) {
      baseScale = 0.8;
    } else if (score > 0.4) {
      baseScale = 0.6;
    } else if (score > 0.2) {
      baseScale = 0.4;
    } else {
      baseScale = 0.2;
    }
    
    return (baseScale * deviceMultiplier).clamp(0.1, 1.0);
  }

  /// Returns recommended animation quality level
  AnimationQuality get recommendedQuality {
    final score = performanceScore;
    if (score > 0.8) {
      return AnimationQuality.high;
    }
    if (score > 0.6) {
      return AnimationQuality.medium;
    }
    if (score > 0.3) {
      return AnimationQuality.low;
    }
    return AnimationQuality.minimal;
  }

  /// Returns true if memory pressure is high
  bool get isMemoryPressureHigh => memoryUsage > 80.0;

  /// Returns true if CPU usage is high
  bool get isCpuUsageHigh => cpuUsage > 80.0;

  @override
  String toString() {
    return 'AnimationPerformanceMetrics('
        'frameTime: ${averageFrameTime.toStringAsFixed(2)}ms, '
        'dropRate: ${frameDropPercentage.toStringAsFixed(1)}%, '
        'activeAnimations: $activeAnimations, '
        'memoryUsage: ${memoryUsage.toStringAsFixed(1)}MB, '
        'cpuUsage: ${cpuUsage.toStringAsFixed(1)}%, '
        'deviceTier: $deviceTier, '
        'score: ${performanceScore.toStringAsFixed(2)}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimationPerformanceMetrics &&
        other.averageFrameTime == averageFrameTime &&
        other.frameDropPercentage == frameDropPercentage &&
        other.activeAnimations == activeAnimations &&
        other.memoryUsage == memoryUsage &&
        other.cpuUsage == cpuUsage &&
        other.deviceTier == deviceTier &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      averageFrameTime,
      frameDropPercentage,
      activeAnimations,
      memoryUsage,
      cpuUsage,
      deviceTier,
      timestamp,
    );
  }
}

/// Performance monitor for tracking animation performance with adaptive quality management
class AnimationPerformanceMonitor {
  static final AnimationPerformanceMonitor _instance = 
      AnimationPerformanceMonitor._internal();
  factory AnimationPerformanceMonitor() => _instance;
  AnimationPerformanceMonitor._internal();

  final List<double> _frameTimes = [];
  final List<AnimationPerformanceMetrics> _history = [];
  final List<double> _memoryUsageHistory = [];
  final List<double> _cpuUsageHistory = [];
  
  int _frameDrops = 0;
  int _totalFrames = 0;
  DevicePerformanceTier? _deviceTier;
  Timer? _memoryMonitorTimer;
  Timer? _performanceEvaluationTimer;
  
  // Performance thresholds
  static const int _maxHistorySize = 100;
  static const int _maxFrameTimesSample = 60; // 1 second at 60fps
  static const int _maxMemorySample = 30; // 30 seconds of memory samples
  static const double _memoryPressureThreshold = 80.0; // MB
  
  // Callbacks for performance changes
  final List<ValueChanged<AnimationQuality>> _qualityChangeCallbacks = [];
  final List<VoidCallback> _memoryPressureCallbacks = [];
  
  AnimationQuality _currentQuality = AnimationQuality.high;
  bool _isMemoryPressureActive = false;

  /// Initialize the performance monitor
  void initialize() {
    _detectDevicePerformanceTier();
    _startMemoryMonitoring();
    _startPerformanceEvaluation();
    
    if (kDebugMode) {
      debugPrint('AnimationPerformanceMonitor initialized - deviceTier: $_deviceTier');
    }
  }

  /// Records a frame time measurement
  void recordFrameTime(double frameTimeMs) {
    _frameTimes.add(frameTimeMs);
    if (_frameTimes.length > _maxFrameTimesSample) {
      _frameTimes.removeAt(0);
    }

    _totalFrames++;
    if (frameTimeMs > 16.67) { // Dropped frame at 60fps
      _frameDrops++;
    }
  }

  /// Gets current performance metrics
  AnimationPerformanceMetrics getCurrentMetrics(int activeAnimations) {
    final averageFrameTime = _frameTimes.isEmpty 
        ? 16.67 
        : _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    
    final frameDropPercentage = _totalFrames == 0 
        ? 0.0 
        : (_frameDrops / _totalFrames) * 100;

    final memoryUsage = _getAverageMemoryUsage();
    final cpuUsage = _getAverageCpuUsage();

    final metrics = AnimationPerformanceMetrics(
      averageFrameTime: averageFrameTime,
      frameDropPercentage: frameDropPercentage,
      activeAnimations: activeAnimations,
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      deviceTier: _deviceTier ?? DevicePerformanceTier.medium,
      timestamp: DateTime.now(),
    );

    _addToHistory(metrics);
    return metrics;
  }

  /// Gets current animation quality level
  AnimationQuality get currentQuality => _currentQuality;

  /// Gets device performance tier
  DevicePerformanceTier get deviceTier => _deviceTier ?? DevicePerformanceTier.medium;

  /// Checks if memory pressure is currently active
  bool get isMemoryPressureActive => _isMemoryPressureActive;

  /// Adds callback for quality changes
  void addQualityChangeListener(ValueChanged<AnimationQuality> callback) {
    _qualityChangeCallbacks.add(callback);
  }

  /// Removes callback for quality changes
  void removeQualityChangeListener(ValueChanged<AnimationQuality> callback) {
    _qualityChangeCallbacks.remove(callback);
  }

  /// Adds callback for memory pressure events
  void addMemoryPressureListener(VoidCallback callback) {
    _memoryPressureCallbacks.add(callback);
  }

  /// Removes callback for memory pressure events
  void removeMemoryPressureListener(VoidCallback callback) {
    _memoryPressureCallbacks.remove(callback);
  }

  /// Forces a specific animation quality level
  void forceQuality(AnimationQuality quality) {
    if (_currentQuality != quality) {
      _currentQuality = quality;
      _notifyQualityChange();
      
      if (kDebugMode) {
        debugPrint('Animation quality forced to: $quality');
      }
    }
  }

  /// Enables adaptive quality management
  void enableAdaptiveQuality() {
    _startPerformanceEvaluation();
  }

  /// Disables adaptive quality management
  void disableAdaptiveQuality() {
    _performanceEvaluationTimer?.cancel();
  }

  /// Gets performance history
  List<AnimationPerformanceMetrics> get history => List.unmodifiable(_history);

  /// Gets the latest performance metrics
  AnimationPerformanceMetrics? get latestMetrics => 
      _history.isEmpty ? null : _history.last;

  /// Resets performance counters
  void reset() {
    _frameTimes.clear();
    _memoryUsageHistory.clear();
    _cpuUsageHistory.clear();
    _frameDrops = 0;
    _totalFrames = 0;
    _isMemoryPressureActive = false;
  }

  /// Clears performance history
  void clearHistory() {
    _history.clear();
  }

  /// Disposes the performance monitor
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _performanceEvaluationTimer?.cancel();
    _qualityChangeCallbacks.clear();
    _memoryPressureCallbacks.clear();
    reset();
  }

  // Private methods

  void _detectDevicePerformanceTier() {
    // Simplified device detection - in a real app, you'd use more sophisticated methods
    try {
      if (kIsWeb) {
        _deviceTier = DevicePerformanceTier.medium;
      } else if (Platform.isIOS) {
        // iOS devices generally have good performance
        _deviceTier = DevicePerformanceTier.high;
      } else if (Platform.isAndroid) {
        // Android varies widely - default to medium
        _deviceTier = DevicePerformanceTier.medium;
      } else {
        _deviceTier = DevicePerformanceTier.medium;
      }
    } catch (e) {
      _deviceTier = DevicePerformanceTier.medium;
    }
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordMemoryUsage();
    });
  }

  void _startPerformanceEvaluation() {
    _performanceEvaluationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _evaluatePerformanceAndAdjustQuality();
    });
  }

  void _recordMemoryUsage() {
    // Simplified memory usage estimation
    // In a real app, you'd use platform channels to get actual memory usage
    final estimatedUsage = _frameTimes.length * 0.1 + _history.length * 0.05;
    
    _memoryUsageHistory.add(estimatedUsage);
    if (_memoryUsageHistory.length > _maxMemorySample) {
      _memoryUsageHistory.removeAt(0);
    }

    // Simplified CPU usage estimation
    final averageFrameTime = _frameTimes.isEmpty ? 16.67 : 
        _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final cpuUsage = (averageFrameTime / 16.67) * 50; // Rough estimate
    
    _cpuUsageHistory.add(cpuUsage);
    if (_cpuUsageHistory.length > _maxMemorySample) {
      _cpuUsageHistory.removeAt(0);
    }

    // Check for memory pressure
    final currentMemoryPressure = estimatedUsage > _memoryPressureThreshold;
    if (currentMemoryPressure != _isMemoryPressureActive) {
      _isMemoryPressureActive = currentMemoryPressure;
      if (_isMemoryPressureActive) {
        _notifyMemoryPressure();
      }
    }
  }

  void _evaluatePerformanceAndAdjustQuality() {
    if (_history.isEmpty) return;

    final latestMetrics = _history.last;
    final recommendedQuality = latestMetrics.recommendedQuality;

    if (recommendedQuality != _currentQuality) {
      _currentQuality = recommendedQuality;
      _notifyQualityChange();
      
      if (kDebugMode) {
        debugPrint('Animation quality adjusted to: $recommendedQuality '
            '(score: ${latestMetrics.performanceScore.toStringAsFixed(2)})');
      }
    }
  }

  double _getAverageMemoryUsage() {
    if (_memoryUsageHistory.isEmpty) return 0.0;
    return _memoryUsageHistory.reduce((a, b) => a + b) / _memoryUsageHistory.length;
  }

  double _getAverageCpuUsage() {
    if (_cpuUsageHistory.isEmpty) return 0.0;
    return _cpuUsageHistory.reduce((a, b) => a + b) / _cpuUsageHistory.length;
  }

  void _addToHistory(AnimationPerformanceMetrics metrics) {
    _history.add(metrics);
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  void _notifyQualityChange() {
    for (final callback in _qualityChangeCallbacks) {
      try {
        callback(_currentQuality);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in quality change callback: $e');
        }
      }
    }
  }

  void _notifyMemoryPressure() {
    for (final callback in _memoryPressureCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in memory pressure callback: $e');
        }
      }
    }
  }

  /// Logs performance metrics in debug mode
  void logMetrics() {
    if (kDebugMode && _history.isNotEmpty) {
      final latest = _history.last;
      debugPrint('Animation Performance: $latest');
    }
  }
}

/// Device performance tier classification
enum DevicePerformanceTier {
  low,
  medium,
  high,
}

extension DevicePerformanceTierExtension on DevicePerformanceTier {
  /// Performance multiplier for this tier
  double get performanceMultiplier {
    switch (this) {
      case DevicePerformanceTier.low:
        return 0.6;
      case DevicePerformanceTier.medium:
        return 0.8;
      case DevicePerformanceTier.high:
        return 1.0;
    }
  }

  /// Maximum concurrent animations for this tier
  int get maxConcurrentAnimations {
    switch (this) {
      case DevicePerformanceTier.low:
        return 5;
      case DevicePerformanceTier.medium:
        return 10;
      case DevicePerformanceTier.high:
        return 20;
    }
  }

  /// Recommended frame rate target for this tier
  double get targetFrameRate {
    switch (this) {
      case DevicePerformanceTier.low:
        return 30.0;
      case DevicePerformanceTier.medium:
        return 60.0;
      case DevicePerformanceTier.high:
        return 60.0;
    }
  }
}

/// Animation quality levels for adaptive performance
enum AnimationQuality {
  minimal,  // Only essential animations, very short durations
  low,      // Basic animations, reduced complexity
  medium,   // Standard animations, some effects disabled
  high,     // Full animations with all effects
}

extension AnimationQualityExtension on AnimationQuality {
  /// Duration multiplier for this quality level
  double get durationMultiplier {
    switch (this) {
      case AnimationQuality.minimal:
        return 0.3;
      case AnimationQuality.low:
        return 0.5;
      case AnimationQuality.medium:
        return 0.8;
      case AnimationQuality.high:
        return 1.0;
    }
  }

  /// Whether complex effects should be enabled
  bool get enableComplexEffects {
    switch (this) {
      case AnimationQuality.minimal:
      case AnimationQuality.low:
        return false;
      case AnimationQuality.medium:
      case AnimationQuality.high:
        return true;
    }
  }

  /// Whether particle effects should be enabled
  bool get enableParticleEffects {
    switch (this) {
      case AnimationQuality.minimal:
      case AnimationQuality.low:
      case AnimationQuality.medium:
        return false;
      case AnimationQuality.high:
        return true;
    }
  }

  /// Whether staggered animations should be enabled
  bool get enableStaggeredAnimations {
    switch (this) {
      case AnimationQuality.minimal:
        return false;
      case AnimationQuality.low:
      case AnimationQuality.medium:
      case AnimationQuality.high:
        return true;
    }
  }

  /// Maximum number of simultaneous animations for this quality
  int get maxSimultaneousAnimations {
    switch (this) {
      case AnimationQuality.minimal:
        return 2;
      case AnimationQuality.low:
        return 5;
      case AnimationQuality.medium:
        return 10;
      case AnimationQuality.high:
        return 20;
    }
  }
}

/// Performance optimization strategies
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  /// Optimizes animation configuration based on current performance
  static AnimationQuality optimizeForPerformance({
    required AnimationPerformanceMetrics metrics,
    required AnimationQuality currentQuality,
  }) {
    // If performance is good, allow higher quality
    if (metrics.isPerformanceGood && currentQuality != AnimationQuality.high) {
      return _upgradeQuality(currentQuality);
    }
    
    // If performance is poor, reduce quality
    if (metrics.isPerformancePoor && currentQuality != AnimationQuality.minimal) {
      return _downgradeQuality(currentQuality);
    }
    
    return currentQuality;
  }

  /// Calculates optimal animation duration based on performance
  static Duration optimizeDuration({
    required Duration originalDuration,
    required AnimationQuality quality,
    required DevicePerformanceTier deviceTier,
  }) {
    final qualityMultiplier = quality.durationMultiplier;
    final deviceMultiplier = deviceTier.performanceMultiplier;
    final totalMultiplier = qualityMultiplier * deviceMultiplier;
    
    final optimizedMs = (originalDuration.inMilliseconds * totalMultiplier).round();
    return Duration(milliseconds: optimizedMs.clamp(50, originalDuration.inMilliseconds));
  }

  /// Determines if an animation should be skipped based on performance
  static bool shouldSkipAnimation({
    required AnimationPerformanceMetrics metrics,
    required int animationPriority,
  }) {
    // Skip low priority animations if performance is poor
    if (metrics.isPerformancePoor && animationPriority > 2) {
      return true;
    }
    
    // Skip all but essential animations if memory pressure is high
    if (metrics.isMemoryPressureHigh && animationPriority > 1) {
      return true;
    }
    
    return false;
  }

  static AnimationQuality _upgradeQuality(AnimationQuality current) {
    switch (current) {
      case AnimationQuality.minimal:
        return AnimationQuality.low;
      case AnimationQuality.low:
        return AnimationQuality.medium;
      case AnimationQuality.medium:
        return AnimationQuality.high;
      case AnimationQuality.high:
        return AnimationQuality.high;
    }
  }

  static AnimationQuality _downgradeQuality(AnimationQuality current) {
    switch (current) {
      case AnimationQuality.high:
        return AnimationQuality.medium;
      case AnimationQuality.medium:
        return AnimationQuality.low;
      case AnimationQuality.low:
        return AnimationQuality.minimal;
      case AnimationQuality.minimal:
        return AnimationQuality.minimal;
    }
  }
}