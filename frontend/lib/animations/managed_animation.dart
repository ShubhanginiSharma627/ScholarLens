import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'animation_config.dart';
class ManagedAnimation {
  final String id;
  final AnimationController controller;
  final Animation animation;
  final AnimationConfig config;
  final AnimationCategory category;
  AnimationState state;
  DateTime? startTime;
  DateTime? endTime;
  ManagedAnimation({
    required this.id,
    required this.controller,
    required this.animation,
    required this.config,
    required this.category,
    this.state = AnimationState.idle,
  });
  Duration? get runningDuration {
    if (startTime == null) return null;
    final endTimeToUse = endTime ?? DateTime.now();
    return endTimeToUse.difference(startTime!);
  }
  bool get isActive => state == AnimationState.running;
  bool get canDispose => 
      state == AnimationState.completed || 
      state == AnimationState.idle;
  void start() {
    if (state == AnimationState.disposed) {
      throw StateError('Cannot start disposed animation: $id');
    }
    state = AnimationState.running;
    startTime = DateTime.now();
    endTime = null;
  }
  void pause() {
    if (state == AnimationState.running) {
      state = AnimationState.paused;
    }
  }
  void resume() {
    if (state == AnimationState.paused) {
      state = AnimationState.running;
    }
  }
  void complete() {
    state = AnimationState.completed;
    endTime = DateTime.now();
  }
  void dispose() {
    if (state == AnimationState.disposed) {
      if (kDebugMode) {
        debugPrint('Animation already disposed: $id');
      }
      return;
    }
    state = AnimationState.disposed;
    endTime ??= DateTime.now();
    try {
      if (!controller.isDismissed && !controller.isCompleted) {
        controller.stop();
      }
      controller.dispose();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Controller disposal error for $id: $e');
      }
    }
  }
  @override
  String toString() {
    return 'ManagedAnimation('
        'id: $id, '
        'state: $state, '
        'category: $category, '
        'duration: ${runningDuration?.inMilliseconds}ms'
        ')';
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManagedAnimation && other.id == id;
  }
  @override
  int get hashCode => id.hashCode;
}
class AnimationRegistry {
  final Map<String, ManagedAnimation> _animations = {};
  final Map<AnimationCategory, List<String>> _categorizedAnimations = {};
  void register(ManagedAnimation animation) {
    if (_animations.containsKey(animation.id)) {
      throw ArgumentError('Animation with id "${animation.id}" already exists');
    }
    _animations[animation.id] = animation;
    _categorizedAnimations
        .putIfAbsent(animation.category, () => [])
        .add(animation.id);
  }
  void unregister(String id) {
    final animation = _animations.remove(id);
    if (animation != null) {
      _categorizedAnimations[animation.category]?.remove(id);
      if (_categorizedAnimations[animation.category]?.isEmpty == true) {
        _categorizedAnimations.remove(animation.category);
      }
    }
  }
  ManagedAnimation? getAnimation(String id) => _animations[id];
  List<ManagedAnimation> getAnimationsByCategory(AnimationCategory category) {
    final ids = _categorizedAnimations[category] ?? [];
    return ids
        .map((id) => _animations[id])
        .where((animation) => animation != null)
        .cast<ManagedAnimation>()
        .toList();
  }
  List<ManagedAnimation> get activeAnimations {
    return _animations.values
        .where((animation) => animation.isActive)
        .toList();
  }
  List<ManagedAnimation> get allAnimations => 
      List.unmodifiable(_animations.values);
  int get count => _animations.length;
  int get activeCount => activeAnimations.length;
  void disposeCategory(AnimationCategory category) {
    final animations = getAnimationsByCategory(category);
    for (final animation in animations) {
      animation.dispose();
      unregister(animation.id);
    }
  }
  void disposeCompleted() {
    final completed = _animations.values
        .where((animation) => animation.canDispose)
        .toList();
    for (final animation in completed) {
      animation.dispose();
      unregister(animation.id);
    }
  }
  void disposeAll() {
    for (final animation in _animations.values) {
      animation.dispose();
    }
    _animations.clear();
    _categorizedAnimations.clear();
  }
  void pauseCategory(AnimationCategory category) {
    final animations = getAnimationsByCategory(category);
    for (final animation in animations) {
      animation.pause();
    }
  }
  void resumeCategory(AnimationCategory category) {
    final animations = getAnimationsByCategory(category);
    for (final animation in animations) {
      animation.resume();
    }
  }
  Map<String, dynamic> getPerformanceSummary() {
    final byCategory = <String, int>{};
    for (final category in AnimationCategory.values) {
      final count = getAnimationsByCategory(category).length;
      if (count > 0) {
        byCategory[category.name] = count;
      }
    }
    return {
      'total': count,
      'active': activeCount,
      'byCategory': byCategory,
    };
  }
}