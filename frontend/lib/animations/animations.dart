/// Scholar Lens Animation System
/// 
/// A comprehensive animation framework that provides:
/// - Centralized animation management
/// - Performance monitoring and optimization
/// - Accessibility compliance (reduced motion support)
/// - Theme integration
/// - Predefined animation configurations
/// 
/// Usage:
/// ```dart
/// // Initialize the animation manager
/// await AnimationManager().initialize();
/// 
/// // Create and register an animation
/// final animationId = AnimationManager().createScaleAnimation(
///   vsync: this,
///   scaleStart: 1.0,
///   scaleEnd: 0.95,
/// );
/// 
/// // Start the animation
/// AnimationManager().startAnimation(animationId);
/// 
/// // Dispose when done
/// AnimationManager().disposeController(animationId);
/// ```

export 'animation_config.dart';
export 'animation_manager.dart';
export 'animated_form_input.dart';
export 'animated_interactive_element.dart';
export 'flashcard_deck_animations.dart';
export 'managed_animation.dart';
export 'performance_metrics.dart';
export 'smart_transition.dart';
export 'staggered_list_animation.dart';
export 'theme_integration.dart';