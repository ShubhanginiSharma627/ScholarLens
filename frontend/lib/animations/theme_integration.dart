import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animation_config.dart';

/// Animation theme integration that extends AppTheme with animation-specific styling
class AnimationTheme {
  /// Animation durations that align with Material Design 3 guidelines
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationLong = Duration(milliseconds: 500);
  static const Duration durationExtraLong = Duration(milliseconds: 1000);

  /// Animation curves that provide natural motion feel
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;

  /// Theme-aware animation configurations
  static AnimationConfig getButtonPressConfig(BuildContext context) {
    final theme = Theme.of(context);
    return AnimationConfigs.buttonPress.copyWith(
      // Could customize based on theme brightness or other properties
      duration: theme.brightness == Brightness.dark 
          ? const Duration(milliseconds: 120) 
          : const Duration(milliseconds: 150),
    );
  }

  static AnimationConfig getScreenTransitionConfig(BuildContext context) {
    final theme = Theme.of(context);
    return AnimationConfigs.screenSlide.copyWith(
      // Customize transition speed based on theme
      duration: theme.brightness == Brightness.dark 
          ? const Duration(milliseconds: 250) 
          : const Duration(milliseconds: 300),
    );
  }

  static AnimationConfig getLoadingConfig(BuildContext context) {
    return AnimationConfigs.loadingSpinner.copyWith(
      // Loading animations should always be visible regardless of theme
      respectReducedMotion: false,
    );
  }

  /// Gets theme-appropriate colors for animations
  static Color getPrimaryAnimationColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getSecondaryAnimationColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color getAccentAnimationColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  static Color getErrorAnimationColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getSuccessAnimationColor(BuildContext context) {
    return AppTheme.successColor;
  }

  /// Gets theme-appropriate shadow colors for animations
  static Color getAnimationShadowColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.1);
  }

  /// Gets theme-appropriate overlay colors for animations
  static Color getAnimationOverlayColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
  }

  /// Helper methods for creating theme-aware animation values
  static double getElevationForAnimation(BuildContext context, double baseElevation) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark 
        ? baseElevation * 1.2 
        : baseElevation;
  }

  static BorderRadius getAnimationBorderRadius(BuildContext context, double radius) {
    return BorderRadius.circular(radius);
  }

  static EdgeInsets getAnimationPadding(BuildContext context, double padding) {
    return EdgeInsets.all(padding);
  }

  /// Animation timing that respects system settings
  static Duration getAdaptiveDuration(Duration baseDuration, {
    bool respectAccessibility = true,
  }) {
    // In a real implementation, this would check system animation scale
    // For now, we'll return the base duration
    return baseDuration;
  }

  /// Gets appropriate animation curve based on context
  static Curve getContextualCurve(AnimationCategory category) {
    switch (category) {
      case AnimationCategory.microInteraction:
        return curveStandard;
      case AnimationCategory.transition:
        return curveDecelerate;
      case AnimationCategory.content:
        return curveDecelerate;
      case AnimationCategory.feedback:
        return curveStandard;
      case AnimationCategory.gesture:
        return curveElastic;
    }
  }
}