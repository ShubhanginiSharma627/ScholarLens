import 'package:flutter/material.dart';
import '../models/chapter_section.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
class SectionNavigator extends StatelessWidget {
  final int currentSection;
  final int totalSections;
  final List<bool> sectionCompletionStatus;
  final List<ChapterSection>? sections;
  final Function(int) onSectionChanged;
  final VoidCallback? onPreviousPressed;
  final VoidCallback? onNextPressed;
  final VoidCallback? onShowAllSections;
  const SectionNavigator({
    super.key,
    required this.currentSection,
    required this.totalSections,
    required this.sectionCompletionStatus,
    required this.onSectionChanged,
    this.sections,
    this.onPreviousPressed,
    this.onNextPressed,
    this.onShowAllSections,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Section $currentSection of $totalSections',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavigationButton(
                icon: AppIcons.arrowLeft,
                label: 'Previous',
                isEnabled: currentSection > 1,
                onPressed: onPreviousPressed,
                theme: theme,
              ),
              _AllSectionsButton(
                onPressed: () => _showSectionOverview(context),
                theme: theme,
              ),
              _NavigationButton(
                icon: AppIcons.arrowRight,
                label: 'Next',
                isEnabled: currentSection < totalSections,
                onPressed: onNextPressed,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _showSectionOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SectionOverviewModal(
        currentSection: currentSection,
        totalSections: totalSections,
        sectionCompletionStatus: sectionCompletionStatus,
        sections: sections,
        onSectionSelected: (sectionIndex) {
          Navigator.of(context).pop();
          onSectionChanged(sectionIndex);
        },
      ),
    );
  }
}
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback? onPressed;
  final ThemeData theme;
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
        child: OutlinedButton.icon(
          onPressed: isEnabled ? onPressed : null,
          icon: Icon(
            icon,
            size: 18,
            color: isEnabled 
                ? colorScheme.primary 
                : colorScheme.onSurface.withValues(alpha: 0.38),
          ),
          label: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isEnabled 
                  ? colorScheme.primary 
                  : colorScheme.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            side: BorderSide(
              color: isEnabled 
                  ? colorScheme.primary 
                  : colorScheme.onSurface.withValues(alpha: 0.12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
          ),
        ),
      ),
    );
  }
}
class _AllSectionsButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final ThemeData theme;
  const _AllSectionsButton({
    required this.onPressed,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            AppIcons.menu,
            size: 18,
            color: colorScheme.onPrimary,
          ),
          label: Text(
            'All Sections',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
class _SectionOverviewModal extends StatelessWidget {
  final int currentSection;
  final int totalSections;
  final List<bool> sectionCompletionStatus;
  final List<ChapterSection>? sections;
  final Function(int) onSectionSelected;
  const _SectionOverviewModal({
    required this.currentSection,
    required this.totalSections,
    required this.sectionCompletionStatus,
    required this.sections,
    required this.onSectionSelected,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Icon(
                  AppIcons.menu,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'All Sections',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
              itemCount: totalSections,
              itemBuilder: (context, index) {
                final sectionNumber = index + 1;
                final isCompleted = index < sectionCompletionStatus.length 
                    ? sectionCompletionStatus[index] 
                    : false;
                final isCurrent = sectionNumber == currentSection;
                final sectionTitle = sections != null && index < sections!.length
                    ? sections![index].title
                    : 'Section $sectionNumber';
                return _SectionListItem(
                  sectionNumber: sectionNumber,
                  title: sectionTitle,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  onTap: () => onSectionSelected(sectionNumber),
                  theme: theme,
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppTheme.spacingL),
        ],
      ),
    );
  }
}
class _SectionListItem extends StatelessWidget {
  final int sectionNumber;
  final String title;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onTap;
  final ThemeData theme;
  const _SectionListItem({
    required this.sectionNumber,
    required this.title,
    required this.isCompleted,
    required this.isCurrent,
    required this.onTap,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: isCurrent 
            ? colorScheme.primary.withValues(alpha: 0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: isCurrent 
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrent 
                ? colorScheme.primary
                : isCompleted 
                    ? AppTheme.successColor
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: !isCurrent && !isCompleted
                ? Border.all(color: colorScheme.outline)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    AppIcons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : Text(
                    '$sectionNumber',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isCurrent 
                          ? Colors.white
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isCurrent 
                ? colorScheme.primary
                : colorScheme.onSurface,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: isCurrent 
            ? Text(
                'Current Section',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing: isCurrent 
            ? Icon(
                AppIcons.arrowRight,
                color: colorScheme.primary,
                size: 20,
              )
            : null,
      ),
    );
  }
}