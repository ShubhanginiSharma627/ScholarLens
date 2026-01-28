import 'package:flutter/material.dart';
import 'package:scholar_lens/theme/responsive.dart';

/// Utility class for responsive design in chapter reading interface
class ResponsiveChapterUtils {
  /// Get responsive padding for chapter content
  static EdgeInsets getContentPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: Responsive.responsive(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
      vertical: Responsive.responsive(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }

  /// Get responsive font size for chapter content
  static double getContentFontSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
  }

  /// Get responsive line height for chapter content
  static double getContentLineHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 1.6,
      tablet: 1.7,
      desktop: 1.8,
    );
  }

  /// Get responsive header height
  static double getHeaderHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 200.0,
      tablet: 220.0,
      desktop: 240.0,
    );
  }

  /// Get responsive tool button size
  static double getToolButtonSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
    );
  }

  /// Get responsive tool button spacing
  static double getToolButtonSpacing(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// Get responsive section indicator size
  static double getSectionIndicatorSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );
  }

  /// Get responsive progress bar height
  static double getProgressBarHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 6.0,
      tablet: 8.0,
      desktop: 10.0,
    );
  }

  /// Get responsive card border radius
  static double getCardBorderRadius(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
  }

  /// Get responsive maximum content width
  static double getMaxContentWidth(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: double.infinity,
      tablet: 700.0,
      desktop: 800.0,
    );
  }

  /// Get responsive layout direction for tools
  static Axis getToolsLayoutAxis(BuildContext context) {
    return Responsive.isMobile(context) ? Axis.horizontal : Axis.horizontal;
  }

  /// Get responsive column count for grid layouts
  static int getGridColumnCount(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Check if should use compact layout
  static bool shouldUseCompactLayout(BuildContext context) {
    return Responsive.isMobile(context) && 
           MediaQuery.of(context).size.height < 700;
  }

  /// Get responsive spacing between sections
  static double getSectionSpacing(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Get responsive minimum touch target size
  static double getMinTouchTargetSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 44.0,
      tablet: 48.0,
      desktop: 52.0,
    );
  }

  /// Get responsive text scale factor
  static double getTextScaleFactor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    // Clamp text scale factor to prevent UI breaking
    return textScaleFactor.clamp(0.8, 1.3);
  }

  /// Get responsive layout constraints
  static BoxConstraints getLayoutConstraints(BuildContext context) {
    final maxWidth = getMaxContentWidth(context);
    return BoxConstraints(
      maxWidth: maxWidth,
      minHeight: 0,
    );
  }

  /// Check if orientation is landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
  }

  /// Get responsive safe area padding
  static EdgeInsets getResponsiveSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    
    return EdgeInsets.only(
      top: padding.top,
      bottom: padding.bottom,
      left: Responsive.isMobile(context) ? padding.left : 0,
      right: Responsive.isMobile(context) ? padding.right : 0,
    );
  }
}

/// Widget that provides responsive layout for chapter reading
class ResponsiveChapterLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveChapterLayout({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveChapterUtils.getContentPadding(context);
    final responsiveMaxWidth = maxWidth ?? ResponsiveChapterUtils.getMaxContentWidth(context);

    return Container(
      width: double.infinity,
      padding: responsivePadding,
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
                child: child,
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
              child: child,
            ),
    );
  }
}

/// Widget that adapts layout based on orientation
class OrientationAwareLayout extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;
  final bool forcePortraitOnMobile;

  const OrientationAwareLayout({
    super.key,
    required this.portrait,
    this.landscape,
    this.forcePortraitOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveChapterUtils.isLandscape(context);
    final isMobile = Responsive.isMobile(context);

    // Force portrait layout on mobile devices for better reading experience
    if (isMobile && forcePortraitOnMobile) {
      return portrait;
    }

    if (isLandscape && landscape != null) {
      return landscape!;
    }

    return portrait;
  }
}