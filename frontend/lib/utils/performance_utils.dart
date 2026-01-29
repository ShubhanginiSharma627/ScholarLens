import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Utility class for monitoring and improving app performance
class PerformanceUtils {
  static bool _isMonitoring = false;
  static final List<Duration> _frameTimes = [];
  static const int _maxFrameHistory = 60; // Keep last 60 frames
  
  /// Start monitoring frame performance
  static void startFrameMonitoring() {
    if (_isMonitoring || !kDebugMode) return;
    
    _isMonitoring = true;
    SchedulerBinding.instance.addTimingsCallback(_onFrameCallback);
    developer.log('Performance monitoring started');
  }
  
  /// Stop monitoring frame performance
  static void stopFrameMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameCallback);
    developer.log('Performance monitoring stopped');
  }
  
  /// Frame callback to track performance
  static void _onFrameCallback(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameTimes.add(frameDuration);
      
      // Keep only recent frames
      if (_frameTimes.length > _maxFrameHistory) {
        _frameTimes.removeAt(0);
      }
      
      // Log slow frames (> 16.67ms for 60fps)
      const slowFrameThreshold = Duration(milliseconds: 17);
      if (frameDuration > slowFrameThreshold) {
        developer.log(
          'Slow frame detected: ${frameDuration.inMilliseconds}ms',
          name: 'Performance',
        );
      }
      
      // Log extremely slow frames (> 100ms)
      const extremelySlowThreshold = Duration(milliseconds: 100);
      if (frameDuration > extremelySlowThreshold) {
        developer.log(
          'EXTREMELY slow frame: ${frameDuration.inMilliseconds}ms - UI likely frozen',
          name: 'Performance',
          level: 1000, // Warning level
        );
      }
    }
  }
  
  /// Get average frame time
  static Duration get averageFrameTime {
    if (_frameTimes.isEmpty) return Duration.zero;
    
    final totalMs = _frameTimes
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    
    return Duration(microseconds: totalMs ~/ _frameTimes.length);
  }
  
  /// Get current FPS estimate
  static double get currentFPS {
    final avgFrameTime = averageFrameTime;
    if (avgFrameTime == Duration.zero) return 0.0;
    
    return 1000000.0 / avgFrameTime.inMicroseconds; // Convert to FPS
  }
  
  /// Check if performance is good (>= 55 FPS)
  static bool get isPerformanceGood => currentFPS >= 55.0;
  
  /// Get performance summary
  static Map<String, dynamic> getPerformanceSummary() {
    return {
      'average_frame_time_ms': averageFrameTime.inMilliseconds,
      'current_fps': currentFPS.toStringAsFixed(1),
      'is_performance_good': isPerformanceGood,
      'frame_count': _frameTimes.length,
      'monitoring': _isMonitoring,
    };
  }
  
  /// Log performance summary
  static void logPerformanceSummary() {
    final summary = getPerformanceSummary();
    developer.log(
      'Performance Summary: ${summary.toString()}',
      name: 'Performance',
    );
  }
  
  /// Measure execution time of a function
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      developer.log(
        '$operationName completed in ${stopwatch.elapsedMilliseconds}ms',
        name: 'Performance',
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        '$operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'Performance',
        level: 1000,
      );
      rethrow;
    }
  }
  
  /// Measure execution time of a synchronous function
  static T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      
      developer.log(
        '$operationName completed in ${stopwatch.elapsedMilliseconds}ms',
        name: 'Performance',
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        '$operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'Performance',
        level: 1000,
      );
      rethrow;
    }
  }
}

/// Widget that automatically starts/stops performance monitoring
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });
  
  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled && kDebugMode) {
      PerformanceUtils.startFrameMonitoring();
    }
  }
  
  @override
  void dispose() {
    if (widget.enabled && kDebugMode) {
      PerformanceUtils.stopFrameMonitoring();
      PerformanceUtils.logPerformanceSummary();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}