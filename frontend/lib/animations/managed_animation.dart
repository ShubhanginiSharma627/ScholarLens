import 'package:flutter/material.dart';
import 'animation_config.dart';

/// Managed animation wrapper that tracks state and lifecycle
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

  /// Duration since animation started
  Duration? get runningDuration {
    if (startTime == null) return null;
    final endTimeToUse = endTime ?? DateTime.now();
    return endTimeToUse.difference(startTime!);
  }

  /// Whether the animation is currently active
  bool get isActive => state == AnimationState.running;

  /// Whether the animation can be safely disposed
  bool get canDispose => 
      state == AnimationState.completed || 
      state == AnimationState.idle;

  /// Starts the animation
  void start() {
    if (state == AnimationState.disposed) {
      throw StateError('Cannot start disposed animation: $id');
    }
    
    state = AnimationState.running;
    startTime = DateTime.now();
    endTime = null;
  }

  /// Pauses the animation
  void pause() {
    if (state == AnimationState.running) {
      state = AnimationState.paused;
    }
  }

  /// Resumes the animation
  void resume() {
    if (state == AnimationState.paused) {
      state = AnimationState.running;
    }
  }

  /// Completes the animation
  void complete() {
    state = AnimationState.completed;
    endTime = DateTime.now();
  }

  /// Disposes the animation and its controller
  void dispose() {
    if (state != AnimationState.disposed) {
      controller.dispose();
      state = AnimationState.disposed;
      endTime ??= DateTime.now();
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

/// Animation registry for managing multiple animations
class AnimationRegistry {
  final Map<String, ManagedAnimation> _animations = {};
  final Map<AnimationCategory, List<String>> _categorizedAnimations = {};

  /// Registers a new animation
  void register(ManagedAnimation animation) {
    if (_animations.containsKey(animation.id)) {
      throw ArgumentError('Animation with id "${animation.id}" already exists');
    }

    _animations[animation.id] = animation;
    _categorizedAnimations
        .putIfAbsent(animation.category, () => [])
        .add(animation.id);
  }

  /// Unregisters an animation
  void unregister(String id) {
    final animation = _animations.remove(id);
    if (animation != null) {
      _categorizedAnimations[animation.category]?.remove(id);
      if (_categorizedAnimations[animation.category]?.isEmpty == true) {
        _categorizedAnimations.remove(animation.category);
      }
    }
  }

  /// Gets an animation by id
  ManagedAnimation? getAnimation(String id) => _animations[id];

  /// Gets all animations in a category
  List<ManagedAnimation> getAnimationsByCategory(AnimationCategory category) {
    final ids = _categorizedAnimations[category] ?? [];
    return ids
        .map((id) => _animations[id])
        .where((animation) => animation != null)
        .cast<ManagedAnimation>()
        .toList();
  }

  /// Gets all active animations
  List<ManagedAnimation> get activeAnimations {
    return _animations.values
        .where((animation) => animation.isActive)
        .toList();
  }

  /// Gets all animations
  List<ManagedAnimation> get allAnimations => 
      List.unmodifiable(_animations.values);

  /// Total number of registered animations
  int get count => _animations.length;

  /// Number of active animations
  int get activeCount => activeAnimations.length;

  /// Disposes all animations in a category
  void disposeCategory(AnimationCategory category) {
    final animations = getAnimationsByCategory(category);
    for (final animation in animations) {
      animation.dispose();
      unregister(animation.id);
    }
  }

  /// Disposes all completed animations
  void disposeCompleted() {
    final completed = _animations.values
        .where((animation) => animation.canDispose)
        .toList();
    
    for (final animation in completed) {
      animation.dispose();
      unregister(animation.id);
    }
  }

  /// Disposes all animations
  void disposeAll() {
    for (final animation in _animations.values) {
      animation.dispose();
    }
    _animations.clear();
    _categorizedAnimations.clear();
  }

  /// Pauses all animations in a category
  void pauseCategory(AnimationCategory category) {
    final animations = getAnimationsByCategory(category);
    for (final animation in animations) {
      animation.pause();
    }
  }

  /// Resumes all animations in a category
  void resumeCategory(AnimationCategory category) {
    final animations = getAnimationsByCategory(category);
    for (final animation in animations) {
      animation.resume();
    }
  }

  /// Gets performance summary
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