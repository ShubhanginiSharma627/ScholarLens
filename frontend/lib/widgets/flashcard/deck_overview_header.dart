import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../theme/responsive.dart';
import '../../services/flashcard_service.dart';
import 'modern_progress_tracker.dart';

/// Modern header component for deck overview with subject info, progress, and study options
/// Validates: Requirements 1.1, 1.4, 5.4, 5.5
class DeckOverviewHeader extends StatelessWidget {
  final String subjectName;
  final FlashcardStats stats;
  final VoidCallback onStudyAll;
  final VoidCallback onShuffle;
  final bool isLoading;

  const DeckOverviewHeader({
    super.key,
    required this.subjectName,
    required this.stats,
    required this.onStudyAll,
    required this.onShuffle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            Responsive.responsive(
              context,
              mobile: AppTheme.spacingM,
              tablet: AppTheme.spacingL,
              desktop: AppTheme.spacingXL,
            ),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.05),
                AppTheme.secondaryColor.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject name and badge
              _buildSubjectHeader(context, isMobile),
              
              SizedBox(height: AppTheme.spacingL),
              
              // Progress tracker
              _buildProgressSection(context),
              
              SizedBox(height: AppTheme.spacingL),
              
              // Study action buttons
              _buildActionButtons(context, isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        // Subject icon
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            _getSubjectIcon(subjectName),
            color: AppTheme.primaryColor,
            size: isMobile ? 24 : 28,
          ),
        ),
        
        SizedBox(width: AppTheme.spacingM),
        
        // Subject name and info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subjectName,
                style: isMobile 
                  ? AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    )
                  : AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTextColor,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: AppTheme.spacingXS),
              
              // Subject badge with card count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${stats.totalCards} cards',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Due cards indicator (if any)
        if (stats.dueCards > 0) ...[
          SizedBox(width: AppTheme.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: AppTheme.warningColor,
                ),
                SizedBox(width: AppTheme.spacingXS),
                Text(
                  '${stats.dueCards} due',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return ModernProgressTracker(
      totalCards: stats.totalCards,
      masteredCards: stats.masteredCards,
      completionPercentage: stats.masteryPercentage,
      showMasteryStats: true,
      showCounters: false,
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isMobile, bool isTablet) {
    if (isMobile) {
      // Stack buttons vertically on mobile
      return Column(
        children: [
          _buildStudyAllButton(context, isMobile),
          SizedBox(height: AppTheme.spacingS),
          _buildShuffleButton(context, isMobile),
        ],
      );
    } else {
      // Place buttons side by side on tablet/desktop
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildStudyAllButton(context, isMobile),
          ),
          SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: _buildShuffleButton(context, isMobile),
          ),
        ],
      );
    }
  }

  Widget _buildStudyAllButton(BuildContext context, bool isMobile) {
    final hasCards = stats.totalCards > 0;
    
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 48 : 52,
      child: ElevatedButton.icon(
        onPressed: hasCards && !isLoading ? onStudyAll : null,
        icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(
              Icons.play_arrow,
              size: isMobile ? 20 : 24,
            ),
        label: Text(
          isLoading ? 'Loading...' : 'Study All',
          style: AppTypography.buttonMedium.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: AppTheme.elevationS,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: isMobile ? AppTheme.spacingS : AppTheme.spacingM,
          ),
        ),
      ),
    );
  }

  Widget _buildShuffleButton(BuildContext context, bool isMobile) {
    final hasCards = stats.totalCards > 0;
    
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 48 : 52,
      child: OutlinedButton.icon(
        onPressed: hasCards && !isLoading ? onShuffle : null,
        icon: Icon(
          Icons.shuffle,
          size: isMobile ? 20 : 24,
        ),
        label: Text(
          'Shuffle',
          style: AppTypography.buttonMedium.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(
            color: hasCards && !isLoading 
              ? AppTheme.primaryColor 
              : AppTheme.secondaryTextColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: isMobile ? AppTheme.spacingS : AppTheme.spacingM,
          ),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    final subjectLower = subject.toLowerCase();
    
    if (subjectLower.contains('math') || subjectLower.contains('calculus') || 
        subjectLower.contains('algebra') || subjectLower.contains('geometry')) {
      return Icons.calculate;
    } else if (subjectLower.contains('science') || subjectLower.contains('physics') || 
               subjectLower.contains('chemistry') || subjectLower.contains('biology')) {
      return Icons.science;
    } else if (subjectLower.contains('history') || subjectLower.contains('social')) {
      return Icons.history_edu;
    } else if (subjectLower.contains('language') || subjectLower.contains('english') || 
               subjectLower.contains('literature') || subjectLower.contains('writing')) {
      return Icons.translate;
    } else if (subjectLower.contains('art') || subjectLower.contains('design')) {
      return Icons.palette;
    } else if (subjectLower.contains('music')) {
      return Icons.music_note;
    } else if (subjectLower.contains('computer') || subjectLower.contains('programming') || 
               subjectLower.contains('coding')) {
      return Icons.computer;
    } else if (subjectLower.contains('geography')) {
      return Icons.public;
    } else if (subjectLower.contains('economics') || subjectLower.contains('business')) {
      return Icons.trending_up;
    } else {
      return Icons.school; // Default icon
    }
  }
}