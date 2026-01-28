import 'package:flutter/material.dart';
import 'package:scholar_lens/models/uploaded_textbook.dart';
import 'package:scholar_lens/models/chapter_reading_state.dart';
import 'package:scholar_lens/theme/app_theme.dart';
import 'package:scholar_lens/theme/responsive.dart';
import 'package:scholar_lens/utils/responsive_chapter_utils.dart';
import 'package:scholar_lens/utils/accessibility_utils.dart';

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
    return ResponsiveChapterLayout(
      child: Container(
        padding: ResponsiveChapterUtils.getContentPadding(context),
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
            SizedBox(height: ResponsiveChapterUtils.getSectionSpacing(context) * 0.5),
            _buildChapterInfo(context),
            SizedBox(height: ResponsiveChapterUtils.getSectionSpacing(context) * 0.5),
            _buildMetadata(context),
            SizedBox(height: ResponsiveChapterUtils.getSectionSpacing(context) * 0.5),
            _buildProgressSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow(BuildContext context) {
    final buttonSize = ResponsiveChapterUtils.getMinTouchTargetSize(context);
    
    return AccessibilityUtils.createAccessibleNavigation(
      semanticLabel: 'Chapter navigation',
      children: [
        AccessibilityUtils.createAccessibleButton(
          semanticLabel: 'Back to ${textbook.title}',
          tooltip: 'Navigate back to textbook overview',
          onPressed: onBackPressed,
          minSize: buttonSize,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(buttonSize / 2),
            ),
            child: Icon(
              Icons.arrow_back,
              size: Responsive.responsiveFontSize(context, 20.0),
              semanticLabel: 'Back arrow',
            ),
          ),
        ),
        SizedBox(width: ResponsiveChapterUtils.getSectionSpacing(context) * 0.5),
        Expanded(
          child: Semantics(
            label: 'Back to ${textbook.title}',
            hint: 'Tap to return to textbook overview',
            button: true,
            child: GestureDetector(
              onTap: onBackPressed,
              child: Text(
                'Back to ${textbook.title}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: Responsive.responsiveFontSize(context, 14.0),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: Responsive.isMobile(context) ? 1 : 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterInfo(BuildContext context) {
    final isCompact = ResponsiveChapterUtils.shouldUseCompactLayout(context);
    
    return Responsive.isMobile(context) && isCompact
        ? _buildCompactChapterInfo(context)
        : _buildFullChapterInfo(context);
  }

  Widget _buildCompactChapterInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chapterTitle != null)
          Text(
            chapterTitle!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.responsiveFontSize(context, 18.0),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        else
          Text(
            'Chapter ${readingState.chapterNumber}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.responsiveFontSize(context, 18.0),
            ),
          ),
        if (pageRange != null) ...[
          SizedBox(height: AppTheme.spacingXS),
          Text(
            'Pages $pageRange',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: Responsive.responsiveFontSize(context, 12.0),
            ),
          ),
        ],
        if (isChapterCompleted || readingState.isChapterCompleted) ...[
          SizedBox(height: AppTheme.spacingXS),
          _buildCompletionBadge(context),
        ],
      ],
    );
  }

  Widget _buildFullChapterInfo(BuildContext context) {
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
                    fontSize: Responsive.responsiveFontSize(context, 20.0),
                  ),
                  maxLines: Responsive.isMobile(context) ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Chapter ${readingState.chapterNumber}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.responsiveFontSize(context, 20.0),
                  ),
                ),
              if (pageRange != null) ...[
                SizedBox(height: AppTheme.spacingXS),
                Text(
                  'Pages $pageRange',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: Responsive.responsiveFontSize(context, 14.0),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Completion status indicator
        if (isChapterCompleted || readingState.isChapterCompleted)
          _buildCompletionBadge(context),
      ],
    );
  }

  Widget _buildCompletionBadge(BuildContext context) {
    return Semantics(
      label: 'Chapter completed',
      child: Container(
        padding: EdgeInsets.all(ResponsiveChapterUtils.getToolButtonSpacing(context) * 0.5),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AccessibilityUtils.createAccessibleIcon(
              icon: Icons.check_circle,
              semanticLabel: 'Completed checkmark',
              color: AppTheme.successColor,
              size: Responsive.responsiveFontSize(context, 16.0),
            ),
            SizedBox(width: AppTheme.spacingXS),
            AccessibilityUtils.createAccessibleText(
              text: 'Completed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.responsiveFontSize(context, 12.0),
              ),
            ),
          ],
        ),
      ),
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
    final progressBarHeight = ResponsiveChapterUtils.getProgressBarHeight(context);
    final progressLabel = AccessibilityUtils.createProgressLabel(progress, context: 'Chapter reading');
    
    return Semantics(
      label: 'Chapter progress section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AccessibilityUtils.createAccessibleText(
                  text: 'Chapter Progress',
                  semanticLabel: 'Chapter progress heading',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.responsiveFontSize(context, 14.0),
                  ),
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AccessibilityUtils.createAccessibleText(
                      text: '$progressPercentage%',
                      semanticLabel: '$progressPercentage percent complete',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: Responsive.responsiveFontSize(context, 14.0),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingXS),
                    if (!ResponsiveChapterUtils.shouldUseCompactLayout(context))
                      AccessibilityUtils.createAccessibleText(
                        text: '(${readingState.completedSectionsCount}/${readingState.totalSections} sections)',
                        semanticLabel: '${readingState.completedSectionsCount} of ${readingState.totalSections} sections completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: Responsive.responsiveFontSize(context, 12.0),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingS),
          // Animated progress bar
          TweenAnimationBuilder<double>(
            duration: AccessibilityUtils.isReduceMotionEnabled(context) 
                ? Duration.zero 
                : const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0.0, end: progress),
            builder: (context, animatedProgress, child) {
              return Column(
                children: [
                  AccessibilityUtils.createAccessibleProgress(
                    value: animatedProgress,
                    label: progressLabel,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(progressBarHeight / 2),
                      child: LinearProgressIndicator(
                        value: animatedProgress,
                        minHeight: progressBarHeight,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(context, animatedProgress),
                        ),
                        semanticsLabel: progressLabel,
                        semanticsValue: '${(animatedProgress * 100).round()}%',
                      ),
                    ),
                  ),
                  if (readingState.readingTime.inMinutes > 0 && 
                      !ResponsiveChapterUtils.shouldUseCompactLayout(context)) ...[
                    SizedBox(height: AppTheme.spacingXS),
                    Semantics(
                      label: 'Reading time information',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: AccessibilityUtils.createAccessibleText(
                              text: 'Reading time: ${readingState.formattedReadingTime}',
                              semanticLabel: AccessibilityUtils.createReadingTimeLabel(readingState.readingTime),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: Responsive.responsiveFontSize(context, 11.0),
                              ),
                            ),
                          ),
                          if (estimatedReadingTime != null && readingState.readingTime.inMinutes < estimatedReadingTime!)
                            Flexible(
                              child: AccessibilityUtils.createAccessibleText(
                                text: '${estimatedReadingTime! - readingState.readingTime.inMinutes} min remaining',
                                semanticLabel: '${estimatedReadingTime! - readingState.readingTime.inMinutes} minutes remaining',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: Responsive.responsiveFontSize(context, 11.0),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
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