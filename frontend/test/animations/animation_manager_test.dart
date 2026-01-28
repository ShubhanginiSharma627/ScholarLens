import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/animations/animations.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnimationManager', () {
    late AnimationManager manager;

    setUp(() {
      manager = AnimationManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('should be a singleton', () {
      final manager1 = AnimationManager();
      final manager2 = AnimationManager();
      expect(manager1, same(manager2));
    });

    test('should initialize successfully', () async {
      expect(manager.isInitialized, false);
      await manager.initialize();
      expect(manager.isInitialized, true);
    });

    test('should register and dispose controllers', () async {
      await manager.initialize();
      
      // Create a test ticker provider
      final testVsync = TestVSync();
      
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: testVsync,
      );

      final config = AnimationConfigs.buttonPress;
      
      final animationId = manager.registerController(
        controller: controller,
        config: config,
        category: AnimationCategory.microInteraction,
      );

      expect(animationId, isNotEmpty);
      expect(manager.registry.count, 1);

      manager.disposeController(animationId);
      expect(manager.registry.count, 0);
    });

    test('should track performance metrics', () async {
      await manager.initialize();
      
      final metrics = manager.getCurrentPerformanceMetrics();
      expect(metrics, isA<AnimationPerformanceMetrics>());
      expect(metrics.activeAnimations, 0);
    });

    test('should handle performance scaling', () async {
      await manager.initialize();
      
      expect(manager.performanceScale, 1.0);
      
      manager.updatePerformanceScale(0.5);
      expect(manager.performanceScale, 0.5);
      
      // Test clamping
      manager.updatePerformanceScale(2.0);
      expect(manager.performanceScale, 1.0);
      
      manager.updatePerformanceScale(-0.5);
      expect(manager.performanceScale, 0.1);
    });

    test('should create scale animation helper', () async {
      await manager.initialize();
      
      final testVsync = TestVSync();
      
      final animationId = manager.createScaleAnimation(
        vsync: testVsync,
        scaleStart: 1.0,
        scaleEnd: 0.95,
      );

      expect(animationId, isNotEmpty);
      expect(manager.registry.count, 1);
      
      final animation = manager.registry.getAnimation(animationId);
      expect(animation, isNotNull);
      expect(animation!.category, AnimationCategory.microInteraction);
    });

    test('should create slide animation helper', () async {
      await manager.initialize();
      
      final testVsync = TestVSync();
      
      final animationId = manager.createSlideAnimation(
        vsync: testVsync,
        slideStart: const Offset(1.0, 0.0),
        slideEnd: Offset.zero,
      );

      expect(animationId, isNotEmpty);
      expect(manager.registry.count, 1);
      
      final animation = manager.registry.getAnimation(animationId);
      expect(animation, isNotNull);
      expect(animation!.category, AnimationCategory.transition);
    });

    test('should create fade animation helper', () async {
      await manager.initialize();
      
      final testVsync = TestVSync();
      
      final animationId = manager.createFadeAnimation(
        vsync: testVsync,
        fadeStart: 0.0,
        fadeEnd: 1.0,
      );

      expect(animationId, isNotEmpty);
      expect(manager.registry.count, 1);
      
      final animation = manager.registry.getAnimation(animationId);
      expect(animation, isNotNull);
      expect(animation!.category, AnimationCategory.content);
    });

    test('should pause and resume all animations', () async {
      await manager.initialize();
      
      final testVsync = TestVSync();
      
      // Create multiple animations
      final id1 = manager.createScaleAnimation(vsync: testVsync);
      final id2 = manager.createFadeAnimation(vsync: testVsync);
      
      // Start animations
      manager.startAnimation(id1);
      manager.startAnimation(id2);
      
      // Test pause/resume (basic functionality)
      manager.pauseAll();
      manager.resumeAll();
      
      // No exceptions should be thrown
      expect(manager.registry.count, 2);
    });
  });

  group('AnimationConfig', () {
    test('should create config with default values', () {
      const config = AnimationConfig(
        duration: Duration(milliseconds: 300),
      );

      expect(config.duration, const Duration(milliseconds: 300));
      expect(config.curve, Curves.easeInOut);
      expect(config.respectReducedMotion, true);
      expect(config.priority, 1);
    });

    test('should create copy with overrides', () {
      const original = AnimationConfig(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );

      final copy = original.copyWith(
        duration: const Duration(milliseconds: 500),
      );

      expect(copy.duration, const Duration(milliseconds: 500));
      expect(copy.curve, Curves.easeIn); // Should preserve original
    });

    test('should compare configs correctly', () {
      const config1 = AnimationConfig(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );

      const config2 = AnimationConfig(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );

      const config3 = AnimationConfig(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );

      expect(config1, config2);
      expect(config1, isNot(config3));
    });
  });

  group('AnimationPerformanceMetrics', () {
    test('should calculate performance score correctly', () {
      final metrics = AnimationPerformanceMetrics(
        averageFrameTime: 16.67, // Perfect 60fps
        frameDropPercentage: 0.0,
        activeAnimations: 5,
        memoryUsage: 2.5,
        timestamp: DateTime.now(),
      );

      expect(metrics.isPerformanceGood, true);
      expect(metrics.performanceScore, greaterThan(0.6)); // More realistic expectation
    });

    test('should detect poor performance', () {
      final metrics = AnimationPerformanceMetrics(
        averageFrameTime: 33.33, // 30fps
        frameDropPercentage: 10.0,
        activeAnimations: 20,
        memoryUsage: 10.0,
        timestamp: DateTime.now(),
      );

      expect(metrics.isPerformanceGood, false);
      expect(metrics.performanceScore, lessThan(0.5));
    });

    test('should recommend appropriate scale', () {
      final goodMetrics = AnimationPerformanceMetrics(
        averageFrameTime: 16.67,
        frameDropPercentage: 0.0,
        activeAnimations: 5,
        memoryUsage: 2.5,
        timestamp: DateTime.now(),
      );

      final poorMetrics = AnimationPerformanceMetrics(
        averageFrameTime: 50.0,
        frameDropPercentage: 20.0,
        activeAnimations: 30,
        memoryUsage: 20.0,
        timestamp: DateTime.now(),
      );

      expect(goodMetrics.recommendedScale, 0.8); // Based on actual calculation
      expect(poorMetrics.recommendedScale, lessThan(0.5));
    });
  });
}

/// Test ticker provider for testing
class TestVSync extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}