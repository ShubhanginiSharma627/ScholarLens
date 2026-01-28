import 'package:flutter/material.dart';
import 'package:scholar_lens/theme/app_theme.dart';
import 'package:scholar_lens/theme/responsive.dart';
import 'package:scholar_lens/utils/responsive_chapter_utils.dart';
import 'package:scholar_lens/utils/accessibility_utils.dart';

/// A toolbar widget that provides interactive study tools including
/// highlight mode toggle, bookmark functionality, and AI tutor access
class StudyToolsBar extends StatelessWidget {
  /// Whether highlight mode is currently active
  final bool isHighlightMode;
  
  /// Callback when highlight button is pressed to toggle highlight mode
  final VoidCallback onHighlightToggle;
  
  /// Callback when bookmark button is pressed to bookmark current section
  final VoidCallback onBookmarkPressed;
  
  /// Callback when AI tutor button is pressed to open AI assistance
  final VoidCallback onAITutorPressed;
  
  /// Whether the bookmark button should show as active (current section is bookmarked)
  final bool isCurrentSectionBookmarked;
  
  /// Whether the AI tutor service is available
  final bool isAITutorAvailable;

  const StudyToolsBar({
    super.key,
    required this.isHighlightMode,
    required this.onHighlightToggle,
    required this.onBookmarkPressed,
    required this.onAITutorPressed,
    this.isCurrentSectionBookmarked = false,
    this.isAITutorAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveChapterUtils.shouldUseCompactLayout(context);
    final buttonSize = ResponsiveChapterUtils.getMinTouchTargetSize(context);
    final spacing = ResponsiveChapterUtils.getToolButtonSpacing(context);
    
    return Semantics(
      label: 'Study tools',
      hint: 'Interactive tools for highlighting, bookmarking, and AI assistance',
      child: ResponsiveChapterLayout(
        child: Container(
          padding: ResponsiveChapterUtils.getContentPadding(context),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(ResponsiveChapterUtils.getCardBorderRadius(context)),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: isCompact 
              ? _buildCompactLayout(context, buttonSize, spacing)
              : _buildFullLayout(context, buttonSize, spacing),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, double buttonSize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactToolButton(
          context: context,
          icon: Icons.highlight_alt,
          isActive: isHighlightMode,
          onPressed: onHighlightToggle,
          tooltip: isHighlightMode 
              ? 'Exit highlight mode' 
              : 'Enter highlight mode to select text',
          buttonSize: buttonSize,
        ),
        _buildCompactToolButton(
          context: context,
          icon: isCurrentSectionBookmarked 
              ? Icons.bookmark 
              : Icons.bookmark_add,
          isActive: isCurrentSectionBookmarked,
          onPressed: onBookmarkPressed,
          tooltip: isCurrentSectionBookmarked
              ? 'Section bookmarked'
              : 'Bookmark current section',
          buttonSize: buttonSize,
        ),
        _buildCompactToolButton(
          context: context,
          icon: Icons.psychology,
          onPressed: isAITutorAvailable ? onAITutorPressed : null,
          tooltip: isAITutorAvailable
              ? 'Ask AI tutor about this section'
              : 'AI tutor is temporarily unavailable',
          isDisabled: !isAITutorAvailable,
          buttonSize: buttonSize,
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, double buttonSize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          context: context,
          icon: Icons.highlight_alt,
          label: 'Highlight',
          isActive: isHighlightMode,
          onPressed: onHighlightToggle,
          tooltip: isHighlightMode 
              ? 'Exit highlight mode' 
              : 'Enter highlight mode to select text',
          buttonSize: buttonSize,
        ),
        _buildToolButton(
          context: context,
          icon: isCurrentSectionBookmarked 
              ? Icons.bookmark 
              : Icons.bookmark_add,
          label: 'Bookmark',
          isActive: isCurrentSectionBookmarked,
          onPressed: onBookmarkPressed,
          tooltip: isCurrentSectionBookmarked
              ? 'Section bookmarked'
              : 'Bookmark current section',
          buttonSize: buttonSize,
        ),
        _buildToolButton(
          context: context,
          icon: Icons.psychology,
          label: 'Ask AI',
          onPressed: isAITutorAvailable ? onAITutorPressed : null,
          tooltip: isAITutorAvailable
              ? 'Ask AI tutor about this section'
              : 'AI tutor is temporarily unavailable',
          isDisabled: !isAITutorAvailable,
          buttonSize: buttonSize,
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isDisabled = false,
    required VoidCallback? onPressed,
    required String tooltip,
    required double buttonSize,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine button colors based on state
    Color? backgroundColor;
    Color? foregroundColor;
    
    if (isDisabled) {
      backgroundColor = colorScheme.surfaceVariant.withOpacity(0.3);
      foregroundColor = colorScheme.onSurfaceVariant.withOpacity(0.4);
    } else if (isActive) {
      backgroundColor = colorScheme.primary.withOpacity(0.2);
      foregroundColor = colorScheme.primary;
    } else {
      backgroundColor = null;
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    // Create semantic label
    final semanticLabel = isActive 
        ? '$label active' 
        : isDisabled 
            ? '$label disabled' 
            : label;

    return Expanded(
      child: AccessibilityUtils.createAccessibleButton(
        semanticLabel: semanticLabel,
        tooltip: tooltip,
        onPressed: onPressed,
        isSelected: isActive,
        isEnabled: !isDisabled,
        minSize: buttonSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(buttonSize / 2),
              ),
              child: AccessibilityUtils.createAccessibleIcon(
                icon: icon,
                semanticLabel: '$label icon',
                color: foregroundColor,
                size: Responsive.responsiveFontSize(context, 20.0),
              ),
            ),
            SizedBox(height: AppTheme.spacingXS),
            AccessibilityUtils.createAccessibleText(
              text: label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: Responsive.responsiveFontSize(context, 12.0),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToolButton({
    required BuildContext context,
    required IconData icon,
    bool isActive = false,
    bool isDisabled = false,
    required VoidCallback? onPressed,
    required String tooltip,
    required double buttonSize,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine button colors based on state
    Color? backgroundColor;
    Color? foregroundColor;
    
    if (isDisabled) {
      backgroundColor = colorScheme.surfaceVariant.withOpacity(0.3);
      foregroundColor = colorScheme.onSurfaceVariant.withOpacity(0.4);
    } else if (isActive) {
      backgroundColor = colorScheme.primary.withOpacity(0.2);
      foregroundColor = colorScheme.primary;
    } else {
      backgroundColor = null;
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    // Create semantic label based on icon
    String semanticLabel;
    if (icon == Icons.highlight_alt) {
      semanticLabel = AccessibilityUtils.createHighlightModeLabel(isActive);
    } else if (icon == Icons.bookmark || icon == Icons.bookmark_add) {
      semanticLabel = AccessibilityUtils.createBookmarkLabel(isActive);
    } else if (icon == Icons.psychology) {
      semanticLabel = AccessibilityUtils.createAITutorLabel(!isDisabled);
    } else {
      semanticLabel = tooltip;
    }

    return AccessibilityUtils.createAccessibleButton(
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: isActive,
      isEnabled: !isDisabled,
      minSize: buttonSize,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(buttonSize / 2),
        ),
        child: AccessibilityUtils.createAccessibleIcon(
          icon: icon,
          semanticLabel: '$semanticLabel icon',
          color: foregroundColor,
          size: Responsive.responsiveFontSize(context, 22.0),
        ),
      ),
    );
  }
}