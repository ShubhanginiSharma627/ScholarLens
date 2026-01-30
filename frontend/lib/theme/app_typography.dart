import 'package:flutter/material.dart';
import 'app_theme.dart';
class AppTypography {
  static const String fontFamily = 'Inter';
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.2,
    letterSpacing: -0.25,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.25,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.4,
    color: AppTheme.secondaryTextColor,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppTheme.primaryTextColor,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppTheme.secondaryTextColor,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    height: 1.3,
    letterSpacing: 0.4,
    color: AppTheme.secondaryTextColor,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: medium,
    height: 1.6,
    letterSpacing: 1.5,
    color: AppTheme.secondaryTextColor,
  );
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.1,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.1,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: semiBold,
    height: 1.25,
    letterSpacing: 0.1,
  );
  static TextStyle displayLargeDark = displayLarge.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle displayMediumDark = displayMedium.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle displaySmallDark = displaySmall.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle headlineLargeDark = headlineLarge.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle headlineMediumDark = headlineMedium.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle headlineSmallDark = headlineSmall.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle titleLargeDark = titleLarge.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle titleMediumDark = titleMedium.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle titleSmallDark = titleSmall.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle bodyLargeDark = bodyLarge.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle bodyMediumDark = bodyMedium.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle bodySmallDark = bodySmall.copyWith(
    color: AppTheme.darkSecondaryTextColor,
  );
  static TextStyle labelLargeDark = labelLarge.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle labelMediumDark = labelMedium.copyWith(
    color: AppTheme.darkPrimaryTextColor,
  );
  static TextStyle labelSmallDark = labelSmall.copyWith(
    color: AppTheme.darkSecondaryTextColor,
  );
  static TextStyle captionDark = caption.copyWith(
    color: AppTheme.darkSecondaryTextColor,
  );
  static TextStyle overlineDark = overline.copyWith(
    color: AppTheme.darkSecondaryTextColor,
  );
  static TextStyle getTextStyle(BuildContext context, String styleName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (styleName) {
      case 'displayLarge':
        return isDark ? displayLargeDark : displayLarge;
      case 'displayMedium':
        return isDark ? displayMediumDark : displayMedium;
      case 'displaySmall':
        return isDark ? displaySmallDark : displaySmall;
      case 'headlineLarge':
        return isDark ? headlineLargeDark : headlineLarge;
      case 'headlineMedium':
        return isDark ? headlineMediumDark : headlineMedium;
      case 'headlineSmall':
        return isDark ? headlineSmallDark : headlineSmall;
      case 'titleLarge':
        return isDark ? titleLargeDark : titleLarge;
      case 'titleMedium':
        return isDark ? titleMediumDark : titleMedium;
      case 'titleSmall':
        return isDark ? titleSmallDark : titleSmall;
      case 'bodyLarge':
        return isDark ? bodyLargeDark : bodyLarge;
      case 'bodyMedium':
        return isDark ? bodyMediumDark : bodyMedium;
      case 'bodySmall':
        return isDark ? bodySmallDark : bodySmall;
      case 'labelLarge':
        return isDark ? labelLargeDark : labelLarge;
      case 'labelMedium':
        return isDark ? labelMediumDark : labelMedium;
      case 'labelSmall':
        return isDark ? labelSmallDark : labelSmall;
      case 'caption':
        return isDark ? captionDark : caption;
      case 'overline':
        return isDark ? overlineDark : overline;
      default:
        return isDark ? bodyMediumDark : bodyMedium;
    }
  }
  static TextStyle responsive(BuildContext context, TextStyle baseStyle) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    double scaleFactor = 1.0;
    if (screenWidth < 600) {
      scaleFactor = 0.9;
    } else if (screenWidth < 900) {
      scaleFactor = 1.0;
    } else {
      scaleFactor = 1.1;
    }
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scaleFactor,
    );
  }
}
extension TextStyleExtensions on TextStyle {
  TextStyle get primary => copyWith(color: AppTheme.primaryColor);
  TextStyle get secondary => copyWith(color: AppTheme.secondaryColor);
  TextStyle get accent => copyWith(color: AppTheme.accentColor);
  TextStyle get error => copyWith(color: AppTheme.errorColor);
  TextStyle get success => copyWith(color: AppTheme.successColor);
  TextStyle get warning => copyWith(color: AppTheme.warningColor);
  TextStyle get white => copyWith(color: Colors.white);
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
}