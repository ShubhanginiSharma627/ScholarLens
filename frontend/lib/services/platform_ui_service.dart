import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io';
class PlatformUIService {
  static PlatformUIService? _instance;
  static PlatformUIService get instance => _instance ??= PlatformUIService._();
  PlatformUIService._();
  TargetPlatform get currentPlatform => Platform.isIOS 
      ? TargetPlatform.iOS 
      : TargetPlatform.android;
  bool get isIOS => Platform.isIOS;
  bool get isAndroid => Platform.isAndroid;
  ThemeData getPlatformTheme({
    required ColorScheme colorScheme,
    bool useMaterial3 = true,
  }) {
    if (isIOS) {
      return _getIOSTheme(colorScheme, useMaterial3);
    } else {
      return _getAndroidTheme(colorScheme, useMaterial3);
    }
  }
  PreferredSizeWidget getPlatformAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: actions != null && actions.isNotEmpty 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              )
            : null,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor,
      );
    } else {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      );
    }
  }
  Widget getPlatformButton({
    required String text,
    required VoidCallback? onPressed,
    bool isPrimary = true,
    IconData? icon,
    Color? color,
  }) {
    if (isIOS) {
      if (icon != null) {
        return CupertinoButton.filled(
          onPressed: onPressed,
          color: color,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(text),
            ],
          ),
        );
      } else {
        return isPrimary
            ? CupertinoButton.filled(
                onPressed: onPressed,
                color: color,
                child: Text(text),
              )
            : CupertinoButton(
                onPressed: onPressed,
                child: Text(text),
              );
      }
    } else {
      if (icon != null) {
        return isPrimary
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(text),
                style: color != null 
                    ? ElevatedButton.styleFrom(backgroundColor: color)
                    : null,
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(text),
              );
      } else {
        return isPrimary
            ? ElevatedButton(
                onPressed: onPressed,
                style: color != null 
                    ? ElevatedButton.styleFrom(backgroundColor: color)
                    : null,
                child: Text(text),
              )
            : OutlinedButton(
                onPressed: onPressed,
                child: Text(text),
              );
      }
    }
  }
  Widget getPlatformDialog({
    required String title,
    required String content,
    List<PlatformDialogAction>? actions,
  }) {
    if (isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions?.map((action) => CupertinoDialogAction(
          onPressed: action.onPressed,
          isDefaultAction: action.isDefault,
          isDestructiveAction: action.isDestructive,
          child: Text(action.text),
        )).toList() ?? [],
      );
    } else {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions?.map((action) => TextButton(
          onPressed: action.onPressed,
          style: action.isDestructive 
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: Text(action.text),
        )).toList() ?? [],
      );
    }
  }
  Future<T?> showPlatformDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    List<PlatformDialogAction>? actions,
    bool barrierDismissible = true,
  }) {
    if (isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => getPlatformDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => getPlatformDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    }
  }
  Widget getPlatformLoadingIndicator({
    Color? color,
    double? size,
  }) {
    if (isIOS) {
      return CupertinoActivityIndicator(
        color: color,
        radius: size != null ? size / 2 : 10,
      );
    } else {
      return CircularProgressIndicator(
        color: color,
        strokeWidth: 3,
      );
    }
  }
  Widget getPlatformSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) {
    if (isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
      );
    }
  }
  Widget getPlatformSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    Color? activeColor,
  }) {
    if (isIOS) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: activeColor,
      );
    } else {
      return Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        thumbColor: activeColor,
      );
    }
  }
  Widget getPlatformTextField({
    TextEditingController? controller,
    String? placeholder,
    String? labelText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
    int? maxLines = 1,
  }) {
    if (isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        suffix: suffixIcon,
        prefix: prefixIcon,
        maxLines: maxLines,
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
      );
    } else {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: placeholder,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
          border: const OutlineInputBorder(),
        ),
      );
    }
  }
  Future<T?> showPlatformBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
  }) {
    if (isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: SafeArea(child: child),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (context) => child,
      );
    }
  }
  PageRouteBuilder<T> getPlatformPageRoute<T>({
    required Widget child,
    RouteSettings? settings,
  }) {
    if (isIOS) {
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      );
    } else {
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      );
    }
  }
  void setPlatformStatusBarStyle({
    Brightness? brightness,
    Color? backgroundColor,
  }) {
    if (isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarBrightness: brightness,
          statusBarIconBrightness: brightness == Brightness.dark 
              ? Brightness.light 
              : Brightness.dark,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: backgroundColor ?? Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark 
              ? Brightness.light 
              : Brightness.dark,
        ),
      );
    }
  }
  void providePlatformHapticFeedback(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
  ThemeData _getIOSTheme(ColorScheme colorScheme, bool useMaterial3) {
    return ThemeData(
      useMaterial3: useMaterial3,
      colorScheme: colorScheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: colorScheme.primary,
        brightness: colorScheme.brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  ThemeData _getAndroidTheme(ColorScheme colorScheme, bool useMaterial3) {
    return ThemeData(
      useMaterial3: useMaterial3,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: useMaterial3 ? 0 : 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(useMaterial3 ? 20 : 4),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(useMaterial3 ? 12 : 4),
        ),
      ),
    );
  }
}
class PlatformDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
  const PlatformDialogAction({
    required this.text,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });
}
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}
mixin PlatformUIMixin<T extends StatefulWidget> on State<T> {
  PlatformUIService get platformUI => PlatformUIService.instance;
  Future<T?> showPlatformDialog<T>({
    required String title,
    required String content,
    List<PlatformDialogAction>? actions,
  }) {
    return platformUI.showPlatformDialog<T>(
      context: context,
      title: title,
      content: content,
      actions: actions,
    );
  }
  Future<T?> showPlatformBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return platformUI.showPlatformBottomSheet<T>(
      context: context,
      child: child,
      isScrollControlled: isScrollControlled,
    );
  }
  void hapticFeedback(HapticFeedbackType type) {
    platformUI.providePlatformHapticFeedback(type);
  }
  Future<T?> pushWithPlatformTransition<T>(Widget child) {
    return Navigator.of(context).push<T>(
      platformUI.getPlatformPageRoute<T>(child: child),
    );
  }
}