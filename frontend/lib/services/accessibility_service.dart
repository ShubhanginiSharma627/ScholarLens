import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Service for managing accessibility preferences and animation behavior
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _reducedMotionEnabled = false;
  bool _highContrastEnabled = false;
  double _textScaleFactor = 1.0;
  bool _isInitialized = false;

  /// Callbacks for accessibility preference changes
  final List<VoidCallback> _reducedMotionCallbacks = [];
  final List<VoidCallback> _highContrastCallbacks = [];
  final List<ValueChanged<double>> _textScaleCallbacks = [];

  /// Initialize the accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check system accessibility preferences
      await _checkSystemPreferences();
      
      // Set up platform channel listeners for preference changes
      _setupPlatformChannelListeners();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('AccessibilityService initialized - '
            'reducedMotion: $_reducedMotionEnabled, '
            'highContrast: $_highContrastEnabled, '
            'textScale: $_textScaleFactor');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing AccessibilityService: $e');
      }
      // Set safe defaults
      _reducedMotionEnabled = false;
      _highContrastEnabled = false;
      _textScaleFactor = 1.0;
      _isInitialized = true;
    }
  }

  /// Check if reduced motion is enabled
  bool get isReducedMotionEnabled => _reducedMotionEnabled;

  /// Check if high contrast is enabled
  bool get isHighContrastEnabled => _highContrastEnabled;

  /// Get current text scale factor
  double get textScaleFactor => _textScaleFactor;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Manually set reduced motion preference (for testing or user settings)
  void setReducedMotionPreference(bool enabled) {
    if (_reducedMotionEnabled != enabled) {
      _reducedMotionEnabled = enabled;
      _notifyReducedMotionCallbacks();
      
      if (kDebugMode) {
        debugPrint('Reduced motion preference changed: $_reducedMotionEnabled');
      }
    }
  }

  /// Manually set high contrast preference (for testing or user settings)
  void setHighContrastPreference(bool enabled) {
    if (_highContrastEnabled != enabled) {
      _highContrastEnabled = enabled;
      _notifyHighContrastCallbacks();
      
      if (kDebugMode) {
        debugPrint('High contrast preference changed: $_highContrastEnabled');
      }
    }
  }

  /// Manually set text scale factor (for testing or user settings)
  void setTextScaleFactor(double factor) {
    final clampedFactor = factor.clamp(0.5, 3.0);
    if (_textScaleFactor != clampedFactor) {
      _textScaleFactor = clampedFactor;
      _notifyTextScaleCallbacks();
      
      if (kDebugMode) {
        debugPrint('Text scale factor changed: $_textScaleFactor');
      }
    }
  }

  /// Update preferences from MediaQuery (called by widgets)
  void updateFromMediaQuery(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Update reduced motion from MediaQuery
    final newReducedMotion = mediaQuery.disableAnimations;
    if (_reducedMotionEnabled != newReducedMotion) {
      _reducedMotionEnabled = newReducedMotion;
      _notifyReducedMotionCallbacks();
    }
    
    // Update high contrast from MediaQuery
    final newHighContrast = mediaQuery.highContrast;
    if (_highContrastEnabled != newHighContrast) {
      _highContrastEnabled = newHighContrast;
      _notifyHighContrastCallbacks();
    }
    
    // Update text scale factor from MediaQuery
    final newTextScale = mediaQuery.textScaler.scale(1.0);
    if ((_textScaleFactor - newTextScale).abs() > 0.01) {
      _textScaleFactor = newTextScale;
      _notifyTextScaleCallbacks();
    }
  }

  /// Register callback for reduced motion changes
  void addReducedMotionListener(VoidCallback callback) {
    _reducedMotionCallbacks.add(callback);
  }

  /// Remove callback for reduced motion changes
  void removeReducedMotionListener(VoidCallback callback) {
    _reducedMotionCallbacks.remove(callback);
  }

  /// Register callback for high contrast changes
  void addHighContrastListener(VoidCallback callback) {
    _highContrastCallbacks.add(callback);
  }

  /// Remove callback for high contrast changes
  void removeHighContrastListener(VoidCallback callback) {
    _highContrastCallbacks.remove(callback);
  }

  /// Register callback for text scale changes
  void addTextScaleListener(ValueChanged<double> callback) {
    _textScaleCallbacks.add(callback);
  }

  /// Remove callback for text scale changes
  void removeTextScaleListener(ValueChanged<double> callback) {
    _textScaleCallbacks.remove(callback);
  }

  /// Get reduced motion animation duration
  Duration getReducedMotionDuration(Duration originalDuration) {
    if (!_reducedMotionEnabled) return originalDuration;
    
    // For reduced motion, use much shorter durations
    final reducedMs = (originalDuration.inMilliseconds * 0.2).round().clamp(50, 200);
    return Duration(milliseconds: reducedMs);
  }

  /// Get reduced motion animation curve
  Curve getReducedMotionCurve(Curve originalCurve) {
    if (!_reducedMotionEnabled) return originalCurve;
    
    // For reduced motion, use simple linear or ease curves
    return Curves.easeInOut;
  }

  /// Check if animation should be skipped entirely
  bool shouldSkipAnimation() {
    return _reducedMotionEnabled;
  }

  /// Get alternative animation for reduced motion
  AnimationAlternative getAnimationAlternative(AnimationType type) {
    if (!_reducedMotionEnabled) {
      return AnimationAlternative.normal;
    }
    
    switch (type) {
      case AnimationType.scale:
      case AnimationType.slide:
      case AnimationType.rotation:
        return AnimationAlternative.fade;
      case AnimationType.fade:
        return AnimationAlternative.instant;
      case AnimationType.loading:
        return AnimationAlternative.simple;
      case AnimationType.celebration:
        return AnimationAlternative.skip;
    }
  }

  /// Announce message to screen readers
  void announceMessage(String message) {
    if (kDebugMode) {
      debugPrint('Accessibility announcement: $message');
    }
    
    // Use a simple approach for screen reader announcements
    // In a real implementation, you might use a more sophisticated approach
    // or a dedicated accessibility package
    if (kDebugMode) {
      debugPrint('Screen reader announcement: $message');
    }
  }

  /// Create accessible animation configuration
  AccessibleAnimationConfig createAccessibleConfig({
    required Duration duration,
    required Curve curve,
    required AnimationType type,
    int priority = 1,
  }) {
    return AccessibleAnimationConfig(
      originalDuration: duration,
      originalCurve: curve,
      reducedDuration: getReducedMotionDuration(duration),
      reducedCurve: getReducedMotionCurve(curve),
      alternative: getAnimationAlternative(type),
      shouldSkip: shouldSkipAnimation(),
      priority: priority,
    );
  }

  /// Dispose the service
  void dispose() {
    _reducedMotionCallbacks.clear();
    _highContrastCallbacks.clear();
    _textScaleCallbacks.clear();
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('AccessibilityService disposed');
    }
  }

  // Private methods

  Future<void> _checkSystemPreferences() async {
    // In a real implementation, you would use platform channels to check
    // actual system accessibility preferences. For now, we'll use MediaQuery
    // values that will be updated when widgets call updateFromMediaQuery.
    
    // Set default values that will be updated by MediaQuery
    _reducedMotionEnabled = false;
    _highContrastEnabled = false;
    _textScaleFactor = 1.0;
  }

  void _setupPlatformChannelListeners() {
    // In a real implementation, you would set up platform channel listeners
    // to detect when system accessibility preferences change.
    // For now, we rely on MediaQuery updates from widgets.
  }

  void _notifyReducedMotionCallbacks() {
    for (final callback in _reducedMotionCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in reduced motion callback: $e');
        }
      }
    }
  }

  void _notifyHighContrastCallbacks() {
    for (final callback in _highContrastCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in high contrast callback: $e');
        }
      }
    }
  }

  void _notifyTextScaleCallbacks() {
    for (final callback in _textScaleCallbacks) {
      try {
        callback(_textScaleFactor);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in text scale callback: $e');
        }
      }
    }
  }
}

/// Configuration for accessible animations
class AccessibleAnimationConfig {
  final Duration originalDuration;
  final Duration reducedDuration;
  final Curve originalCurve;
  final Curve reducedCurve;
  final AnimationAlternative alternative;
  final bool shouldSkip;
  final int priority;

  const AccessibleAnimationConfig({
    required this.originalDuration,
    required this.reducedDuration,
    required this.originalCurve,
    required this.reducedCurve,
    required this.alternative,
    required this.shouldSkip,
    required this.priority,
  });

  /// Get the appropriate duration based on accessibility settings
  Duration get effectiveDuration => shouldSkip ? Duration.zero : reducedDuration;

  /// Get the appropriate curve based on accessibility settings
  Curve get effectiveCurve => shouldSkip ? Curves.linear : reducedCurve;
}

/// Types of animations for accessibility handling
enum AnimationType {
  scale,
  slide,
  fade,
  rotation,
  loading,
  celebration,
}

/// Alternative animation approaches for accessibility
enum AnimationAlternative {
  normal,    // Use normal animation
  fade,      // Use fade instead of complex movement
  instant,   // Show final state immediately
  simple,    // Use simplified version
  skip,      // Skip animation entirely
}

/// Widget that automatically updates accessibility service from MediaQuery
class AccessibilityServiceProvider extends StatefulWidget {
  final Widget child;

  const AccessibilityServiceProvider({
    super.key,
    required this.child,
  });

  @override
  State<AccessibilityServiceProvider> createState() => _AccessibilityServiceProviderState();
}

class _AccessibilityServiceProviderState extends State<AccessibilityServiceProvider> {
  final AccessibilityService _accessibilityService = AccessibilityService();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update accessibility service with current MediaQuery values
    _accessibilityService.updateFromMediaQuery(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    // Don't dispose the singleton service here
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _accessibilityService.initialize();
    if (mounted) {
      _accessibilityService.updateFromMediaQuery(context);
    }
  }
}