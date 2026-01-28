import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// A purple-tinted section displaying chapter learning objectives with completion tracking
/// 
/// This widget displays key points for a chapter with:
/// - Purple background tinting with star icon header
/// - List of key points with green checkmark indicators
/// - Interactive completion toggling for individual key points
/// - Responsive layout and proper spacing
class KeyPointsSection extends StatelessWidget {
  /// List of key learning objectives for the chapter
  final List<String> keyPoints;
  
  /// Completion status for each key point (must match keyPoints length)
  final List<bool> completionStatus;
  
  /// Callback when a key point completion status is toggled
  final Function(int index, bool isCompleted)? onKeyPointToggled;
  
  /// Whether the section should be interactive (allow toggling completion)
  final bool isInteractive;

  const KeyPointsSection({
    super.key,
    required this.keyPoints,
    required this.completionStatus,
    this.onKeyPointToggled,
    this.isInteractive = true,
  }) : assert(keyPoints.length == completionStatus.length,
              'keyPoints and completionStatus lists must have the same length');

  @override
  Widget build(BuildContext context) {
    if (keyPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        // Purple background tinting
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppTheme.spacingM),
            _buildKeyPointsList(context),
          ],
        ),
      ),
    );
  }

  /// Builds the header with star icon and title
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Star icon
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            Icons.star,
            color: AppTheme.primaryColor,
            size: 20,
            semanticLabel: 'Key learning objectives',
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        // Title
        Expanded(
          child: Text(
            'Key Learning Objectives',
            style: AppTypography.getTextStyle(context, 'titleLarge').copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Completion indicator
        if (_getCompletedCount() > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              '${_getCompletedCount()}/${keyPoints.length}',
              style: AppTypography.getTextStyle(context, 'labelSmall').copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the list of key points with completion indicators
  Widget _buildKeyPointsList(BuildContext context) {
    return Column(
      children: keyPoints.asMap().entries.map((entry) {
        final index = entry.key;
        final keyPoint = entry.value;
        final isCompleted = completionStatus[index];

        return _buildKeyPointItem(
          context,
          keyPoint,
          isCompleted,
          index,
        );
      }).toList(),
    );
  }

  /// Builds an individual key point item
  Widget _buildKeyPointItem(
    BuildContext context,
    String keyPoint,
    bool isCompleted,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: InkWell(
        onTap: isInteractive && onKeyPointToggled != null
            ? () => onKeyPointToggled!(index, !isCompleted)
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingS,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion indicator
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.successColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.successColor
                        : AppTheme.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingM),
              // Key point text
              Expanded(
                child: Text(
                  keyPoint,
                  style: AppTypography.getTextStyle(context, 'bodyMedium').copyWith(
                    color: isCompleted
                        ? AppTheme.secondaryTextColor
                        : AppTheme.primaryTextColor,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets the count of completed key points
  int _getCompletedCount() {
    return completionStatus.where((status) => status).length;
  }

  /// Checks if all key points are completed
  bool get isAllCompleted => _getCompletedCount() == keyPoints.length;

  /// Gets the completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (keyPoints.isEmpty) return 0.0;
    return _getCompletedCount() / keyPoints.length;
  }
}