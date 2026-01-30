import 'package:flutter/material.dart';
import 'package:scholar_lens/theme/responsive.dart';
class ResponsiveChapterUtils {
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
  static double getContentFontSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );
  }
  static double getContentLineHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 1.6,
      tablet: 1.7,
      desktop: 1.8,
    );
  }
  static double getHeaderHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 200.0,
      tablet: 220.0,
      desktop: 240.0,
    );
  }
  static double getToolButtonSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
    );
  }
  static double getToolButtonSpacing(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }
  static double getSectionIndicatorSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );
  }
  static double getProgressBarHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 6.0,
      tablet: 8.0,
      desktop: 10.0,
    );
  }
  static double getCardBorderRadius(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
  }
  static double getMaxContentWidth(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: double.infinity,
      tablet: 700.0,
      desktop: 800.0,
    );
  }
  static Axis getToolsLayoutAxis(BuildContext context) {
    return Responsive.isMobile(context) ? Axis.horizontal : Axis.horizontal;
  }
  static int getGridColumnCount(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }
  static bool shouldUseCompactLayout(BuildContext context) {
    return Responsive.isMobile(context) && 
           MediaQuery.of(context).size.height < 700;
  }
  static double getSectionSpacing(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }
  static double getMinTouchTargetSize(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: 44.0,
      tablet: 48.0,
      desktop: 52.0,
    );
  }
  static double getTextScaleFactor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    return textScaleFactor.clamp(0.8, 1.3);
  }
  static BoxConstraints getLayoutConstraints(BuildContext context) {
    final maxWidth = getMaxContentWidth(context);
    return BoxConstraints(
      maxWidth: maxWidth,
      minHeight: 0,
    );
  }
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  static double getAppBarHeight(BuildContext context) {
    return Responsive.responsive(
      context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
  }
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
    if (isMobile && forcePortraitOnMobile) {
      return portrait;
    }
    if (isLandscape && landscape != null) {
      return landscape!;
    }
    return portrait;
  }
}