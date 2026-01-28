import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:scholar_lens/models/text_highlight.dart';
import 'package:scholar_lens/theme/app_theme.dart';

/// A widget that displays text with highlighting support and text selection
class HighlightedTextWidget extends StatefulWidget {
  /// The text content to display
  final String text;
  
  /// List of existing highlights to render
  final List<TextHighlight> highlights;
  
  /// Whether highlight mode is active for text selection
  final bool isHighlightMode;
  
  /// Callback when text is selected for highlighting
  final Function(String selectedText, int startOffset, int endOffset)? onTextHighlighted;
  
  /// Callback when a highlight is tapped
  final Function(TextHighlight highlight)? onHighlightTapped;
  
  /// Text style for the content
  final TextStyle? textStyle;
  
  /// Whether text selection is enabled
  final bool enableSelection;

  const HighlightedTextWidget({
    super.key,
    required this.text,
    this.highlights = const [],
    this.isHighlightMode = false,
    this.onTextHighlighted,
    this.onHighlightTapped,
    this.textStyle,
    this.enableSelection = true,
  });

  @override
  State<HighlightedTextWidget> createState() => _HighlightedTextWidgetState();
}

class _HighlightedTextWidgetState extends State<HighlightedTextWidget> {
  final GlobalKey _textKey = GlobalKey();
  TextSelection? _currentSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.6,
      color: theme.colorScheme.onSurface,
    );

    return SelectableText.rich(
      _buildTextSpan(context),
      key: _textKey,
      style: widget.textStyle ?? defaultTextStyle,
      onSelectionChanged: widget.isHighlightMode ? _handleSelectionChanged : null,
      selectionControls: widget.isHighlightMode 
          ? _HighlightSelectionControls(
              onHighlight: _handleHighlightSelection,
            )
          : null,
      contextMenuBuilder: widget.isHighlightMode 
          ? _buildHighlightContextMenu 
          : null,
    );
  }

  /// Builds a TextSpan with highlights applied
  TextSpan _buildTextSpan(BuildContext context) {
    if (widget.highlights.isEmpty) {
      return TextSpan(text: widget.text);
    }

    // Sort highlights by start offset
    final sortedHighlights = List<TextHighlight>.from(widget.highlights)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    final spans = <TextSpan>[];
    int currentOffset = 0;

    for (final highlight in sortedHighlights) {
      // Add text before highlight
      if (highlight.startOffset > currentOffset) {
        spans.add(TextSpan(
          text: widget.text.substring(currentOffset, highlight.startOffset),
        ));
      }

      // Add highlighted text
      spans.add(TextSpan(
        text: highlight.highlightedText,
        style: TextStyle(
          backgroundColor: highlight.highlightColor.withOpacity(0.3),
          color: _getContrastingTextColor(highlight.highlightColor),
        ),
        recognizer: widget.onHighlightTapped != null
            ? (TapGestureRecognizer()
                ..onTap = () => widget.onHighlightTapped!(highlight))
            : null,
      ));

      currentOffset = highlight.endOffset;
    }

    // Add remaining text
    if (currentOffset < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(currentOffset),
      ));
    }

    return TextSpan(children: spans);
  }

  /// Gets a contrasting text color for the given background color
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Handles text selection changes in highlight mode
  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    setState(() {
      _currentSelection = selection;
    });

    // If selection is complete and we have a callback, trigger highlighting
    if (cause == SelectionChangedCause.tap && 
        selection.isValid && 
        !selection.isCollapsed &&
        widget.onTextHighlighted != null) {
      
      final selectedText = widget.text.substring(selection.start, selection.end);
      widget.onTextHighlighted!(selectedText, selection.start, selection.end);
      
      // Provide haptic feedback
      HapticFeedback.selectionClick();
    }
  }

  /// Handles highlight selection from context menu
  void _handleHighlightSelection() {
    if (_currentSelection != null && 
        _currentSelection!.isValid && 
        !_currentSelection!.isCollapsed &&
        widget.onTextHighlighted != null) {
      
      final selectedText = widget.text.substring(
        _currentSelection!.start, 
        _currentSelection!.end,
      );
      
      widget.onTextHighlighted!(
        selectedText, 
        _currentSelection!.start, 
        _currentSelection!.end,
      );
      
      // Clear selection after highlighting
      setState(() {
        _currentSelection = null;
      });
      
      // Provide haptic feedback
      HapticFeedback.mediumImpact();
    }
  }

  /// Builds the context menu for highlighting
  Widget _buildHighlightContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final selection = editableTextState.textEditingValue.selection;
    
    if (selection.isCollapsed) {
      return const SizedBox.shrink();
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: [
        ContextMenuButtonItem(
          onPressed: _handleHighlightSelection,
          label: 'Highlight',
        ),
      ],
    );
  }
}

/// Custom selection controls for highlighting
class _HighlightSelectionControls extends TextSelectionControls {
  final VoidCallback onHighlight;

  _HighlightSelectionControls({required this.onHighlight});

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: TextSelectionToolbarAnchors(
        primaryAnchor: selectionMidpoint,
      ),
      buttonItems: [
        ContextMenuButtonItem(
          onPressed: onHighlight,
          label: 'Highlight',
        ),
      ],
    );
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return const Size(20, 20);
  }
}