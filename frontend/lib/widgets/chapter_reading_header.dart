import 'package:flutter/material.dart';
import 'package:scholar_lens/models/uploaded_textbook.dart';
import 'package:scholar_lens/models/chapter_reading_state.dart';
import 'package:scholar_lens/theme/app_theme.dart';

/// Header component for the chapter reading screen with navigation and progress
class ChapterReadingHeader extends StatelessWidget {
  final UploadedTextbook textbook;
  final ChapterReadingState readingState;
  final VoidCallback onBackPressed;
  final String? chapterTitle;
  final String? pageRange;
  final int? estimatedReadingTime;
  final bool isChapterCompleted;

  const ChapterReadingHeader({
    super.key,
    required this.textbook,
    required this.readingState,
    required this.onBackPressed,
    this.chapterTitle,
    this.pageRange,
    this.estimatedReadingTime,
    this.isChapterCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppTheme.elevationS,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNavigationRow(context),
          const SizedBox(height: AppTheme.spacingM),
          _buildChapterInfo(context),
          const SizedBox(height: AppTheme.spacingM),
          _buildMetadata(context),
          const SizedBox(height: AppTheme.spacingM),
          _buildProgressSection(context),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBackPressed,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to ${textbook.title}',
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(AppTheme.spacingS),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: GestureDetector(
            onTap: onBackPressed,
            child: Text(
              'Back to ${textbook.title}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chapterTitle != null)
                Text(
                  chapterTitle!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  'Chapter ${readingState.chapterNumber}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (pageRange != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  'Pages $pageRange',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Completion status indicator
        if (isChapterCompleted || readingState.isChapterCompleted)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXS),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  'Completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        if (estimatedReadingTime != null) ...[
          Icon(
            Icons.access_time,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            '${estimatedReadingTime!} min read',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        if (estimatedReadingTime != null && pageRange != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
            width: 1,
            height: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        if (pageRange != null) ...[
          Icon(
            Icons.menu_book,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            pageRange!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final progress = readingState.readingProgress;
    final progressPercentage = (progress * 100).toInt();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chapter Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  '$progressPercentage%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  '(${readingState.completedSectionsCount}/${readingState.totalSections} sections)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        // Animated progress bar
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: progress),
          builder: (context, animatedProgress, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  child: LinearProgressIndicator(
                    value: animatedProgress,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(context, animatedProgress),
                    ),
                  ),
                ),
                if (readingState.readingTime.inMinutes > 0) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reading time: ${readingState.formattedReadingTime}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (estimatedReadingTime != null && readingState.readingTime.inMinutes < estimatedReadingTime!)
                        Text(
                          '${estimatedReadingTime! - readingState.readingTime.inMinutes} min remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// Returns appropriate color for progress bar based on completion percentage
  Color _getProgressColor(BuildContext context, double progress) {
    if (progress >= 1.0) {
      return AppTheme.successColor;
    } else if (progress >= 0.7) {
      return AppTheme.primaryColor;
    } else if (progress >= 0.3) {
      return AppTheme.accentColor;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}