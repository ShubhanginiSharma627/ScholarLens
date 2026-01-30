import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'animation_manager.dart';
import 'animation_config.dart';
class AnimatedFormInput extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final Curve animationCurve;
  final Color? focusedBorderColor;
  final Color? unfocusedBorderColor;
  final Color? focusedBackgroundColor;
  final Color? unfocusedBackgroundColor;
  final bool animateBackground;
  final bool animateBorder;
  final bool animateLabel;
  final int animationPriority;
  final bool enableHapticFeedback;
  const AnimatedFormInput({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.focusedBorderColor,
    this.unfocusedBorderColor,
    this.focusedBackgroundColor,
    this.unfocusedBackgroundColor,
    this.animateBackground = true,
    this.animateBorder = true,
    this.animateLabel = true,
    this.animationPriority = 2,
    this.enableHapticFeedback = false,
  });
  @override
  State<AnimatedFormInput> createState() => _AnimatedFormInputState();
}
class _AnimatedFormInputState extends State<AnimatedFormInput>
    with TickerProviderStateMixin {
  late final AnimationManager _animationManager;
  late final FocusNode _focusNode;
  late AnimationController _focusController;
  String? _focusAnimationId;
  Animation<Color?>? _borderColorAnimation;
  Animation<Color?>? _backgroundColorAnimation;
  Animation<Color?>? _labelColorAnimation;
  bool _isFocused = false;
  bool _isDisposed = false;
  @override
  void initState() {
    super.initState();
    _animationManager = AnimationManager();
    _focusNode = widget.focusNode ?? FocusNode();
    _initializeAnimations();
    _setupFocusListener();
  }
  void _initializeAnimations() {
    _focusController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
      _animationManager.initialize().then((_) {
        if (mounted) {
          _registerAnimations();
        }
      });
    }
  }
  void _registerAnimations() {
    try {
      final focusConfig = AnimationConfig(
        duration: widget.animationDuration,
        curve: widget.animationCurve,
        fadeStart: 0.0,
        fadeEnd: 1.0,
        priority: widget.animationPriority,
      );
      _focusAnimationId = _animationManager.registerController(
        controller: _focusController,
        config: focusConfig,
        category: AnimationCategory.microInteraction,
      );
    } catch (e) {
      debugPrint('Failed to register focus animations with manager: $e');
    }
  }
  void _createLocalAnimations() {
    if (mounted) {
      _createColorAnimations();
    }
  }
  void _createColorAnimations() {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final unfocusedBorderColor = widget.unfocusedBorderColor ?? 
        inputTheme.enabledBorder?.borderSide.color ?? 
        const Color(0xFFE5E7EB);
    final focusedBorderColor = widget.focusedBorderColor ?? 
        inputTheme.focusedBorder?.borderSide.color ?? 
        theme.colorScheme.primary;
    final unfocusedBackgroundColor = widget.unfocusedBackgroundColor ?? 
        inputTheme.fillColor ?? 
        AppTheme.surfaceColor;
    final focusedBackgroundColor = widget.focusedBackgroundColor ?? 
        unfocusedBackgroundColor;
    if (widget.animateBorder) {
      _borderColorAnimation = ColorTween(
        begin: unfocusedBorderColor,
        end: focusedBorderColor,
      ).animate(CurvedAnimation(
        parent: _focusController,
        curve: widget.animationCurve,
      ));
    } else {
      _borderColorAnimation = AlwaysStoppedAnimation(unfocusedBorderColor);
    }
    if (widget.animateBackground) {
      _backgroundColorAnimation = ColorTween(
        begin: unfocusedBackgroundColor,
        end: focusedBackgroundColor,
      ).animate(CurvedAnimation(
        parent: _focusController,
        curve: widget.animationCurve,
      ));
    } else {
      _backgroundColorAnimation = AlwaysStoppedAnimation(unfocusedBackgroundColor);
    }
    if (widget.animateLabel) {
      _labelColorAnimation = ColorTween(
        begin: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        end: focusedBorderColor,
      ).animate(CurvedAnimation(
        parent: _focusController,
        curve: widget.animationCurve,
      ));
    } else {
      _labelColorAnimation = AlwaysStoppedAnimation(
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)
      );
    }
  }
  void _setupFocusListener() {
    _focusNode.addListener(_handleFocusChange);
  }
  void _handleFocusChange() {
    if (!mounted || _isDisposed) return;
    final wasFocused = _isFocused;
    final isFocused = _focusNode.hasFocus;
    if (wasFocused != isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      if (widget.enableHapticFeedback && isFocused) {
        HapticFeedback.selectionClick();
      }
      if (isFocused) {
        _animateFocus();
      } else {
        _animateUnfocus();
      }
    }
  }
  void _animateFocus() {
    if (_focusAnimationId != null) {
      _animationManager.startAnimation(_focusAnimationId!);
    } else {
      _focusController.forward();
    }
  }
  void _animateUnfocus() {
    _focusController.reverse();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _createColorAnimations();
  }
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (_focusAnimationId != null) {
      _animationManager.disposeController(_focusAnimationId!);
    } else {
      if (_focusController.isAnimating || !_focusController.isDismissed) {
        _focusController.stop();
      }
      _focusController.dispose();
    }
    super.dispose();
  }
  InputDecoration _buildAnimatedDecoration() {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final baseDecoration = widget.decoration ?? const InputDecoration();
    return baseDecoration.copyWith(
      border: widget.animateBorder ? _buildAnimatedBorder(inputTheme.border) : baseDecoration.border,
      enabledBorder: widget.animateBorder ? _buildAnimatedBorder(inputTheme.enabledBorder) : baseDecoration.enabledBorder,
      focusedBorder: widget.animateBorder ? _buildAnimatedBorder(inputTheme.focusedBorder, focused: true) : baseDecoration.focusedBorder,
      errorBorder: baseDecoration.errorBorder ?? inputTheme.errorBorder,
      focusedErrorBorder: baseDecoration.focusedErrorBorder ?? inputTheme.focusedErrorBorder,
      fillColor: widget.animateBackground ? _backgroundColorAnimation?.value : baseDecoration.fillColor,
      filled: widget.animateBackground || baseDecoration.filled == true,
      labelStyle: widget.animateLabel 
          ? (baseDecoration.labelStyle ?? theme.textTheme.bodyMedium)?.copyWith(
              color: _labelColorAnimation?.value,
            )
          : baseDecoration.labelStyle,
      hintText: baseDecoration.hintText,
      hintStyle: baseDecoration.hintStyle,
      helperText: baseDecoration.helperText,
      helperStyle: baseDecoration.helperStyle,
      errorText: baseDecoration.errorText,
      errorStyle: baseDecoration.errorStyle,
      prefixIcon: baseDecoration.prefixIcon,
      suffixIcon: baseDecoration.suffixIcon,
      contentPadding: baseDecoration.contentPadding ?? inputTheme.contentPadding,
    );
  }
  InputBorder? _buildAnimatedBorder(InputBorder? baseBorder, {bool focused = false}) {
    if (baseBorder == null) return null;
    final animatedColor = _borderColorAnimation?.value;
    if (animatedColor == null) return baseBorder;
    if (baseBorder is OutlineInputBorder) {
      return baseBorder.copyWith(
        borderSide: baseBorder.borderSide.copyWith(
          color: animatedColor,
          width: focused ? 2.0 : baseBorder.borderSide.width,
        ),
      );
    } else if (baseBorder is UnderlineInputBorder) {
      return baseBorder.copyWith(
        borderSide: baseBorder.borderSide.copyWith(
          color: animatedColor,
          width: focused ? 2.0 : baseBorder.borderSide.width,
        ),
      );
    }
    return baseBorder;
  }
  @override
  Widget build(BuildContext context) {
    final animations = <Listenable>[
      if (_borderColorAnimation != null) _borderColorAnimation!,
      if (_backgroundColorAnimation != null) _backgroundColorAnimation!,
      if (_labelColorAnimation != null) _labelColorAnimation!,
    ];
    return AnimatedBuilder(
      animation: animations.isNotEmpty ? Listenable.merge(animations) : _focusController,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: _buildAnimatedDecoration(),
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
          style: const TextStyle(fontSize: 14), // Reduced font size
        );
      },
    );
  }
}
extension AnimatedFormInputExtensions on Widget {
  static Widget animatedTextField({
    TextEditingController? controller,
    FocusNode? focusNode,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    bool readOnly = false,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
    VoidCallback? onTap,
    Duration animationDuration = const Duration(milliseconds: 200),
    Curve animationCurve = Curves.easeInOut,
    Color? focusedBorderColor,
    Color? unfocusedBorderColor,
    Color? focusedBackgroundColor,
    Color? unfocusedBackgroundColor,
    bool animateBackground = true,
    bool animateBorder = true,
    bool animateLabel = true,
    bool enableHapticFeedback = false,
  }) {
    return AnimatedFormInput(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      focusedBorderColor: focusedBorderColor,
      unfocusedBorderColor: unfocusedBorderColor,
      focusedBackgroundColor: focusedBackgroundColor,
      unfocusedBackgroundColor: unfocusedBackgroundColor,
      animateBackground: animateBackground,
      animateBorder: animateBorder,
      animateLabel: animateLabel,
      enableHapticFeedback: enableHapticFeedback,
    );
  }
}
class AnimatedFormInputConfigs {
  static Widget standard({
    TextEditingController? controller,
    FocusNode? focusNode,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AnimatedFormInput(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      animationDuration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeInOut,
    );
  }
  static Widget email({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? labelText = 'Email',
    String? hintText = 'Enter your email address',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AnimatedFormInput(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: onChanged,
      animationDuration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeInOut,
    );
  }
  static Widget password({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? labelText = 'Password',
    String? hintText = 'Enter your password',
    bool obscureText = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    return AnimatedFormInput(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      animationDuration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeInOut,
      enableHapticFeedback: true,
    );
  }
  static Widget search({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hintText = 'Search...',
    Widget? prefixIcon = const Icon(Icons.search),
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    return AnimatedFormInput(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      animationDuration: const Duration(milliseconds: 150),
      animationCurve: Curves.easeInOut,
    );
  }
  static Widget textArea({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? labelText,
    String? hintText,
    int maxLines = 4,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return AnimatedFormInput(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        alignLabelWithHint: true,
      ),
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      onChanged: onChanged,
      animationDuration: const Duration(milliseconds: 250),
      animationCurve: Curves.easeInOut,
    );
  }
}