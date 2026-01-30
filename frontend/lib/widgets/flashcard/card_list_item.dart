import 'package:flutter/material.dart';
import '../../models/flashcard.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
class CardListItem extends StatefulWidget {
  final Flashcard flashcard;
  final bool isMastered;
  final VoidCallback onTap;
  final int? cardNumber;
  final bool showMasteryIndicator;
  const CardListItem({
    super.key,
    required this.flashcard,
    required this.isMastered,
    required this.onTap,
    this.cardNumber,
    this.showMasteryIndicator = true,
  });
  @override
  State<CardListItem> createState() => _CardListItemState();
}
class _CardListItemState extends State<CardListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _elevationAnimation = Tween<double>(
      begin: AppTheme.elevationS,
      end: AppTheme.elevationM,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }
  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onTap();
  }
  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      label: 'Flashcard ${widget.cardNumber != null ? '${widget.cardNumber}: ' : ''}'
             '${widget.flashcard.question}. '
             '${widget.isMastered ? 'Mastered' : 'Not mastered'}. '
             'Tap to study this card.',
      button: true,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              child: Material(
                elevation: _elevationAnimation.value,
                shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                color: isDark ? AppTheme.darkCardColor : AppTheme.cardColor,
                child: InkWell(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: _isPressed
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.08),
                        width: _isPressed ? 2 : 1,
                      ),
                      gradient: _isPressed
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.05),
                                AppTheme.primaryColor.withValues(alpha: 0.02),
                              ],
                            )
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showMasteryIndicator)
                          _buildMasteryIndicator(context, isDark),
                        Expanded(
                          child: _buildCardContent(context, isDark),
                        ),
                        _buildTrailingIndicators(context, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildMasteryIndicator(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingL),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: widget.isMastered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.successColor,
                        AppTheme.successColor.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: widget.isMastered 
                  ? null 
                  : (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: widget.isMastered
                  ? null
                  : Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.12),
                      width: 2,
                    ),
              boxShadow: widget.isMastered
                  ? [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: widget.isMastered
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                : widget.cardNumber != null
                    ? Center(
                        child: Text(
                          widget.cardNumber.toString(),
                          style: AppTypography.getTextStyle(context, 'titleLarge').copyWith(
                            fontWeight: AppTypography.bold,
                            color: isDark 
                                ? AppTheme.darkPrimaryTextColor.withValues(alpha: 0.7)
                                : AppTheme.primaryTextColor.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.school_outlined,
                        color: isDark 
                            ? AppTheme.darkSecondaryTextColor
                            : AppTheme.secondaryTextColor,
                        size: 24,
                      ),
          ),
          if (widget.cardNumber != null && widget.isMastered)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingS),
              child: Text(
                '#${widget.cardNumber}',
                style: AppTypography.getTextStyle(context, 'labelSmall').copyWith(
                  fontWeight: AppTypography.semiBold,
                  color: isDark 
                      ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.8)
                      : AppTheme.secondaryTextColor.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildCardContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubjectBadge(context, isDark),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          widget.flashcard.question,
          style: AppTypography.getTextStyle(context, 'titleLarge').copyWith(
            fontWeight: AppTypography.semiBold,
            height: 1.3,
            color: isDark 
                ? AppTheme.darkPrimaryTextColor
                : AppTheme.primaryTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: AppTheme.successColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  widget.flashcard.answer,
                  style: AppTypography.getTextStyle(context, 'bodyMedium').copyWith(
                    color: isDark 
                        ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.9)
                        : AppTheme.secondaryTextColor.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        _buildCardStatistics(context, isDark),
      ],
    );
  }
  Widget _buildSubjectBadge(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 12,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            widget.flashcard.subject.toUpperCase(),
            style: AppTypography.getTextStyle(context, 'labelSmall').copyWith(
              fontWeight: AppTypography.bold,
              letterSpacing: 1.0,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCardStatistics(BuildContext context, bool isDark) {
    return Row(
      children: [
        _buildStatChip(
          context,
          Icons.repeat_rounded,
          '${widget.flashcard.reviewCount} reviews',
          AppTheme.primaryColor,
          isDark,
        ),
        const SizedBox(width: AppTheme.spacingM),
        _buildStatChip(
          context,
          _getDifficultyIcon(widget.flashcard.difficulty),
          widget.flashcard.difficulty.displayName,
          _getDifficultyColor(widget.flashcard.difficulty),
          isDark,
        ),
        const Spacer(),
        if (widget.flashcard.isDue)
          _buildStatChip(
            context,
            Icons.schedule_rounded,
            'Due now',
            AppTheme.warningColor,
            isDark,
          )
        else if (widget.flashcard.daysUntilReview > 0)
          _buildStatChip(
            context,
            Icons.schedule_rounded,
            '${widget.flashcard.daysUntilReview}d',
            AppTheme.successColor,
            isDark,
          ),
      ],
    );
  }
  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            label,
            style: AppTypography.getTextStyle(context, 'labelSmall').copyWith(
              fontWeight: AppTypography.medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTrailingIndicators(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          width: 4,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getDifficultyColor(widget.flashcard.difficulty),
                _getDifficultyColor(widget.flashcard.difficulty).withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark 
                ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.7)
                : AppTheme.secondaryTextColor.withValues(alpha: 0.6),
          ),
        ),
      ],
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