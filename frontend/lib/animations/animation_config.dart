import 'package:flutter/material.dart';

/// Configuration class for animations with timing, curves, and behavior settings
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final double? scaleStart;
  final double? scaleEnd;
  final Offset? slideStart;
  final Offset? slideEnd;
  final double? fadeStart;
  final double? fadeEnd;
  final bool respectReducedMotion;
  final int priority; // For performance management (1 = highest, 5 = lowest)

  const AnimationConfig({
    required this.duration,
    this.curve = Curves.easeInOut,
    this.scaleStart,
    this.scaleEnd,
    this.slideStart,
    this.slideEnd,
    this.fadeStart,
    this.fadeEnd,
    this.respectReducedMotion = true,
    this.priority = 1,
  });

  /// Creates a copy of this config with optional parameter overrides
  AnimationConfig copyWith({
    Duration? duration,
    Curve? curve,
    double? scaleStart,
    double? scaleEnd,
    Offset? slideStart,
    Offset? slideEnd,
    double? fadeStart,
    double? fadeEnd,
    bool? respectReducedMotion,
    int? priority,
  }) {
    return AnimationConfig(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      scaleStart: scaleStart ?? this.scaleStart,
      scaleEnd: scaleEnd ?? this.scaleEnd,
      slideStart: slideStart ?? this.slideStart,
      slideEnd: slideEnd ?? this.slideEnd,
      fadeStart: fadeStart ?? this.fadeStart,
      fadeEnd: fadeEnd ?? this.fadeEnd,
      respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimationConfig &&
        other.duration == duration &&
        other.curve == curve &&
        other.scaleStart == scaleStart &&
        other.scaleEnd == scaleEnd &&
        other.slideStart == slideStart &&
        other.slideEnd == slideEnd &&
        other.fadeStart == fadeStart &&
        other.fadeEnd == fadeEnd &&
        other.respectReducedMotion == respectReducedMotion &&
        other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(
      duration,
      curve,
      scaleStart,
      scaleEnd,
      slideStart,
      slideEnd,
      fadeStart,
      fadeEnd,
      respectReducedMotion,
      priority,
    );
  }
}

/// Predefined animation configurations for common use cases
class AnimationConfigs {
  // Interactive element animations
  static const AnimationConfig buttonPress = AnimationConfig(
    duration: Duration(milliseconds: 150),
    curve: Curves.easeInOut,
    scaleStart: 1.0,
    scaleEnd: 0.95,
    priority: 1,
  );

  static const AnimationConfig buttonRelease = AnimationConfig(
    duration: Duration(milliseconds: 200),
    curve: Curves.elasticOut,
    scaleStart: 0.95,
    scaleEnd: 1.0,
    priority: 1,
  );

  static const AnimationConfig hoverEffect = AnimationConfig(
    duration: Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    priority: 2,
  );

  static const AnimationConfig focusTransition = AnimationConfig(
    duration: Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    priority: 2,
  );

  // Screen transition animations
  static const AnimationConfig screenSlide = AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    slideStart: Offset(1.0, 0.0),
    slideEnd: Offset.zero,
    priority: 1,
  );

  static const AnimationConfig modalSlideUp = AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
    slideStart: Offset(0.0, 1.0),
    slideEnd: Offset.zero,
    priority: 1,
  );

  static const AnimationConfig fadeTransition = AnimationConfig(
    duration: Duration(milliseconds: 250),
    curve: Curves.easeInOut,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 1,
  );

  // Content animations
  static const AnimationConfig listItemStagger = AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    slideStart: Offset(0.0, 0.3),
    slideEnd: Offset.zero,
    priority: 3,
  );

  static const AnimationConfig cardAppear = AnimationConfig(
    duration: Duration(milliseconds: 400),
    curve: Curves.elasticOut,
    scaleStart: 0.8,
    scaleEnd: 1.0,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 3,
  );

  // Loading animations
  static const AnimationConfig loadingSpinner = AnimationConfig(
    duration: Duration(milliseconds: 1000),
    curve: Curves.linear,
    respectReducedMotion: false, // Always show loading feedback
    priority: 2,
  );

  static const AnimationConfig progressBar = AnimationConfig(
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    priority: 2,
  );

  static const AnimationConfig skeletonShimmer = AnimationConfig(
    duration: Duration(milliseconds: 1500),
    curve: Curves.easeInOut,
    respectReducedMotion: false, // Always show loading feedback
    priority: 4,
  );

  // Chat animations
  static const AnimationConfig messageSlideInUser = AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
    slideStart: Offset(0.3, 0.0),
    slideEnd: Offset.zero,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 2,
  );

  static const AnimationConfig messageSlideInAI = AnimationConfig(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
    slideStart: Offset(-0.3, 0.0),
    slideEnd: Offset.zero,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 2,
  );

  static const AnimationConfig typingIndicator = AnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    priority: 3,
  );

  // Flashcard animations
  static const AnimationConfig flashcardFlip = AnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.easeInOut,
    priority: 1,
  );

  static const AnimationConfig flashcardSwipe = AnimationConfig(
    duration: Duration(milliseconds: 400),
    curve: Curves.easeOut,
    priority: 1,
  );

  static const AnimationConfig difficultyRating = AnimationConfig(
    duration: Duration(milliseconds: 250),
    curve: Curves.elasticOut,
    scaleStart: 1.0,
    scaleEnd: 1.2,
    priority: 2,
  );

  // Celebration animations
  static const AnimationConfig celebration = AnimationConfig(
    duration: Duration(milliseconds: 1000),
    curve: Curves.elasticOut,
    priority: 1,
  );

  static const AnimationConfig particleEffect = AnimationConfig(
    duration: Duration(milliseconds: 2000),
    curve: Curves.easeOut,
    priority: 4,
  );
}

/// Animation state enumeration
enum AnimationState {
  idle,
  running,
  paused,
  completed,
  disposed,
}

/// Transition type enumeration for smart transitions
enum TransitionType {
  adaptive,     // Chooses based on platform and context
  slide,        // Slide transition
  fade,         // Fade transition
  scale,        // Scale transition
  slideUp,      // Modal-style slide up
  custom,       // Custom transition
}

/// Animation category for performance management
enum AnimationCategory {
  microInteraction,  // Button presses, hover effects
  transition,        // Screen changes, modal presentations
  content,          // List loading, card appearances
  feedback,         // Loading states, progress indicators
  gesture,          // Swipe responses, drag feedback
}