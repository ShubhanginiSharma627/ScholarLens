import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'animation_manager.dart';
import 'animation_config.dart';

/// An enhanced form input widget that provides smooth color transition animations
/// for focus states, integrating with the existing InputDecorationTheme.
/// 
/// This widget implements:
/// - Smooth border color transitions on focus/unfocus
/// - Background color animation support
/// - Integration with existing InputDecorationTheme
/// - Performance-optimized animations through AnimationManager
/// - Accessibility compliance with reduced motion preferences
class AnimatedFormInput extends StatefulWidget {
  /// The text editing controller
  final TextEditingController? controller;
  
  /// The focus node for managing focus state
  final FocusNode? focusNode;
  
  /// Input decoration configuration
  final InputDecoration? decoration;
  
  /// Text input type
  final TextInputType? keyboardType;
  
  /// Text input action
  final TextInputAction? textInputAction;
  
  /// Whether the text should be obscured (for passwords)
  final bool obscureText;
  
  /// Whether the input is read-only
  final bool readOnly;
  
  /// Maximum number of lines
  final int? maxLines;
  
  /// Minimum number of lines
  final int? minLines;
  
  /// Maximum length of input
  final int? maxLength;
  
  /// Text capitalization
  final TextCapitalization textCapitalization;
  
  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;
  
  /// Validation function
  final String? Function(String?)? validator;
  
  /// Callback when the input value changes
  final void Function(String)? onChanged;
  
  /// Callback when editing is complete
  final void Function(String)? onFieldSubmitted;
  
  /// Callback when the input is tapped
  final VoidCallback? onTap;
  
  /// Duration for focus/unfocus animations (default: 200ms)
  final Duration animationDuration;
  
  /// Curve for focus animations (default: easeInOut)
  final Curve animationCurve;
  
  /// Custom focused border color (overrides theme)
  final Color? focusedBorderColor;
  
  /// Custom unfocused border color (overrides theme)
  final Color? unfocusedBorderColor;
  
  /// Custom focused background color
  final Color? focusedBackgroundColor;
  
  /// Custom unfocused background color
  final Color? unfocusedBackgroundColor;
  
  /// Whether to animate the background color
  final bool animateBackground;
  
  /// Whether to animate the border color
  final bool animateBorder;
  
  /// Whether to animate the label color
  final bool animateLabel;
  
  /// Priority for animation performance management
  final int animationPriority;
  
  /// Whether to enable haptic feedback on focus
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
  
  // Animation controllers and IDs
  late AnimationController _focusController;
  String? _focusAnimationId;
  
  // Animation values - initialize with default values
  Animation<Color?>? _borderColorAnimation;
  Animation<Color?>? _backgroundColorAnimation;
  Animation<Color?>? _labelColorAnimation;
  
  // State tracking
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
    // Initialize focus animation controller
    _focusController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Register animation with the manager if it's initialized
    if (_animationManager.isInitialized) {
      _registerAnimations();
    } else {
      // Initialize the manager and then register animations
      _animationManager.initialize().then((_) {
        if (mounted) {
          _registerAnimations();
        }
      });
    }
    
    // Don't create color animations here - wait for didChangeDependencies
  }

  void _registerAnimations() {
    try {
      // Register focus animation
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
      
      // Color animations will be created in didChangeDependencies
    } catch (e) {
      // Fallback to local animations if registration fails
      debugPrint('Failed to register focus animations with manager: $e');
    }
  }

  void _createLocalAnimations() {
    // Only create color animations if we have access to theme
    if (mounted) {
      _createColorAnimations();
    }
  }

  void _createColorAnimations() {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    
    // Get colors from theme or widget properties
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
    
    // Create border color animation
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
    
    // Create background color animation
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
    
    // Create label color animation
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
      
      // Provide haptic feedback if enabled
      if (widget.enableHapticFeedback && isFocused) {
        HapticFeedback.selectionClick();
      }
      
      // Animate focus state
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
    // Create color animations when theme is available
    _createColorAnimations();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    // Remove focus listener first
    _focusNode.removeListener(_handleFocusChange);
    
    // Dispose focus node if we created it
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    
    // Dispose animations through manager if registered, otherwise dispose directly
    if (_focusAnimationId != null) {
      _animationManager.disposeController(_focusAnimationId!);
    } else {
      // Only dispose controller if it wasn't managed by AnimationManager
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
      // Animated border
      border: widget.animateBorder ? _buildAnimatedBorder(inputTheme.border) : baseDecoration.border,
      enabledBorder: widget.animateBorder ? _buildAnimatedBorder(inputTheme.enabledBorder) : baseDecoration.enabledBorder,
      focusedBorder: widget.animateBorder ? _buildAnimatedBorder(inputTheme.focusedBorder, focused: true) : baseDecoration.focusedBorder,
      errorBorder: baseDecoration.errorBorder ?? inputTheme.errorBorder,
      focusedErrorBorder: baseDecoration.focusedErrorBorder ?? inputTheme.focusedErrorBorder,
      
      // Animated background color
      fillColor: widget.animateBackground ? _backgroundColorAnimation?.value : baseDecoration.fillColor,
      filled: widget.animateBackground || baseDecoration.filled == true,
      
      // Animated label color
      labelStyle: widget.animateLabel 
          ? (baseDecoration.labelStyle ?? theme.textTheme.bodyMedium)?.copyWith(
              color: _labelColorAnimation?.value,
            )
          : baseDecoration.labelStyle,
      
      // Keep other properties from base decoration
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
    
    // Handle different border types
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
    // Create a list of non-null animations for the AnimatedBuilder
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

/// Extension methods for easier usage of AnimatedFormInput
extension AnimatedFormInputExtensions on Widget {
  /// Wraps a TextFormField with animated focus states
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

/// Predefined animated form input configurations
class AnimatedFormInputConfigs {
  /// Standard animated text field with default settings
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
  
  /// Email input field with appropriate keyboard and validation
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
  
  /// Password input field with obscured text and toggle
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
  
  /// Search input field with search-specific styling
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
  
  /// Multiline text area with animated focus
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