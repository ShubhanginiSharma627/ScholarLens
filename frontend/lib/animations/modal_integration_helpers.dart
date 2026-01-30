import 'package:flutter/material.dart';
import 'modal_animations.dart';
class ModalIntegrationHelpers {
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
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
extension ModalExtensions on BuildContext {
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