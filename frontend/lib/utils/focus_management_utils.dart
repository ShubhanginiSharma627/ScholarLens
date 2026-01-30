import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class FocusManagementUtils {
  static FocusNode createManagedFocusNode({
    String? debugLabel,
    bool canRequestFocus = true,
    bool skipTraversal = false,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      canRequestFocus: canRequestFocus,
      skipTraversal: skipTraversal,
    );
  }
  static Widget createFocusScope({
    required Widget child,
    FocusScopeNode? node,
    bool autofocus = false,
    ValueChanged<bool>? onFocusChange,
  }) {
    return FocusScope(
      node: node,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      child: child,
    );
  }
  static Widget createFocusableWidget({
    required Widget child,
    required FocusNode focusNode,
    VoidCallback? onTap,
    VoidCallback? onFocusChange,
    bool showFocusIndicator = true,
    Color? focusColor,
    double focusWidth = 2.0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        onFocusChange?.call();
      },
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final hasFocus = focusNode.hasFocus;
          return GestureDetector(
            onTap: () {
              focusNode.requestFocus();
              onTap?.call();
            },
            child: Container(
              padding: padding,
              decoration: showFocusIndicator && hasFocus
                  ? BoxDecoration(
                      border: Border.all(
                        color: focusColor ?? theme.colorScheme.primary,
                        width: focusWidth,
                      ),
                      borderRadius: borderRadius ?? BorderRadius.circular(8),
                    )
                  : null,
              child: child,
            ),
          );
        },
      ),
    );
  }
  static Widget createKeyboardNavigationHandler({
    required Widget child,
    Map<LogicalKeySet, VoidCallback>? shortcuts,
    Map<Type, Action<Intent>>? actions,
  }) {
    final defaultShortcuts = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.tab): NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift): PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): PreviousFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.space): ActivateIntent(),
    };
    final defaultActions = <Type, Action<Intent>>{
      NextFocusIntent: CallbackAction<NextFocusIntent>(
        onInvoke: (intent) => FocusScope.of(child as BuildContext).nextFocus(),
      ),
      PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
        onInvoke: (intent) => FocusScope.of(child as BuildContext).previousFocus(),
      ),
    };
    return Shortcuts(
      shortcuts: {
        ...defaultShortcuts,
        if (shortcuts != null)
          ...shortcuts.map((key, callback) => MapEntry(key, CallbackIntent(callback))),
      },
      child: Actions(
        actions: {
          ...defaultActions,
          if (actions != null) ...actions,
          CallbackIntent: CallbackAction<CallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: child,
      ),
    );
  }
  static Widget createFocusTraversalGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
    bool descendantsAreFocusable = true,
    bool descendantsAreTraversable = true,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
      child: child,
    );
  }
  static Widget createFocusOrder({
    required Widget child,
    required double order,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
  static Widget createFocusableButton({
    required Widget child,
    required VoidCallback? onPressed,
    FocusNode? focusNode,
    bool autofocus = false,
    String? tooltip,
    Color? focusColor,
    double? focusWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    final buttonFocusNode = focusNode ?? FocusNode();
    return Focus(
      focusNode: buttonFocusNode,
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final hasFocus = buttonFocusNode.hasFocus;
          Widget button = ElevatedButton(
            onPressed: onPressed,
            focusNode: buttonFocusNode,
            child: child,
          );
          if (tooltip != null) {
            button = Tooltip(
              message: tooltip,
              child: button,
            );
          }
          return Container(
            decoration: hasFocus
                ? BoxDecoration(
                    border: Border.all(
                      color: focusColor ?? theme.colorScheme.primary,
                      width: focusWidth ?? 2.0,
                    ),
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                  )
                : null,
            child: button,
          );
        },
      ),
    );
  }
  static Widget createFocusableCard({
    required Widget child,
    VoidCallback? onTap,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? focusColor,
    double? elevation,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    final cardFocusNode = focusNode ?? FocusNode();
    return Focus(
      focusNode: cardFocusNode,
      autofocus: autofocus,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final hasFocus = cardFocusNode.hasFocus;
          return Card(
            elevation: hasFocus ? (elevation ?? 4.0) * 1.5 : elevation,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              side: hasFocus
                  ? BorderSide(
                      color: focusColor ?? theme.colorScheme.primary,
                      width: 2.0,
                    )
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () {
                cardFocusNode.requestFocus();
                onTap?.call();
              },
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16.0),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
  static Widget createFocusIndicator({
    required Widget child,
    required bool hasFocus,
    Color? color,
    double width = 2.0,
    BorderRadius? borderRadius,
    bool showOnlyOnKeyboard = true,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final shouldShow = hasFocus && (!showOnlyOnKeyboard || _isKeyboardNavigation(context));
        return Container(
          decoration: shouldShow
              ? BoxDecoration(
                  border: Border.all(
                    color: color ?? theme.colorScheme.primary,
                    width: width,
                  ),
                  borderRadius: borderRadius ?? BorderRadius.circular(8),
                )
              : null,
          child: child,
        );
      },
    );
  }
  static List<Widget> createFocusableList({
    required List<Widget> children,
    required List<FocusNode> focusNodes,
    FocusTraversalPolicy? policy,
  }) {
    assert(children.length == focusNodes.length, 
           'Children and focus nodes lists must have the same length');
    return List.generate(children.length, (index) {
      return FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: Focus(
          focusNode: focusNodes[index],
          child: children[index],
        ),
      );
    });
  }
  static Widget createModalFocusScope({
    required Widget child,
    bool trapFocus = true,
    FocusNode? initialFocus,
  }) {
    return FocusScope(
      child: FocusTraversalGroup(
        policy: trapFocus ? _ModalTraversalPolicy() : OrderedTraversalPolicy(),
        child: child,
      ),
    );
  }
  static void requestFocusWithDelay(FocusNode focusNode, {Duration delay = const Duration(milliseconds: 100)}) {
    Future.delayed(delay, () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  static bool _isKeyboardNavigation(BuildContext context) {
    return FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
  }
  static void disposeFocusNodes(List<FocusNode> focusNodes) {
    for (final node in focusNodes) {
      node.dispose();
    }
  }
}
class CallbackIntent extends Intent {
  final VoidCallback callback;
  const CallbackIntent(this.callback);
}
class _ModalTraversalPolicy extends FocusTraversalPolicy {
  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    return descendants.toList()..sort((a, b) => a.rect.top.compareTo(b.rect.top));
  }
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final sorted = sortDescendants(currentNode.nearestScope!.traversalDescendants, currentNode).toList();
    final currentIndex = sorted.indexOf(currentNode);
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.left:
        if (currentIndex > 0) {
          sorted[currentIndex - 1].requestFocus();
          return true;
        } else {
          sorted.last.requestFocus();
          return true;
        }
      case TraversalDirection.down:
      case TraversalDirection.right:
        if (currentIndex < sorted.length - 1) {
          sorted[currentIndex + 1].requestFocus();
          return true;
        } else {
          sorted.first.requestFocus();
          return true;
        }
    }
  }
  @override
  FocusNode? findFirstFocusInDirection(FocusNode currentNode, TraversalDirection direction) {
    final sorted = sortDescendants(currentNode.nearestScope!.traversalDescendants, currentNode).toList();
    if (sorted.isEmpty) return null;
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.left:
        return sorted.last;
      case TraversalDirection.down:
      case TraversalDirection.right:
        return sorted.first;
    }
  }
}
mixin FocusManagementMixin<T extends StatefulWidget> on State<T> {
  final List<FocusNode> _focusNodes = [];
  FocusNode createFocusNode({
    String? debugLabel,
    bool canRequestFocus = true,
    bool skipTraversal = false,
  }) {
    final node = FocusNode(
      debugLabel: debugLabel,
      canRequestFocus: canRequestFocus,
      skipTraversal: skipTraversal,
    );
    _focusNodes.add(node);
    return node;
  }
  void disposeFocusNodes() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
  }
  @override
  void dispose() {
    disposeFocusNodes();
    super.dispose();
  }
}