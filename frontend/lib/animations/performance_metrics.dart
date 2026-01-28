import 'package:flutter/foundation.dart';

/// Performance metrics for animation monitoring
class AnimationPerformanceMetrics {
  final double averageFrameTime;
  final double frameDropPercentage;
  final int activeAnimations;
  final double memoryUsage;
  final DateTime timestamp;

  const AnimationPerformanceMetrics({
    required this.averageFrameTime,
    required this.frameDropPercentage,
    required this.activeAnimations,
    required this.memoryUsage,
    required this.timestamp,
  });

  /// Returns true if performance is considered good (60fps target)
  bool get isPerformanceGood => 
      averageFrameTime <= 16.67 && frameDropPercentage < 5.0;

  /// Returns performance quality score (0.0 to 1.0)
  double get performanceScore {
    final frameScore = (16.67 - averageFrameTime.clamp(0, 33.33)) / 16.67;
    final dropScore = (100 - frameDropPercentage.clamp(0, 100)) / 100;
    final animationScore = activeAnimations < 10 ? 1.0 : 10.0 / activeAnimations;
    
    return (frameScore + dropScore + animationScore) / 3.0;
  }

  /// Returns recommended performance scale factor (0.1 to 1.0)
  double get recommendedScale {
    final score = performanceScore;
    if (score > 0.8) return 1.0;
    if (score > 0.6) return 0.8;
    if (score > 0.4) return 0.6;
    if (score > 0.2) return 0.4;
    return 0.2;
  }

  @override
  String toString() {
    return 'AnimationPerformanceMetrics('
        'frameTime: ${averageFrameTime.toStringAsFixed(2)}ms, '
        'dropRate: ${frameDropPercentage.toStringAsFixed(1)}%, '
        'activeAnimations: $activeAnimations, '
        'memoryUsage: ${memoryUsage.toStringAsFixed(1)}MB, '
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
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      averageFrameTime,
      frameDropPercentage,
      activeAnimations,
      memoryUsage,
      timestamp,
    );
  }
}

/// Performance monitor for tracking animation performance
class AnimationPerformanceMonitor {
  static final AnimationPerformanceMonitor _instance = 
      AnimationPerformanceMonitor._internal();
  factory AnimationPerformanceMonitor() => _instance;
  AnimationPerformanceMonitor._internal();

  final List<double> _frameTimes = [];
  final List<AnimationPerformanceMetrics> _history = [];
  int _frameDrops = 0;
  int _totalFrames = 0;
  DateTime? _lastFrameTime;

  static const int _maxHistorySize = 100;
  static const int _maxFrameTimesSample = 60; // 1 second at 60fps

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

    _lastFrameTime = DateTime.now();
  }

  /// Gets current performance metrics
  AnimationPerformanceMetrics getCurrentMetrics(int activeAnimations) {
    final averageFrameTime = _frameTimes.isEmpty 
        ? 16.67 
        : _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    
    final frameDropPercentage = _totalFrames == 0 
        ? 0.0 
        : (_frameDrops / _totalFrames) * 100;

    // Estimate memory usage (simplified)
    final memoryUsage = activeAnimations * 0.5; // Rough estimate in MB

    final metrics = AnimationPerformanceMetrics(
      averageFrameTime: averageFrameTime,
      frameDropPercentage: frameDropPercentage,
      activeAnimations: activeAnimations,
      memoryUsage: memoryUsage,
      timestamp: DateTime.now(),
    );

    _addToHistory(metrics);
    return metrics;
  }

  /// Gets performance history
  List<AnimationPerformanceMetrics> get history => List.unmodifiable(_history);

  /// Gets the latest performance metrics
  AnimationPerformanceMetrics? get latestMetrics => 
      _history.isEmpty ? null : _history.last;

  /// Resets performance counters
  void reset() {
    _frameTimes.clear();
    _frameDrops = 0;
    _totalFrames = 0;
    _lastFrameTime = null;
  }

  /// Clears performance history
  void clearHistory() {
    _history.clear();
  }

  void _addToHistory(AnimationPerformanceMetrics metrics) {
    _history.add(metrics);
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
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