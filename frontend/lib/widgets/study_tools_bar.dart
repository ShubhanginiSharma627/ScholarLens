import 'package:flutter/material.dart';
import 'package:scholar_lens/theme/app_theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
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
          ),
        ],
      ),
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

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPressed,
              icon: Icon(icon),
              style: IconButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(AppTheme.spacingM),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}