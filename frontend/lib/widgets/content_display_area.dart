import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scholar_lens/models/chapter_section.dart';
import 'package:scholar_lens/models/text_highlight.dart';
import 'package:scholar_lens/widgets/highlighted_text_widget.dart';
import 'package:scholar_lens/theme/responsive.dart';
import 'package:scholar_lens/utils/responsive_chapter_utils.dart';

/// Main content display area for chapter reading with section management
class ContentDisplayArea extends StatefulWidget {
  /// List of chapter sections
  final List<ChapterSection> sections;
  
  /// Current section index being displayed
  final int currentSectionIndex;
  
  /// List of highlights for the current section
  final List<TextHighlight> highlights;
  
  /// Whether highlight mode is active
  final bool isHighlightMode;
  
  /// Callback when text is highlighted
  final Function(String selectedText, int startOffset, int endOffset)? onTextHighlighted;
  
  /// Callback when a highlight is tapped
  final Function(TextHighlight highlight)? onHighlightTapped;
  
  /// Callback when a highlight should be removed
  final Function(String highlightId)? onHighlightRemoved;
  
  /// Callback when a highlight color should be changed
  final Function(TextHighlight highlight, Color newColor)? onHighlightColorChanged;
  
  /// Callback when scroll position changes for progress tracking
  final Function(double scrollOffset, double maxScrollExtent)? onScrollChanged;
  
  /// Callback when section reading is completed
  final Function(int sectionIndex)? onSectionCompleted;
  
  /// Custom text style for content
  final TextStyle? contentTextStyle;

  const ContentDisplayArea({
    super.key,
    required this.sections,
    required this.currentSectionIndex,
    this.highlights = const [],
    this.isHighlightMode = false,
    this.onTextHighlighted,
    this.onHighlightTapped,
    this.onHighlightRemoved,
    this.onHighlightColorChanged,
    this.onScrollChanged,
    this.onSectionCompleted,
    this.contentTextStyle,
  });

  @override
  State<ContentDisplayArea> createState() => _ContentDisplayAreaState();
}

class _ContentDisplayAreaState extends State<ContentDisplayArea> {
  late ScrollController _scrollController;
  double _lastScrollOffset = 0.0;
  DateTime? _sectionStartTime;
  bool _hasReachedBottom = false;
  
  // Progress tracking variables
  double _totalReadingTime = 0.0; // in seconds
  double _currentScrollProgress = 0.0;
  Timer? _progressTimer;
  DateTime? _lastProgressUpdate;
  
  // Reading behavior tracking
  int _scrollEvents = 0;
  double _maxScrollReached = 0.0;
  bool _isActivelyReading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollChange);
    _sectionStartTime = DateTime.now();
    _lastProgressUpdate = DateTime.now();
    _startProgressTracking();
  }

  @override
  void didUpdateWidget(ContentDisplayArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset section tracking when section changes
    if (oldWidget.currentSectionIndex != widget.currentSectionIndex) {
      _resetSectionTracking();
      _scrollToTop();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _scrollController.removeListener(_handleScrollChange);
    _scrollController.dispose();
    super.dispose();
  }

  /// Starts the progress tracking timer
  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isActivelyReading) {
        _totalReadingTime += 1.0;
        _updateReadingProgress();
      }
    });
  }

  /// Resets section tracking when changing sections
  void _resetSectionTracking() {
    _sectionStartTime = DateTime.now();
    _lastProgressUpdate = DateTime.now();
    _hasReachedBottom = false;
    _totalReadingTime = 0.0;
    _currentScrollProgress = 0.0;
    _scrollEvents = 0;
    _maxScrollReached = 0.0;
    _isActivelyReading = false;
  }

  /// Updates reading progress based on time and scroll behavior
  void _updateReadingProgress() {
    final now = DateTime.now();
    if (_lastProgressUpdate != null) {
      // Progress calculation methods are available for future enhancement
      // Currently using scroll-based progress tracking
      
      // Notify parent of progress changes
      widget.onScrollChanged?.call(_scrollController.offset, _scrollController.position.maxScrollExtent);
      
      _lastProgressUpdate = now;
    }
  }

  /// Handles scroll position changes for progress tracking
  void _handleScrollChange() {
    final currentOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    // Update scroll tracking variables
    _scrollEvents++;
    _maxScrollReached = currentOffset > _maxScrollReached ? currentOffset : _maxScrollReached;
    _currentScrollProgress = maxScrollExtent > 0 ? currentOffset / maxScrollExtent : 0.0;
    
    // Determine if user is actively reading based on scroll behavior
    final scrollDelta = (currentOffset - _lastScrollOffset).abs();
    _isActivelyReading = scrollDelta > 0; // User is scrolling
    
    // Notify parent of scroll changes
    widget.onScrollChanged?.call(currentOffset, maxScrollExtent);
    
    // Track if user has reached the bottom of the section
    if (!_hasReachedBottom && maxScrollExtent > 0) {
      final scrollPercentage = currentOffset / maxScrollExtent;
      if (scrollPercentage >= 0.9) { // 90% scrolled
        _hasReachedBottom = true;
        _checkSectionCompletion();
      }
    }
    
    _lastScrollOffset = currentOffset;
    
    // Update reading progress
    _updateReadingProgress();
  }

  /// Checks if section should be marked as completed
  void _checkSectionCompletion() {
    if (_hasReachedBottom && _sectionStartTime != null) {
      final readingTime = DateTime.now().difference(_sectionStartTime!);
      final currentSection = _currentSection;
      
      if (currentSection != null) {
        // More sophisticated completion criteria
        final minReadingTime = (currentSection.estimatedReadingTimeMinutes * 0.3 * 60).round(); // 30% of estimated time
        final hasMinimumTime = readingTime.inSeconds >= minReadingTime;
        final hasMinimumScrollActivity = _scrollEvents >= 5;
        final hasReachedSignificantProgress = _currentScrollProgress >= 0.8;
        
        if (hasMinimumTime && hasMinimumScrollActivity && hasReachedSignificantProgress) {
          widget.onSectionCompleted?.call(widget.currentSectionIndex);
        }
      }
    }
  }

  /// Scrolls to the top of the content
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Handles highlight tap with options menu
  void _handleHighlightTapped(TextHighlight highlight) {
    if (widget.onHighlightTapped != null) {
      widget.onHighlightTapped!(highlight);
    } else {
      // Show default highlight options
      _showHighlightOptionsMenu(highlight);
    }
  }

  /// Shows highlight options menu
  void _showHighlightOptionsMenu(TextHighlight highlight) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildHighlightOptionsSheet(highlight),
    );
  }

  /// Builds the highlight options bottom sheet
  Widget _buildHighlightOptionsSheet(TextHighlight highlight) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlight Options',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Highlight preview
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: highlight.highlightColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              highlight.getPreview(maxLength: 100),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Color options
          Text(
            'Change Color',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HighlightColorType.values.map((colorType) {
              final isSelected = highlight.highlightColor.r == colorType.color.r &&
                                highlight.highlightColor.g == colorType.color.g &&
                                highlight.highlightColor.b == colorType.color.b;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onHighlightColorChanged != null) {
                    widget.onHighlightColorChanged!(highlight, colorType.color);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorType.color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          )
                        : Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onHighlightRemoved != null) {
                      widget.onHighlightRemoved!(highlight.id);
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Gets the current section being displayed
  ChapterSection? get _currentSection {
    if (widget.currentSectionIndex >= 0 && 
        widget.currentSectionIndex < widget.sections.length) {
      return widget.sections[widget.currentSectionIndex];
    }
    return null;
  }

  /// Gets highlights for the current section
  List<TextHighlight> get _currentSectionHighlights {
    final currentSection = _currentSection;
    if (currentSection == null) return [];
    
    return widget.highlights.where((highlight) =>
        highlight.sectionNumber == currentSection.sectionNumber).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSection = _currentSection;
    final borderRadius = ResponsiveChapterUtils.getCardBorderRadius(context);
    
    return ResponsiveChapterLayout(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            _buildSectionHeader(theme, currentSection),
            
            // Content area
            Expanded(
              child: _buildContentArea(theme, currentSection),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the section header with indicator and title
  Widget _buildSectionHeader(ThemeData theme, ChapterSection? currentSection) {
    final borderRadius = ResponsiveChapterUtils.getCardBorderRadius(context);
    final isCompact = ResponsiveChapterUtils.shouldUseCompactLayout(context);
    
    return Container(
      padding: ResponsiveChapterUtils.getContentPadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section indicator
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveChapterUtils.getToolButtonSpacing(context),
                  vertical: ResponsiveChapterUtils.getToolButtonSpacing(context) * 0.5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Section ${widget.currentSectionIndex + 1} of ${widget.sections.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.responsiveFontSize(context, 12.0),
                  ),
                ),
              ),
              const Spacer(),
              if (currentSection?.isCompleted == true)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: Responsive.responsiveFontSize(context, 18.0),
                ),
            ],
          ),
          
          SizedBox(height: ResponsiveChapterUtils.getSectionSpacing(context) * 0.5),
          
          // Section title
          if (currentSection != null)
            Text(
              currentSection.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: Responsive.responsiveFontSize(context, isCompact ? 16.0 : 18.0),
              ),
              maxLines: isCompact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Builds the main content area with scrollable text
  Widget _buildContentArea(ThemeData theme, ChapterSection? currentSection) {
    if (currentSection == null) {
      return _buildEmptyState(theme);
    }

    final contentPadding = ResponsiveChapterUtils.getContentPadding(context);
    final sectionSpacing = ResponsiveChapterUtils.getSectionSpacing(context);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content with highlighting support
          HighlightedTextWidget(
            text: currentSection.content,
            highlights: _currentSectionHighlights,
            isHighlightMode: widget.isHighlightMode,
            onTextHighlighted: widget.onTextHighlighted,
            onHighlightTapped: _handleHighlightTapped,
            textStyle: widget.contentTextStyle ?? theme.textTheme.bodyLarge?.copyWith(
              height: ResponsiveChapterUtils.getContentLineHeight(context),
              color: theme.colorScheme.onSurface,
              fontSize: ResponsiveChapterUtils.getContentFontSize(context),
            ),
          ),
          
          SizedBox(height: sectionSpacing),
          
          // Key terms section if available
          if (currentSection.hasKeyTerms)
            _buildKeyTermsSection(theme, currentSection),
          
          // Reading progress indicator
          SizedBox(height: sectionSpacing * 1.5),
          _buildReadingProgressIndicator(theme),
        ],
      ),
    );
  }

  /// Builds the empty state when no section is available
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a section to read',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the key terms section
  Widget _buildKeyTermsSection(ThemeData theme, ChapterSection section) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Terms',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: section.keyTerms.map((term) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                term,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds a reading progress indicator at the bottom
  Widget _buildReadingProgressIndicator(ThemeData theme) {
    final progressPercentage = (_currentScrollProgress * 100).round();
    final readingTimeMinutes = (_totalReadingTime / 60).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: _currentScrollProgress,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasReachedBottom ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progressPercentage%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Status text
          Row(
            children: [
              Text(
                _hasReachedBottom ? 'Section completed' : 'Reading in progress',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _hasReachedBottom ? Colors.green : theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              if (readingTimeMinutes > 0)
                Text(
                  '${readingTimeMinutes}m read',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}