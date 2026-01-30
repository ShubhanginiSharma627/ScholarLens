import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animation_config.dart';
class AnimationTheme {
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationLong = Duration(milliseconds: 500);
  static const Duration durationExtraLong = Duration(milliseconds: 1000);
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;
  static AnimationConfig getButtonPressConfig(BuildContext context) {
    final theme = Theme.of(context);
    return AnimationConfigs.buttonPress.copyWith(
      duration: theme.brightness == Brightness.dark 
          ? const Duration(milliseconds: 120) 
          : const Duration(milliseconds: 150),
    );
  }
  static AnimationConfig getScreenTransitionConfig(BuildContext context) {
    final theme = Theme.of(context);
    return AnimationConfigs.screenSlide.copyWith(
      duration: theme.brightness == Brightness.dark 
          ? const Duration(milliseconds: 250) 
          : const Duration(milliseconds: 300),
    );
  }
  static AnimationConfig getLoadingConfig(BuildContext context) {
    return AnimationConfigs.loadingSpinner.copyWith(
      respectReducedMotion: false,
    );
  }
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
  static Color getAnimationShadowColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.1);
  }
  static Color getAnimationOverlayColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
  }
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
  static Duration getAdaptiveDuration(Duration baseDuration, {
    bool respectAccessibility = true,
  }) {
    return baseDuration;
  }
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