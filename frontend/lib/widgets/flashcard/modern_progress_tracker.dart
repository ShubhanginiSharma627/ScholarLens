import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Modern progress tracker widget with gradient progress bar and statistics display
/// Validates: Requirements 1.2, 1.3, 3.4
class ModernProgressTracker extends StatelessWidget {
  final int totalCards;
  final int masteredCards;
  final int correctCount;
  final int incorrectCount;
  final double completionPercentage;
  final bool showCounters;
  final bool showMasteryStats;

  const ModernProgressTracker({
    super.key,
    required this.totalCards,
    required this.masteredCards,
    required this.completionPercentage,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.showCounters = false,
    this.showMasteryStats = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return Container(
          padding: EdgeInsets.all(
            Responsive.responsive(
              context,
              mobile: AppTheme.spacingM,
              tablet: AppTheme.spacingL,
              desktop: AppTheme.spacingL,
            ),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
              // Statistics row
              if (showMasteryStats) ...[
                _buildStatisticsRow(context, isMobile),
                SizedBox(height: AppTheme.spacingM),
              ],
              
              // Progress bar with label
              _buildProgressSection(context, isMobile),
              
              // Counters (for study sessions)
              if (showCounters) ...[
                SizedBox(height: AppTheme.spacingM),
                _buildCountersRow(context, isMobile),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsRow(BuildContext context, bool isMobile) {
    final masteryPercentage = totalCards > 0 ? (masteredCards / totalCards * 100) : 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.style,
            value: totalCards.toString(),
            label: 'Total Cards',
            color: AppTheme.primaryColor,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.check_circle,
            value: masteredCards.toString(),
            label: 'Mastered',
            color: AppTheme.successColor,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.trending_up,
            value: '${masteryPercentage.round()}%',
            label: 'Mastery',
            color: AppTheme.accentColor,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? AppTheme.spacingS : AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
              fontSize: isMobile ? 10 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            Text(
              '${(completionPercentage * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingS),
        _buildGradientProgressBar(context, isMobile),
      ],
    );
  }

  Widget _buildGradientProgressBar(BuildContext context, bool isMobile) {
    final progressHeight = isMobile ? 8.0 : 10.0;
    
    return Container(
      height: progressHeight,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(progressHeight / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: completionPercentage.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                AppTheme.accentColor,
              ],
              stops: const [0.0, 0.6, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(progressHeight / 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountersRow(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildCounterItem(
            context,
            icon: Icons.check_circle,
            count: correctCount,
            label: 'Correct',
            color: AppTheme.successColor,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildCounterItem(
            context,
            icon: Icons.cancel,
            count: incorrectCount,
            label: 'Incorrect',
            color: AppTheme.errorColor,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildCounterItem(
            context,
            icon: Icons.percent,
            count: _calculateAccuracyPercentage(),
            label: 'Accuracy',
            color: AppTheme.accentColor,
            isMobile: isMobile,
            isPercentage: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCounterItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required bool isMobile,
    bool isPercentage = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingS : AppTheme.spacingM,
        vertical: AppTheme.spacingS,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 16 : 18,
          ),
          SizedBox(width: AppTheme.spacingXS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPercentage ? '$count%' : count.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontSize: isMobile ? 9 : 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateAccuracyPercentage() {
    final total = correctCount + incorrectCount;
    if (total == 0) return 0;
    return ((correctCount / total) * 100).round();
  }
}