import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'dart:math' as math;
import '../../models/flashcard.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

/// Enhanced flashcard widget with 3D flip animation and modern styling
/// 
/// Features:
/// - Smooth 3D flip animation using AnimationController and Transform with Matrix4
/// - Gradient backgrounds for question and answer states
/// - Enhanced typography and visual hierarchy
/// - "Tap to reveal answer" instruction text
/// - Improved accessibility and semantic labels
class EnhancedFlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Function(Difficulty)? onDifficultyRated;

  const EnhancedFlashcardWidget({
    super.key,
    required this.flashcard,
    required this.isFlipped,
    required this.onFlip,
    this.onDifficultyRated,
  });

  @override
  State<EnhancedFlashcardWidget> createState() => _EnhancedFlashcardWidgetState();
}

class _EnhancedFlashcardWidgetState extends State<EnhancedFlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _depthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Optimized timing for better UX
      vsync: this,
    );
    
    // Create flip animation with enhanced easeInOut curve for smoother motion
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic, // More sophisticated easing curve
      reverseCurve: Curves.easeInOutCubic, // Consistent reverse animation
    ));
    
    // Enhanced scale animation with better timing intervals
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98, // Subtle scale for premium feel
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOutQuart),
      reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeInOutQuart),
    ));
    
    // Add depth animation for enhanced 3D effect
    _depthAnimation = Tween<double>(
      begin: 0.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOutSine),
    ));
    
    // Set initial state based on isFlipped
    if (widget.isFlipped) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EnhancedFlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    // Critical: Dispose animation controller to prevent memory leaks
    // This ensures all animation resources are properly cleaned up
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.isFlipped 
          ? 'Flashcard showing answer: ${widget.flashcard.answer}'
          : 'Flashcard showing question: ${widget.flashcard.question}. Tap to reveal answer.',
      button: true,
      onTap: widget.onFlip,
      child: GestureDetector(
        onTap: widget.onFlip,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final isShowingFront = _flipAnimation.value < 0.5;
            final rotationValue = _flipAnimation.value * math.pi;
            
            // Enhanced 3D transformation with depth and perspective
            final transform = vector_math.Matrix4.identity()
              ..setEntry(3, 2, 0.0008) // Enhanced perspective for more pronounced 3D effect
              ..translateByVector3(vector_math.Vector3(0.0, 0.0, -_depthAnimation.value)) // Add depth translation
              ..rotateY(rotationValue);
            
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: isShowingFront
                    ? _buildQuestionCard(context)
                    : Transform(
                        alignment: Alignment.center,
                        transform: vector_math.Matrix4.identity()..rotateY(math.pi),
                        child: _buildAnswerCard(context),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.primaryColor.withValues(alpha: 0.12),
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ]
              : [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.06),
                  AppTheme.primaryColor.withValues(alpha: 0.03),
                ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subject badge with enhanced styling
              _buildSubjectBadge(context, AppTheme.primaryColor, false),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Question icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Question text with enhanced typography and visual hierarchy
              Text(
                widget.flashcard.question,
                style: AppTypography.getTextStyle(context, 'headlineLarge').copyWith(
                  fontWeight: AppTypography.bold,
                  height: 1.3,
                  letterSpacing: -0.2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkPrimaryTextColor
                      : AppTheme.primaryTextColor.withValues(alpha: 0.95),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Enhanced "Tap to reveal" instruction
              _buildTapInstruction(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.successColor.withValues(alpha: 0.2),
                  AppTheme.successColor.withValues(alpha: 0.12),
                  AppTheme.successColor.withValues(alpha: 0.08),
                  AppTheme.successColor.withValues(alpha: 0.05),
                ]
              : [
                  AppTheme.successColor.withValues(alpha: 0.15),
                  AppTheme.successColor.withValues(alpha: 0.1),
                  AppTheme.successColor.withValues(alpha: 0.06),
                  AppTheme.successColor.withValues(alpha: 0.03),
                ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subject badge for answer state
              _buildSubjectBadge(context, AppTheme.successColor, true),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Answer icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 48,
                        color: AppTheme.successColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Answer text with enhanced styling and visual differentiation
              Text(
                widget.flashcard.answer,
                style: AppTypography.getTextStyle(context, 'headlineLarge').copyWith(
                  fontWeight: AppTypography.extraBold,
                  height: 1.2,
                  letterSpacing: -0.3,
                  fontSize: 24,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white.withValues(alpha: 0.95)
                      : AppTheme.successColor.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Enhanced card statistics
              _buildCardStats(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectBadge(BuildContext context, Color color, bool isAnswer) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXS),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnswer ? Icons.check_circle_outline : Icons.school_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Text(
            widget.flashcard.subject.toUpperCase(),
            style: AppTypography.getTextStyle(context, 'labelMedium').copyWith(
              color: Colors.white,
              fontWeight: AppTypography.extraBold,
              letterSpacing: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapInstruction(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXL,
        vertical: AppTheme.spacingL,
      ),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_rounded,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Text(
            'Tap to reveal answer',
            style: AppTypography.getTextStyle(context, 'titleMedium').copyWith(
              fontWeight: AppTypography.semiBold,
              letterSpacing: 0.2,
              color: isDark 
                  ? AppTheme.darkPrimaryTextColor.withValues(alpha: 0.8)
                  : AppTheme.primaryTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatChip(
            context,
            'Reviews',
            widget.flashcard.reviewCount.toString(),
            Icons.repeat_rounded,
            isDark,
          ),
          Container(
            width: 2,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.0),
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          _buildStatChip(
            context,
            'Difficulty',
            widget.flashcard.difficulty.displayName,
            _getDifficultyIcon(widget.flashcard.difficulty),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final difficultyColor = _getDifficultyColor(widget.flashcard.difficulty);
    final isReviewStat = label == 'Reviews';
    final chipColor = isReviewStat ? AppTheme.primaryColor : difficultyColor;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  chipColor.withValues(alpha: 0.15),
                  chipColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: chipColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: chipColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            value,
            style: AppTypography.getTextStyle(context, 'headlineSmall').copyWith(
              fontWeight: AppTypography.extraBold,
              letterSpacing: -0.2,
              color: isDark 
                  ? AppTheme.darkPrimaryTextColor
                  : AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            label.toUpperCase(),
            style: AppTypography.getTextStyle(context, 'labelSmall').copyWith(
              fontWeight: AppTypography.bold,
              letterSpacing: 1.2,
              fontSize: 11,
              color: isDark 
                  ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.8)
                  : AppTheme.secondaryTextColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDifficultyIcon(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Icons.trending_down_rounded;
      case Difficulty.medium:
        return Icons.trending_flat_rounded;
      case Difficulty.hard:
        return Icons.trending_up_rounded;
    }
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return AppTheme.successColor;
      case Difficulty.medium:
        return AppTheme.warningColor;
      case Difficulty.hard:
        return AppTheme.errorColor;
    }
  }
}