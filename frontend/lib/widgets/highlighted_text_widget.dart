import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:scholar_lens/models/text_highlight.dart';
class HighlightedTextWidget extends StatefulWidget {
  final String text;
  final List<TextHighlight> highlights;
  final bool isHighlightMode;
  final Function(String selectedText, int startOffset, int endOffset)? onTextHighlighted;
  final Function(TextHighlight highlight)? onHighlightTapped;
  final TextStyle? textStyle;
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
      style: widget.textStyle ?? defaultTextStyle,
      onSelectionChanged: widget.isHighlightMode ? _handleSelectionChanged : null,
      contextMenuBuilder: widget.isHighlightMode 
          ? _buildHighlightContextMenu 
          : null,
    );
  }
  TextSpan _buildTextSpan(BuildContext context) {
    if (widget.highlights.isEmpty) {
      return TextSpan(text: widget.text);
    }
    final sortedHighlights = List<TextHighlight>.from(widget.highlights)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    final spans = <TextSpan>[];
    int currentOffset = 0;
    for (final highlight in sortedHighlights) {
      if (highlight.startOffset > currentOffset) {
        spans.add(TextSpan(
          text: widget.text.substring(currentOffset, highlight.startOffset),
        ));
      }
      spans.add(TextSpan(
        text: highlight.highlightedText,
        style: TextStyle(
          backgroundColor: highlight.highlightColor.withValues(alpha: 0.3),
          color: _getContrastingTextColor(highlight.highlightColor),
        ),
        recognizer: widget.onHighlightTapped != null
            ? (TapGestureRecognizer()
                ..onTap = () => widget.onHighlightTapped!(highlight))
            : null,
      ));
      currentOffset = highlight.endOffset;
    }
    if (currentOffset < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(currentOffset),
      ));
    }
    return TextSpan(children: spans);
  }
  Color _getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    setState(() {
      _currentSelection = selection;
    });
    if (cause == SelectionChangedCause.tap && 
        selection.isValid && 
        !selection.isCollapsed &&
        widget.onTextHighlighted != null) {
      final selectedText = widget.text.substring(selection.start, selection.end);
      widget.onTextHighlighted!(selectedText, selection.start, selection.end);
      HapticFeedback.selectionClick();
    }
  }
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
      setState(() {
        _currentSelection = null;
      });
      HapticFeedback.mediumImpact();
    }
  }
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