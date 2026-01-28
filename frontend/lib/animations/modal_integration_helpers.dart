import 'package:flutter/material.dart';
import 'modal_animations.dart';

/// Integration helpers for using enhanced modal animations throughout the app
class ModalIntegrationHelpers {
  /// Shows an enhanced confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Offset? triggerPosition,
    IconData? icon,
    Color? iconColor,
  }) {
    return ModalAnimations.showEnhancedAlertDialog<bool>(
      context: context,
      triggerPosition: triggerPosition,
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Shows an enhanced error dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    Offset? triggerPosition,
  }) {
    return ModalAnimations.showEnhancedAlertDialog(
      context: context,
      triggerPosition: triggerPosition,
      title: Row(
        children: [
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Shows an enhanced success dialog
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    Offset? triggerPosition,
  }) {
    return ModalAnimations.showEnhancedAlertDialog(
      context: context,
      triggerPosition: triggerPosition,
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Shows an enhanced loading dialog
  static Future<T?> showLoadingDialog<T>({
    required BuildContext context,
    required String message,
    Offset? triggerPosition,
    bool barrierDismissible = false,
  }) {
    return ModalAnimations.showEnhancedDialog<T>(
      context: context,
      triggerPosition: triggerPosition,
      barrierDismissible: barrierDismissible,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows an enhanced options bottom sheet
  static Future<T?> showOptionsBottomSheet<T>({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption<T>> options,
    bool enableBlur = true,
  }) {
    return BottomSheetAnimations.showEnhancedBottomSheet<T>(
      context: context,
      enableBlur: enableBlur,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Options
            ...options.map((option) => ListTile(
              leading: option.icon != null ? Icon(option.icon) : null,
              title: Text(option.title),
              subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
              onTap: () => Navigator.of(context).pop(option.value),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Shows an enhanced custom bottom sheet
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool enableBlur = true,
    bool enableDrag = true,
    bool isDismissible = true,
  }) {
    return BottomSheetAnimations.showEnhancedBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      enableBlur: enableBlur,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
    );
  }

  /// Shows an enhanced overlay with custom content
  static OverlayEntry showCustomOverlay({
    required BuildContext context,
    required WidgetBuilder builder,
    Duration? duration,
    VoidCallback? onDismiss,
  }) {
    return OverlayAnimations.showEnhancedOverlay(
      context: context,
      builder: builder,
      duration: duration,
      onDismiss: onDismiss,
    );
  }
}

/// Option for bottom sheet menus
class BottomSheetOption<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final T value;

  const BottomSheetOption({
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
  });
}

/// Extension methods for easier modal usage
extension ModalExtensions on BuildContext {
  /// Shows an enhanced confirmation dialog
  Future<bool?> showEnhancedConfirmation({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Offset? triggerPosition,
    IconData? icon,
    Color? iconColor,
  }) {
    return ModalIntegrationHelpers.showConfirmationDialog(
      context: this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      triggerPosition: triggerPosition,
      icon: icon,
      iconColor: iconColor,
    );
  }

  /// Shows an enhanced error dialog
  Future<void> showEnhancedError({
    required String title,
    required String message,
    String buttonText = 'OK',
    Offset? triggerPosition,
  }) {
    return ModalIntegrationHelpers.showErrorDialog(
      context: this,
      title: title,
      message: message,
      buttonText: buttonText,
      triggerPosition: triggerPosition,
    );
  }

  /// Shows an enhanced success dialog
  Future<void> showEnhancedSuccess({
    required String title,
    required String message,
    String buttonText = 'OK',
    Offset? triggerPosition,
  }) {
    return ModalIntegrationHelpers.showSuccessDialog(
      context: this,
      title: title,
      message: message,
      buttonText: buttonText,
      triggerPosition: triggerPosition,
    );
  }

  /// Shows an enhanced loading dialog
  Future<T?> showEnhancedLoading<T>({
    required String message,
    Offset? triggerPosition,
    bool barrierDismissible = false,
  }) {
    return ModalIntegrationHelpers.showLoadingDialog<T>(
      context: this,
      message: message,
      triggerPosition: triggerPosition,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Shows an enhanced options bottom sheet
  Future<T?> showEnhancedOptions<T>({
    required String title,
    required List<BottomSheetOption<T>> options,
    bool enableBlur = true,
  }) {
    return ModalIntegrationHelpers.showOptionsBottomSheet<T>(
      context: this,
      title: title,
      options: options,
      enableBlur: enableBlur,
    );
  }

  /// Shows an enhanced custom bottom sheet
  Future<T?> showEnhancedBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool enableBlur = true,
    bool enableDrag = true,
    bool isDismissible = true,
  }) {
    return ModalIntegrationHelpers.showCustomBottomSheet<T>(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      enableBlur: enableBlur,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
    );
  }

  /// Shows an enhanced overlay
  OverlayEntry showEnhancedOverlay({
    required WidgetBuilder builder,
    Duration? duration,
    VoidCallback? onDismiss,
  }) {
    return ModalIntegrationHelpers.showCustomOverlay(
      context: this,
      builder: builder,
      duration: duration,
      onDismiss: onDismiss,
    );
  }
}