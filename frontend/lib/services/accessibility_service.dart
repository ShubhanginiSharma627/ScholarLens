import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();
  bool _reducedMotionEnabled = false;
  bool _highContrastEnabled = false;
  double _textScaleFactor = 1.0;
  bool _isInitialized = false;
  final List<VoidCallback> _reducedMotionCallbacks = [];
  final List<VoidCallback> _highContrastCallbacks = [];
  final List<ValueChanged<double>> _textScaleCallbacks = [];
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _checkSystemPreferences();
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
      _reducedMotionEnabled = false;
      _highContrastEnabled = false;
      _textScaleFactor = 1.0;
      _isInitialized = true;
    }
  }
  bool get isReducedMotionEnabled => _reducedMotionEnabled;
  bool get isHighContrastEnabled => _highContrastEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get isInitialized => _isInitialized;
  void setReducedMotionPreference(bool enabled) {
    if (_reducedMotionEnabled != enabled) {
      _reducedMotionEnabled = enabled;
      _notifyReducedMotionCallbacks();
      if (kDebugMode) {
        debugPrint('Reduced motion preference changed: $_reducedMotionEnabled');
      }
    }
  }
  void setHighContrastPreference(bool enabled) {
    if (_highContrastEnabled != enabled) {
      _highContrastEnabled = enabled;
      _notifyHighContrastCallbacks();
      if (kDebugMode) {
        debugPrint('High contrast preference changed: $_highContrastEnabled');
      }
    }
  }
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
  void updateFromMediaQuery(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final newReducedMotion = mediaQuery.disableAnimations;
    if (_reducedMotionEnabled != newReducedMotion) {
      _reducedMotionEnabled = newReducedMotion;
      _notifyReducedMotionCallbacks();
    }
    final newHighContrast = mediaQuery.highContrast;
    if (_highContrastEnabled != newHighContrast) {
      _highContrastEnabled = newHighContrast;
      _notifyHighContrastCallbacks();
    }
    final newTextScale = mediaQuery.textScaler.scale(1.0);
    if ((_textScaleFactor - newTextScale).abs() > 0.01) {
      _textScaleFactor = newTextScale;
      _notifyTextScaleCallbacks();
    }
  }
  void addReducedMotionListener(VoidCallback callback) {
    _reducedMotionCallbacks.add(callback);
  }
  void removeReducedMotionListener(VoidCallback callback) {
    _reducedMotionCallbacks.remove(callback);
  }
  void addHighContrastListener(VoidCallback callback) {
    _highContrastCallbacks.add(callback);
  }
  void removeHighContrastListener(VoidCallback callback) {
    _highContrastCallbacks.remove(callback);
  }
  void addTextScaleListener(ValueChanged<double> callback) {
    _textScaleCallbacks.add(callback);
  }
  void removeTextScaleListener(ValueChanged<double> callback) {
    _textScaleCallbacks.remove(callback);
  }
  Duration getReducedMotionDuration(Duration originalDuration) {
    if (!_reducedMotionEnabled) return originalDuration;
    final reducedMs = (originalDuration.inMilliseconds * 0.2).round().clamp(50, 200);
    return Duration(milliseconds: reducedMs);
  }
  Curve getReducedMotionCurve(Curve originalCurve) {
    if (!_reducedMotionEnabled) return originalCurve;
    return Curves.easeInOut;
  }
  bool shouldSkipAnimation() {
    return _reducedMotionEnabled;
  }
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
  void announceMessage(String message) {
    if (kDebugMode) {
      debugPrint('Accessibility announcement: $message');
    }
    if (kDebugMode) {
      debugPrint('Screen reader announcement: $message');
    }
  }
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
  void dispose() {
    _reducedMotionCallbacks.clear();
    _highContrastCallbacks.clear();
    _textScaleCallbacks.clear();
    _isInitialized = false;
    if (kDebugMode) {
      debugPrint('AccessibilityService disposed');
    }
  }
  Future<void> _checkSystemPreferences() async {
    _reducedMotionEnabled = false;
    _highContrastEnabled = false;
    _textScaleFactor = 1.0;
  }
  void _setupPlatformChannelListeners() {
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
  Duration get effectiveDuration => shouldSkip ? Duration.zero : reducedDuration;
  Curve get effectiveCurve => shouldSkip ? Curves.linear : reducedCurve;
}
enum AnimationType {
  scale,
  slide,
  fade,
  rotation,
  loading,
  celebration,
}
enum AnimationAlternative {
  normal,    // Use normal animation
  fade,      // Use fade instead of complex movement
  instant,   // Show final state immediately
  simple,    // Use simplified version
  skip,      // Skip animation entirely
}
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
    _accessibilityService.updateFromMediaQuery(context);
  }
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
  @override
  void dispose() {
    super.dispose();
  }
  Future<void> _initializeService() async {
    await _accessibilityService.initialize();
    if (mounted) {
      _accessibilityService.updateFromMediaQuery(context);
    }
  }
}