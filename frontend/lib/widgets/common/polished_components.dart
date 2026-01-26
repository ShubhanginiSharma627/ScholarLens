import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_typography.dart';
import '../../theme/responsive.dart';
import 'loading_animations.dart';

/// Collection of polished UI components with consistent styling and micro-interactions
class PolishedComponents {
  /// Enhanced card with hover effects and proper spacing
  static Widget enhancedCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    double? elevation,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingS),
      child: Material(
        color: backgroundColor ?? AppTheme.cardColor,
        elevation: elevation ?? AppTheme.elevationS,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusM),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Polished button with loading state and animations
  static Widget polishedButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isOutlined = false,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsets? padding,
    double? borderRadius,
    double? elevation,
  }) {
    return LoadingAnimations.bouncingButton(
      onPressed: onPressed ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : (backgroundColor ?? AppTheme.primaryColor),
          border: isOutlined ? Border.all(color: backgroundColor ?? AppTheme.primaryColor) : null,
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusS),
          boxShadow: !isOutlined && elevation != null ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusS),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    LoadingAnimations.circularLoader(
                      size: 16,
                      color: textColor ?? (isOutlined ? AppTheme.primaryColor : Colors.white),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                  ] else if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: textColor ?? (isOutlined ? AppTheme.primaryColor : Colors.white),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  Text(
                    text,
                    style: AppTypography.buttonMedium.copyWith(
                      color: textColor ?? (isOutlined ? AppTheme.primaryColor : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Enhanced input field with proper styling and animations
  static Widget enhancedTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    bool readOnly = false,
    int? maxLines,
    EdgeInsets? contentPadding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText,
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines ?? 1,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon != null 
                ? IconButton(
                    icon: Icon(suffixIcon),
                    onPressed: onSuffixIconTap,
                  )
                : null,
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
        ),
      ],
    );
  }

  /// Status chip with consistent styling
  static Widget statusChip({
    required String label,
    required String status,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        backgroundColor = AppTheme.successColor.withValues(alpha: 0.1);
        textColor = AppTheme.successColor;
        break;
      case 'error':
      case 'failed':
        backgroundColor = AppTheme.errorColor.withValues(alpha: 0.1);
        textColor = AppTheme.errorColor;
        break;
      case 'warning':
      case 'pending':
        backgroundColor = AppTheme.warningColor.withValues(alpha: 0.1);
        textColor = AppTheme.warningColor;
        break;
      case 'info':
      case 'active':
        backgroundColor = AppTheme.primaryColor.withValues(alpha: 0.1);
        textColor = AppTheme.primaryColor;
        break;
      default:
        backgroundColor = AppTheme.surfaceColor;
        textColor = AppTheme.secondaryTextColor;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: AppTheme.spacingXS),
              ],
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Progress indicator with label and percentage
  static Widget progressIndicator({
    required double progress,
    String? label,
    Color? color,
    Color? backgroundColor,
    double height = 8.0,
    bool showPercentage = true,
  }) {
    final progressColor = color ?? AppTheme.primaryColor;
    final bgColor = backgroundColor ?? AppTheme.surfaceColor;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label,
                  style: AppTypography.labelMedium,
                ),
              if (showPercentage)
                Text(
                  '$percentage%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Circular progress indicator with label
  static Widget circularProgress({
    required double progress,
    String? label,
    String? centerText,
    Color? color,
    Color? backgroundColor,
    double size = 80.0,
    double strokeWidth = 6.0,
  }) {
    final progressColor = color ?? AppTheme.primaryColor;
    final bgColor = backgroundColor ?? AppTheme.surfaceColor;
    final percentage = (progress * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(bgColor),
              ),
              // Progress circle
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              // Center text
              Center(
                child: Text(
                  centerText ?? '$percentage%',
                  style: AppTypography.titleMedium.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: AppTypography.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Empty state widget with illustration and action
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String description,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    return ResponsiveContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            title,
            style: AppTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onActionPressed != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            polishedButton(
              text: actionText,
              onPressed: onActionPressed,
              icon: AppIcons.add,
            ),
          ],
        ],
      ),
    );
  }

  /// Section header with optional action
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onActionPressed,
    IconData? actionIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null && onActionPressed != null)
            TextButton.icon(
              onPressed: onActionPressed,
              icon: Icon(actionIcon ?? AppIcons.arrowRight, size: 16),
              label: Text(actionText),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// Back navigation bar component with customizable title text
class BackNavigationBar extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  
  const BackNavigationBar({
    super.key,
    required this.title,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_back, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}