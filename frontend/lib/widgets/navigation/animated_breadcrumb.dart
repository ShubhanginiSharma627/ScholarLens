import 'package:flutter/material.dart';
import '../../animations/animation_manager.dart';
import '../../animations/animation_config.dart';
class AnimatedBreadcrumb extends StatefulWidget {
  final List<BreadcrumbItem> items;
  final Function(int)? onTap;
  final Color? textColor;
  final Color? activeColor;
  final double? fontSize;
  const AnimatedBreadcrumb({
    super.key,
    required this.items,
    this.onTap,
    this.textColor,
    this.activeColor,
    this.fontSize,
  });
  @override
  State<AnimatedBreadcrumb> createState() => _AnimatedBreadcrumbState();
}
class _AnimatedBreadcrumbState extends State<AnimatedBreadcrumb>
    with TickerProviderStateMixin {
  late AnimationManager _animationManager;
  final Map<int, String> _slideAnimationIds = {};
  final Map<int, String> _fadeAnimationIds = {};
  List<BreadcrumbItem> _previousItems = [];
  @override
  void initState() {
    super.initState();
    _animationManager = AnimationManager();
    _previousItems = List.from(widget.items);
    _initializeAnimations();
  }
  void _initializeAnimations() {
    for (int i = 0; i < widget.items.length; i++) {
      _slideAnimationIds[i] = _animationManager.createSlideAnimation(
        vsync: this,
        duration: Duration(milliseconds: 300 + (i * 50)), // Staggered timing
        slideStart: const Offset(0.3, 0.0),
        slideEnd: Offset.zero,
        curve: Curves.easeOut,
        category: AnimationCategory.content,
      );
      _fadeAnimationIds[i] = _animationManager.createFadeAnimation(
        vsync: this,
        duration: Duration(milliseconds: 200 + (i * 30)),
        fadeStart: 0.0,
        fadeEnd: 1.0,
        curve: Curves.easeInOut,
        category: AnimationCategory.content,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateItemsIn();
    });
  }
  @override
  void didUpdateWidget(AnimatedBreadcrumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        !_itemsEqual(oldWidget.items, widget.items)) {
      _handleItemsChange(oldWidget.items, widget.items);
    }
  }
  bool _itemsEqual(List<BreadcrumbItem> a, List<BreadcrumbItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].title != b[i].title || a[i].route != b[i].route) {
        return false;
      }
    }
    return true;
  }
  void _handleItemsChange(List<BreadcrumbItem> oldItems, List<BreadcrumbItem> newItems) {
    for (final id in _slideAnimationIds.values) {
      _animationManager.disposeController(id);
    }
    for (final id in _fadeAnimationIds.values) {
      _animationManager.disposeController(id);
    }
    _slideAnimationIds.clear();
    _fadeAnimationIds.clear();
    _initializeAnimations();
  }
  void _animateItemsIn() {
    for (int i = 0; i < widget.items.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          _animationManager.startAnimation(_slideAnimationIds[i]!);
          _animationManager.startAnimation(_fadeAnimationIds[i]!);
        }
      });
    }
  }
  @override
  void dispose() {
    for (final id in _slideAnimationIds.values) {
      _animationManager.disposeController(id);
    }
    for (final id in _fadeAnimationIds.values) {
      _animationManager.disposeController(id);
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.textColor ?? theme.textTheme.bodyMedium?.color ?? Colors.black;
    final activeColor = widget.activeColor ?? theme.primaryColor;
    final fontSize = widget.fontSize ?? 14.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(textColor, activeColor, fontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> _buildBreadcrumbItems(Color textColor, Color activeColor, double fontSize) {
    final items = <Widget>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isLast = i == widget.items.length - 1;
      final slideAnimationId = _slideAnimationIds[i];
      final fadeAnimationId = _fadeAnimationIds[i];
      items.add(
        AnimatedBuilder(
          animation: slideAnimationId != null 
              ? _animationManager.getAnimation(slideAnimationId)?.controller ?? 
                const AlwaysStoppedAnimation(1.0)
              : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            final slideAnimation = slideAnimationId != null 
                ? _animationManager.getAnimation(slideAnimationId)?.animation as Animation<Offset>?
                : null;
            final fadeAnimation = fadeAnimationId != null 
                ? _animationManager.getAnimation(fadeAnimationId)?.animation as Animation<double>?
                : null;
            final slideOffset = slideAnimation?.value ?? Offset.zero;
            final opacity = fadeAnimation?.value ?? 1.0;
            return Transform.translate(
              offset: slideOffset * 20, // Scale the offset
              child: Opacity(
                opacity: opacity,
                child: _buildBreadcrumbItem(
                  item: item,
                  index: i,
                  isLast: isLast,
                  textColor: textColor,
                  activeColor: activeColor,
                  fontSize: fontSize,
                ),
              ),
            );
          },
        ),
      );
      if (!isLast) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right,
              size: fontSize,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        );
      }
    }
    return items;
  }
  Widget _buildBreadcrumbItem({
    required BreadcrumbItem item,
    required int index,
    required bool isLast,
    required Color textColor,
    required Color activeColor,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: widget.onTap != null && !isLast ? () => widget.onTap!(index) : null,
      child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 200),
        tween: ColorTween(
          begin: textColor,
          end: isLast ? activeColor : textColor,
        ),
        builder: (context, color, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isLast ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: fontSize,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: color,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class BreadcrumbItem {
  final String title;
  final String route;
  final IconData? icon;
  const BreadcrumbItem({
    required this.title,
    required this.route,
    this.icon,
  });
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BreadcrumbItem &&
        other.title == title &&
        other.route == route &&
        other.icon == icon;
  }
  @override
  int get hashCode => Object.hash(title, route, icon);
}