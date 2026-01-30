import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_manager.dart';
import 'animation_config.dart';
class AnimatedSearchFilter extends StatefulWidget {
  final List<Widget> allItems;
  final bool Function(int index, String query) itemFilter;
  final String searchQuery;
  final Duration fadeDuration;
  final Duration layoutDuration;
  final Curve fadeCurve;
  final Curve layoutCurve;
  final bool animateLayout;
  final bool staggerAnimations;
  final Duration staggerDelay;
  final Widget? emptyStateWidget;
  final bool animateEmptyState;
  final VoidCallback? onFilterComplete;
  final int animationPriority;
  const AnimatedSearchFilter({
    super.key,
    required this.allItems,
    required this.itemFilter,
    required this.searchQuery,
    this.fadeDuration = const Duration(milliseconds: 200),
    this.layoutDuration = const Duration(milliseconds: 300),
    this.fadeCurve = Curves.easeInOut,
    this.layoutCurve = Curves.easeInOut,
    this.animateLayout = true,
    this.staggerAnimations = true,
    this.staggerDelay = const Duration(milliseconds: 30),
    this.emptyStateWidget,
    this.animateEmptyState = true,
    this.onFilterComplete,
    this.animationPriority = 2,
  });
  @override
  State<AnimatedSearchFilter> createState() => _AnimatedSearchFilterState();
}
class _AnimatedSearchFilterState extends State<AnimatedSearchFilter>
    with TickerProviderStateMixin {
  final AnimationManager _animationManager = AnimationManager();
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];
  final List<String> _animationIds = [];
  late AnimationController _emptyStateController;
  late Animation<double> _emptyStateAnimation;
  String? _emptyStateAnimationId;
  List<bool> _itemVisibility = [];
  List<bool> _previousVisibility = [];
  String _previousQuery = '';
  int _visibleItemCount = 0;
  bool _isAnimating = false;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _emptyStateController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
    _emptyStateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emptyStateController,
      curve: widget.fadeCurve,
    ));
    _initializeItemAnimations();
    _registerAnimations();
    _updateVisibility();
  }
  void _initializeItemAnimations() {
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    _fadeAnimations.clear();
    _scaleAnimations.clear();
    for (int i = 0; i < widget.allItems.length; i++) {
      final controller = AnimationController(
        duration: widget.fadeDuration,
        vsync: this,
      );
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.fadeCurve,
      ));
      final scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.fadeCurve,
      ));
      _itemControllers.add(controller);
      _fadeAnimations.add(fadeAnimation);
      _scaleAnimations.add(scaleAnimation);
      controller.value = 1.0;
    }
    _itemVisibility = List.filled(widget.allItems.length, true);
    _previousVisibility = List.filled(widget.allItems.length, true);
  }
  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      _emptyStateAnimationId = _animationManager.registerController(
        controller: _emptyStateController,
        config: AnimationConfigs.fadeTransition.copyWith(
          duration: widget.fadeDuration,
          curve: widget.fadeCurve,
        ),
        category: AnimationCategory.content,
      );
      for (int i = 0; i < _itemControllers.length; i++) {
        final config = AnimationConfigs.searchFilter.copyWith(
          duration: widget.fadeDuration,
          curve: widget.fadeCurve,
          priority: widget.animationPriority,
        );
        final animationId = _animationManager.registerController(
          controller: _itemControllers[i],
          config: config,
          category: AnimationCategory.content,
        );
        _animationIds.add(animationId);
      }
    }
  }
  @override
  void didUpdateWidget(AnimatedSearchFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allItems.length != oldWidget.allItems.length) {
      _initializeItemAnimations();
      _registerAnimations();
    }
    if (widget.searchQuery != oldWidget.searchQuery) {
      _updateVisibility();
    }
  }
  @override
  void dispose() {
    if (_emptyStateAnimationId != null) {
      _animationManager.disposeController(_emptyStateAnimationId!);
    }
    for (final animationId in _animationIds) {
      _animationManager.disposeController(animationId);
    }
    _emptyStateController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  void _updateVisibility() {
    if (_isAnimating) return;
    _previousVisibility = List.from(_itemVisibility);
    _previousQuery = widget.searchQuery;
    final newVisibility = <bool>[];
    int newVisibleCount = 0;
    for (int i = 0; i < widget.allItems.length; i++) {
      final isVisible = widget.itemFilter(i, widget.searchQuery);
      newVisibility.add(isVisible);
      if (isVisible) newVisibleCount++;
    }
    bool hasChanges = false;
    for (int i = 0; i < newVisibility.length; i++) {
      if (newVisibility[i] != _itemVisibility[i]) {
        hasChanges = true;
        break;
      }
    }
    if (!hasChanges) return;
    setState(() {
      _itemVisibility = newVisibility;
      _visibleItemCount = newVisibleCount;
      _isAnimating = true;
    });
    _animateVisibilityChanges();
  }
  void _animateVisibilityChanges() {
    int completedAnimations = 0;
    final totalAnimations = _itemControllers.length;
    void onAnimationComplete() {
      completedAnimations++;
      if (completedAnimations >= totalAnimations) {
        setState(() {
          _isAnimating = false;
        });
        if (_visibleItemCount == 0) {
          if (widget.animateEmptyState) {
            _emptyStateController.forward();
          }
        } else {
          _emptyStateController.reverse();
        }
        widget.onFilterComplete?.call();
      }
    }
    for (int i = 0; i < _itemControllers.length; i++) {
      final wasVisible = _previousVisibility[i];
      final isVisible = _itemVisibility[i];
      if (wasVisible && !isVisible) {
        final delay = widget.staggerAnimations 
            ? widget.staggerDelay * i 
            : Duration.zero;
        Future.delayed(delay, () {
          if (mounted) {
            _itemControllers[i].reverse().then((_) {
              onAnimationComplete();
            });
          }
        });
      } else if (!wasVisible && isVisible) {
        final delay = widget.staggerAnimations 
            ? widget.staggerDelay * i 
            : Duration.zero;
        Future.delayed(delay, () {
          if (mounted) {
            _itemControllers[i].forward().then((_) {
              onAnimationComplete();
            });
          }
        });
      } else {
        onAnimationComplete();
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(widget.allItems.length, (index) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              _fadeAnimations[index],
              _scaleAnimations[index],
            ]),
            builder: (context, child) {
              final opacity = _fadeAnimations[index].value;
              final scale = _scaleAnimations[index].value;
              if (opacity == 0.0) {
                return const SizedBox.shrink();
              }
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: widget.animateLayout
                      ? AnimatedContainer(
                          duration: widget.layoutDuration,
                          curve: widget.layoutCurve,
                          height: _itemVisibility[index] ? null : 0,
                          child: widget.allItems[index],
                        )
                      : widget.allItems[index],
                ),
              );
            },
          );
        }),
        if (widget.emptyStateWidget != null)
          AnimatedBuilder(
            animation: _emptyStateAnimation,
            builder: (context, child) {
              if (_visibleItemCount > 0 && _emptyStateAnimation.value == 0.0) {
                return const SizedBox.shrink();
              }
              return Opacity(
                opacity: _emptyStateAnimation.value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * _emptyStateAnimation.value),
                  child: widget.emptyStateWidget,
                ),
              );
            },
          ),
      ],
    );
  }
}
class AnimatedSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<String> suggestions;
  final List<FilterChip> filterChips;
  final ValueChanged<String>? onSuggestionSelected;
  final String hintText;
  final bool showSuggestions;
  final bool showFilterChips;
  final Duration suggestionDuration;
  final Duration chipDuration;
  final int maxSuggestions;
  final bool enableHapticFeedback;
  const AnimatedSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    this.suggestions = const [],
    this.filterChips = const [],
    this.onSuggestionSelected,
    this.hintText = 'Search...',
    this.showSuggestions = true,
    this.showFilterChips = true,
    this.suggestionDuration = const Duration(milliseconds: 200),
    this.chipDuration = const Duration(milliseconds: 150),
    this.maxSuggestions = 5,
    this.enableHapticFeedback = true,
  });
  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}
class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with TickerProviderStateMixin {
  final AnimationManager _animationManager = AnimationManager();
  late AnimationController _suggestionController;
  late AnimationController _chipController;
  late Animation<double> _suggestionAnimation;
  late Animation<double> _chipAnimation;
  String? _suggestionAnimationId;
  String? _chipAnimationId;
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _suggestionController = AnimationController(
      duration: widget.suggestionDuration,
      vsync: this,
    );
    _suggestionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _suggestionController,
      curve: Curves.easeOut,
    ));
    _chipController = AnimationController(
      duration: widget.chipDuration,
      vsync: this,
    );
    _chipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chipController,
      curve: Curves.elasticOut,
    ));
    _registerAnimations();
    _focusNode.addListener(_handleFocusChange);
    if (widget.filterChips.isNotEmpty) {
      _chipController.forward();
    }
  }
  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      _suggestionAnimationId = _animationManager.registerController(
        controller: _suggestionController,
        config: AnimationConfigs.searchSuggestions.copyWith(
          duration: widget.suggestionDuration,
        ),
        category: AnimationCategory.content,
      );
      _chipAnimationId = _animationManager.registerController(
        controller: _chipController,
        config: AnimationConfigs.filterChip.copyWith(
          duration: widget.chipDuration,
        ),
        category: AnimationCategory.microInteraction,
      );
    }
  }
  @override
  void didUpdateWidget(AnimatedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterChips.length != oldWidget.filterChips.length) {
      if (widget.filterChips.isNotEmpty) {
        _chipController.forward();
      } else {
        _chipController.reverse();
      }
    }
    if (widget.query != oldWidget.query) {
      _updateSuggestionsVisibility();
    }
  }
  @override
  void dispose() {
    if (_suggestionAnimationId != null) {
      _animationManager.disposeController(_suggestionAnimationId!);
    }
    if (_chipAnimationId != null) {
      _animationManager.disposeController(_chipAnimationId!);
    }
    _suggestionController.dispose();
    _chipController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  void _handleFocusChange() {
    _updateSuggestionsVisibility();
  }
  void _updateSuggestionsVisibility() {
    final shouldShow = _focusNode.hasFocus && 
                      widget.showSuggestions && 
                      widget.suggestions.isNotEmpty &&
                      widget.query.isNotEmpty;
    if (shouldShow != _showSuggestions) {
      setState(() {
        _showSuggestions = shouldShow;
      });
      if (_showSuggestions) {
        _suggestionController.forward();
      } else {
        _suggestionController.reverse();
      }
    }
  }
  void _handleSuggestionTap(String suggestion) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onSuggestionSelected?.call(suggestion);
    _focusNode.unfocus();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          focusNode: _focusNode,
          onChanged: widget.onQueryChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => widget.onQueryChanged(''),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        if (widget.showFilterChips && widget.filterChips.isNotEmpty)
          AnimatedBuilder(
            animation: _chipAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _chipAnimation.value,
                child: Opacity(
                  opacity: _chipAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.filterChips.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => widget.filterChips[index],
                    ),
                  ),
                ),
              );
            },
          ),
        AnimatedBuilder(
          animation: _suggestionAnimation,
          builder: (context, child) {
            if (!_showSuggestions && _suggestionAnimation.value == 0.0) {
              return const SizedBox.shrink();
            }
            return Transform.translate(
              offset: Offset(0, -10 * (1 - _suggestionAnimation.value)),
              child: Opacity(
                opacity: _suggestionAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: widget.suggestions
                        .take(widget.maxSuggestions)
                        .map((suggestion) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.search, size: 16),
                              title: Text(suggestion),
                              onTap: () => _handleSuggestionTap(suggestion),
                            ))
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
extension SearchFilterAnimationExtensions on List<Widget> {
  Widget asAnimatedFilter({
    required bool Function(int index, String query) itemFilter,
    required String searchQuery,
    Duration fadeDuration = const Duration(milliseconds: 200),
    Duration layoutDuration = const Duration(milliseconds: 300),
    Curve fadeCurve = Curves.easeInOut,
    Curve layoutCurve = Curves.easeInOut,
    bool animateLayout = true,
    bool staggerAnimations = true,
    Duration staggerDelay = const Duration(milliseconds: 30),
    Widget? emptyStateWidget,
    bool animateEmptyState = true,
    VoidCallback? onFilterComplete,
  }) {
    return AnimatedSearchFilter(
      allItems: this,
      itemFilter: itemFilter,
      searchQuery: searchQuery,
      fadeDuration: fadeDuration,
      layoutDuration: layoutDuration,
      fadeCurve: fadeCurve,
      layoutCurve: layoutCurve,
      animateLayout: animateLayout,
      staggerAnimations: staggerAnimations,
      staggerDelay: staggerDelay,
      emptyStateWidget: emptyStateWidget,
      animateEmptyState: animateEmptyState,
      onFilterComplete: onFilterComplete,
    );
  }
}
class SearchFilterAnimationConfigs {
  static Widget fast(
    List<Widget> items, {
    required bool Function(int index, String query) itemFilter,
    required String searchQuery,
    Widget? emptyStateWidget,
    VoidCallback? onFilterComplete,
  }) {
    return items.asAnimatedFilter(
      itemFilter: itemFilter,
      searchQuery: searchQuery,
      fadeDuration: const Duration(milliseconds: 100),
      layoutDuration: const Duration(milliseconds: 150),
      staggerDelay: const Duration(milliseconds: 15),
      emptyStateWidget: emptyStateWidget,
      onFilterComplete: onFilterComplete,
    );
  }
  static Widget smooth(
    List<Widget> items, {
    required bool Function(int index, String query) itemFilter,
    required String searchQuery,
    Widget? emptyStateWidget,
    VoidCallback? onFilterComplete,
  }) {
    return items.asAnimatedFilter(
      itemFilter: itemFilter,
      searchQuery: searchQuery,
      fadeDuration: const Duration(milliseconds: 200),
      layoutDuration: const Duration(milliseconds: 300),
      staggerDelay: const Duration(milliseconds: 30),
      emptyStateWidget: emptyStateWidget,
      onFilterComplete: onFilterComplete,
    );
  }
  static Widget dramatic(
    List<Widget> items, {
    required bool Function(int index, String query) itemFilter,
    required String searchQuery,
    Widget? emptyStateWidget,
    VoidCallback? onFilterComplete,
  }) {
    return items.asAnimatedFilter(
      itemFilter: itemFilter,
      searchQuery: searchQuery,
      fadeDuration: const Duration(milliseconds: 400),
      layoutDuration: const Duration(milliseconds: 500),
      fadeCurve: Curves.elasticOut,
      layoutCurve: Curves.elasticOut,
      staggerDelay: const Duration(milliseconds: 50),
      emptyStateWidget: emptyStateWidget,
      onFilterComplete: onFilterComplete,
    );
  }
}