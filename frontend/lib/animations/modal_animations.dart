import 'package:flutter/material.dart';
import 'animation_config.dart';
class ModalAnimations {
  static Future<T?> showEnhancedModal<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Offset? triggerPosition,
    Duration? duration,
    Curve? curve,
    Color? barrierColor,
    bool barrierDismissible = true,
    String? barrierLabel,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _EnhancedModalTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          triggerPosition: triggerPosition,
          curve: curve ?? Curves.easeOutBack,
          child: child,
        );
      },
    );
  }
  static Future<T?> showEnhancedDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Offset? triggerPosition,
    Duration? duration,
    Curve? curve,
    Color? barrierColor,
    bool barrierDismissible = true,
    String? barrierLabel,
  }) {
    return showEnhancedModal<T>(
      context: context,
      builder: (context) => Dialog(
        child: builder(context),
      ),
      triggerPosition: triggerPosition,
      duration: duration,
      curve: curve,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
    );
  }
  static Future<T?> showEnhancedAlertDialog<T>({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    Offset? triggerPosition,
    Duration? duration,
    Curve? curve,
    Color? barrierColor,
    bool barrierDismissible = true,
  }) {
    return showEnhancedDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: content,
        actions: actions,
      ),
      triggerPosition: triggerPosition,
      duration: duration,
      curve: curve,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
    );
  }
  static Offset? getWidgetPosition(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      return Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
    }
    return null;
  }
}
class _EnhancedModalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Offset? triggerPosition;
  final Curve curve;
  final Widget child;
  const _EnhancedModalTransition({
    required this.animation,
    required this.secondaryAnimation,
    this.triggerPosition,
    required this.curve,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    final startPosition = triggerPosition ?? screenCenter;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: curve.flipped,
    );
    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ));
    final positionAnimation = Tween<Offset>(
      begin: Offset(
        (startPosition.dx - screenCenter.dx) / screenSize.width,
        (startPosition.dy - screenCenter.dy) / screenSize.height,
      ),
      end: Offset.zero,
    ).animate(curvedAnimation);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            FadeTransition(
              opacity: fadeAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
              ),
            ),
            Center(
              child: Transform.translate(
                offset: Offset(
                  positionAnimation.value.dx * screenSize.width,
                  positionAnimation.value.dy * screenSize.height,
                ),
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: this.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
class BottomSheetAnimations {
  static Future<T?> showEnhancedBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Duration? duration,
    Curve? curve,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool enableBlur = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => _EnhancedBottomSheetContent(
        enableBlur: enableBlur,
        child: builder(context),
      ),
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      transitionAnimationController: _createBottomSheetAnimationController(
        context,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeOutCubic,
      ),
    );
  }
  static AnimationController _createBottomSheetAnimationController(
    BuildContext context, {
    required Duration duration,
    required Curve curve,
  }) {
    final controller = AnimationController(
      duration: duration,
      reverseDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
      vsync: Navigator.of(context),
    );
    return controller;
  }
}
class _EnhancedBottomSheetContent extends StatelessWidget {
  final Widget child;
  final bool enableBlur;
  const _EnhancedBottomSheetContent({
    required this.child,
    this.enableBlur = true,
  });
  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (enableBlur) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: content,
        ),
      );
    }
    return content;
  }
}
class OverlayAnimations {
  static OverlayEntry showEnhancedOverlay({
    required BuildContext context,
    required WidgetBuilder builder,
    Duration? duration,
    Curve? curve,
    VoidCallback? onDismiss,
  }) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _EnhancedOverlay(
        duration: duration ?? const Duration(milliseconds: 250),
        curve: curve ?? Curves.easeInOut,
        onDismiss: () {
          overlayEntry.remove();
          onDismiss?.call();
        },
        child: builder(context),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    return overlayEntry;
  }
}
class _EnhancedOverlay extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onDismiss;
  const _EnhancedOverlay({
    required this.child,
    required this.duration,
    required this.curve,
    this.onDismiss,
  });
  @override
  State<_EnhancedOverlay> createState() => _EnhancedOverlayState();
}
class _EnhancedOverlayState extends State<_EnhancedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    _controller.forward();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.5 * _fadeAnimation.value),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent dismissal when tapping content
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class ModalAnimationConfigs {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Curve defaultCurve = Curves.easeOutBack;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const AnimationConfig alertDialog = AnimationConfig(
    duration: defaultDuration,
    curve: defaultCurve,
    scaleStart: 0.0,
    scaleEnd: 1.0,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 1,
  );
  static const AnimationConfig bottomSheet = AnimationConfig(
    duration: Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    slideStart: Offset(0.0, 1.0),
    slideEnd: Offset.zero,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 1,
  );
  static const AnimationConfig overlay = AnimationConfig(
    duration: Duration(milliseconds: 250),
    curve: Curves.easeInOut,
    fadeStart: 0.0,
    fadeEnd: 1.0,
    priority: 2,
  );
}