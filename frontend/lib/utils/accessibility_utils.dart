import 'package:flutter/material.dart';
import 'dart:math' as math;
class AccessibilityUtils {
  static const double minTouchTargetSize = 44.0;
  static const double minContrastRatio = 4.5;
  static const double minLargeTextContrastRatio = 3.0;
  static String createProgressLabel(double progress, {String? context}) {
    final percentage = (progress * 100).round();
    final baseLabel = '$percentage percent complete';
    return context != null ? '$context: $baseLabel' : baseLabel;
  }
  static String createSectionLabel(int currentSection, int totalSections) {
    return 'Section $currentSection of $totalSections';
  }
  static String createReadingTimeLabel(Duration readingTime) {
    final minutes = readingTime.inMinutes;
    final seconds = readingTime.inSeconds % 60;
    if (minutes > 0) {
      return seconds > 0 
          ? 'Reading time: $minutes minutes and $seconds seconds'
          : 'Reading time: $minutes minutes';
    } else {
      return 'Reading time: $seconds seconds';
    }
  }
  static String createHighlightCountLabel(int count) {
    if (count == 0) return 'No highlights';
    if (count == 1) return '1 highlight';
    return '$count highlights';
  }
  static String createBookmarkLabel(bool isBookmarked) {
    return isBookmarked ? 'Section bookmarked' : 'Bookmark this section';
  }
  static String createCompletionLabel(bool isCompleted) {
    return isCompleted ? 'Section completed' : 'Section in progress';
  }
  static String createAITutorLabel(bool isAvailable) {
    return isAvailable 
        ? 'Ask AI tutor about this section'
        : 'AI tutor is temporarily unavailable';
  }
  static String createHighlightModeLabel(bool isActive) {
    return isActive 
        ? 'Highlight mode active. Select text to highlight.'
        : 'Activate highlight mode to select text';
  }
  static Widget ensureMinTouchTarget({
    required Widget child,
    double? minSize,
    VoidCallback? onTap,
  }) {
    final targetSize = minSize ?? minTouchTargetSize;
    return SizedBox(
      width: targetSize,
      height: targetSize,
      child: onTap != null
          ? GestureDetector(
              onTap: onTap,
              child: child,
            )
          : child,
    );
  }
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String semanticLabel,
    String? tooltip,
    bool isSelected = false,
    bool isEnabled = true,
    double? minSize,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: tooltip,
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      child: ensureMinTouchTarget(
        minSize: minSize,
        child: Tooltip(
          message: tooltip ?? semanticLabel,
          child: child,
        ),
      ),
    );
  }
  static Widget createAccessibleProgress({
    required double value,
    required String label,
    Widget? child,
    Color? backgroundColor,
    Color? valueColor,
  }) {
    return Semantics(
      label: label,
      value: createProgressLabel(value),
      child: child ?? LinearProgressIndicator(
        value: value,
        backgroundColor: backgroundColor,
        valueColor: valueColor != null 
            ? AlwaysStoppedAnimation<Color>(valueColor)
            : null,
      ),
    );
  }
  static Widget createAccessibleText({
    required String text,
    TextStyle? style,
    String? semanticLabel,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
  static Widget createAccessibleIcon({
    required IconData icon,
    required String semanticLabel,
    double? size,
    Color? color,
  }) {
    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
  static Widget createAccessibleCard({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    bool isFocusable = true,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      focusable: isFocusable,
      child: Card(
        color: backgroundColor,
        shape: borderRadius != null
            ? RoundedRectangleBorder(borderRadius: borderRadius)
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
  static Widget createAccessibleListItem({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
    bool isSelected = false,
    bool isEnabled = true,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      selected: isSelected,
      enabled: isEnabled,
      child: ListTile(
        onTap: isEnabled ? onTap : null,
        selected: isSelected,
        title: child,
      ),
    );
  }
  static void announceMessage(String message) {
    debugPrint('Accessibility announcement: $message');
  }
  static FocusNode createManagedFocusNode() {
    return FocusNode();
  }
  static bool isHighContrastMode(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  static double getAccessibleTextScale(BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler;
    return textScaler.scale(1.0);
  }
  static Widget createAccessibleScaffold({
    required Widget body,
    PreferredSizeWidget? appBar,
    Widget? floatingActionButton,
    Widget? drawer,
    Widget? endDrawer,
    Widget? bottomNavigationBar,
    Color? backgroundColor,
    bool resizeToAvoidBottomInset = true,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
  static Widget createAccessibleNavigation({
    required List<Widget> children,
    String? semanticLabel,
    Axis direction = Axis.horizontal,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Semantics(
      label: semanticLabel ?? 'Navigation',
      child: direction == Axis.horizontal
          ? Row(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            )
          : Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            ),
    );
  }
  static bool hasValidContrast(Color foreground, Color background, {bool isLargeText = false}) {
    final requiredRatio = isLargeText ? minLargeTextContrastRatio : minContrastRatio;
    final actualRatio = _calculateContrastRatio(foreground, background);
    return actualRatio >= requiredRatio;
  }
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    return (lighter + 0.05) / (darker + 0.05);
  }
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round().clamp(0, 255) / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round().clamp(0, 255) / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round().clamp(0, 255) / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  static double _linearizeColorComponent(double component) {
    return component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }
}
extension DoubleExtension on double {
  double pow(double exponent) {
    return math.pow(this, exponent).toDouble();
  }
}