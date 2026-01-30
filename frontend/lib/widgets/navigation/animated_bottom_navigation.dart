import 'package:flutter/material.dart';
import '../../animations/animation_manager.dart';
import '../../animations/animation_config.dart';
class AnimatedBottomNavigation extends StatefulWidget {
  final List<NavigationTab> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double? elevation;
  const AnimatedBottomNavigation({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.elevation,
  });
  @override
  State<AnimatedBottomNavigation> createState() => _AnimatedBottomNavigationState();
}
class _AnimatedBottomNavigationState extends State<AnimatedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationManager _animationManager;
  final Map<int, String> _colorAnimationIds = {};
  final Map<int, String> _scaleAnimationIds = {};
  final Map<int, String> _badgeAnimationIds = {};
  final Map<int, int> _badgeCounts = {1: 3, 3: 1};
  final Map<int, int> _previousBadgeCounts = {};
  bool _animationsInitialized = false;
  @override
  void initState() {
    super.initState();
    _animationManager = AnimationManager();
    _previousBadgeCounts.addAll(_badgeCounts);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsInitialized) {
      if (!_animationManager.isInitialized) {
        _animationManager.initialize().then((_) {
          if (mounted) {
            _initializeAnimations();
            _animationsInitialized = true;
          }
        });
      } else {
        _initializeAnimations();
        _animationsInitialized = true;
      }
    }
  }
  void _initializeAnimations() {
    _disposeExistingAnimations();
    try {
      for (int i = 0; i < widget.tabs.length; i++) {
        if (widget.tabs[i].isCenter != true) {
          _colorAnimationIds[i] = _animationManager.createThemeAwareFadeAnimation(
            vsync: this,
            context: context,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            category: AnimationCategory.microInteraction,
          );
          _scaleAnimationIds[i] = _animationManager.createThemeAwareScaleAnimation(
            vsync: this,
            context: context,
            duration: const Duration(milliseconds: 150),
            scaleStart: 1.0,
            scaleEnd: 1.1,
            curve: Curves.elasticOut,
            category: AnimationCategory.microInteraction,
          );
          _badgeAnimationIds[i] = _animationManager.createScaleAnimation(
            vsync: this,
            duration: const Duration(milliseconds: 300),
            scaleStart: 0.0,
            scaleEnd: 1.0,
            curve: Curves.elasticOut,
            category: AnimationCategory.microInteraction,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize animations: $e');
      _disposeExistingAnimations();
    }
  }
  void _disposeExistingAnimations() {
    try {
      for (final id in _colorAnimationIds.values) {
        _animationManager.disposeController(id);
      }
      for (final id in _scaleAnimationIds.values) {
        _animationManager.disposeController(id);
      }
      for (final id in _badgeAnimationIds.values) {
        _animationManager.disposeController(id);
      }
    } catch (e) {
      debugPrint('Error disposing animations: $e');
    }
    _colorAnimationIds.clear();
    _scaleAnimationIds.clear();
    _badgeAnimationIds.clear();
  }
  @override
  void didUpdateWidget(AnimatedBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _animationsInitialized = false;
      _initializeAnimations();
      _animationsInitialized = true;
    }
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateSelectionChange(oldWidget.currentIndex, widget.currentIndex);
    }
    _checkBadgeChanges();
  }
  void _animateSelectionChange(int oldIndex, int newIndex) {
    if (_scaleAnimationIds.containsKey(oldIndex)) {
      final animation = _animationManager.getAnimation(_scaleAnimationIds[oldIndex]!);
      if (animation != null) {
        animation.controller.reverse();
      }
    }
    if (_scaleAnimationIds.containsKey(newIndex)) {
      _animationManager.startAnimation(_scaleAnimationIds[newIndex]!);
    }
  }
  void _checkBadgeChanges() {
    for (final entry in _badgeCounts.entries) {
      final index = entry.key;
      final currentCount = entry.value;
      final previousCount = _previousBadgeCounts[index] ?? 0;
      if (currentCount != previousCount && currentCount > 0) {
        if (_badgeAnimationIds.containsKey(index)) {
          _animationManager.startAnimation(_badgeAnimationIds[index]!);
        }
      }
    }
    _previousBadgeCounts.clear();
    _previousBadgeCounts.addAll(_badgeCounts);
  }
  @override
  void dispose() {
    try {
      for (final id in _colorAnimationIds.values) {
        _animationManager.disposeController(id);
      }
      for (final id in _scaleAnimationIds.values) {
        _animationManager.disposeController(id);
      }
      for (final id in _badgeAnimationIds.values) {
        _animationManager.disposeController(id);
      }
    } catch (e) {
      debugPrint('Error disposing animations in dispose(): $e');
    }
    _colorAnimationIds.clear();
    _scaleAnimationIds.clear();
    _badgeAnimationIds.clear();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = widget.selectedColor ?? theme.primaryColor;
    final unselectedColor = widget.unselectedColor ?? Colors.grey;
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isCenter = tab.isCenter ?? false;
              bool isSelected = false;
              if (!isCenter) {
                if (index < 2) {
                  isSelected = widget.currentIndex == index;
                } else {
                  isSelected = widget.currentIndex == (index - 1);
                }
              }
              if (isCenter) {
                return _buildCenterButton(tab, index);
              }
              return _buildNavigationTab(
                tab: tab,
                index: index,
                isSelected: isSelected,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  Widget _buildCenterButton(NavigationTab tab, int index) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween(begin: 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildNavigationTab({
    required NavigationTab tab,
    required int index,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final scaleAnimationId = _scaleAnimationIds[index];
    final badgeCount = _badgeCounts[index] ?? 0;
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedBuilder(
        animation: scaleAnimationId != null 
            ? _animationManager.getAnimation(scaleAnimationId)?.controller ?? 
              const AlwaysStoppedAnimation(0.0)
            : const AlwaysStoppedAnimation(0.0),
        builder: (context, child) {
          final scaleAnimation = scaleAnimationId != null 
              ? _animationManager.getAnimation(scaleAnimationId)?.animation as Animation<double>?
              : null;
          final scale = scaleAnimation?.value ?? 1.0;
          return Transform.scale(
            scale: isSelected ? (1.0 + (scale * 0.1)) : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 200),
                        tween: ColorTween(
                          begin: unselectedColor,
                          end: isSelected ? selectedColor : unselectedColor,
                        ),
                        builder: (context, color, child) {
                          return Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: color,
                            size: 24,
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 200),
                        tween: ColorTween(
                          begin: unselectedColor,
                          end: isSelected ? selectedColor : unselectedColor,
                        ),
                        builder: (context, color, child) {
                          return Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _buildAnimatedBadge(index, badgeCount),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildAnimatedBadge(int index, int count) {
    final badgeAnimationId = _badgeAnimationIds[index];
    return AnimatedBuilder(
      animation: badgeAnimationId != null 
          ? _animationManager.getAnimation(badgeAnimationId)?.controller ?? 
            const AlwaysStoppedAnimation(1.0)
          : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final scaleAnimation = badgeAnimationId != null 
            ? _animationManager.getAnimation(badgeAnimationId)?.animation as Animation<double>?
            : null;
        final scale = scaleAnimation?.value ?? 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
class NavigationTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool? isCenter;
  const NavigationTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter,
  });
}