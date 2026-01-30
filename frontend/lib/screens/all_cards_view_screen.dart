import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../widgets/flashcard/card_list_item.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'flashcard_screen.dart';
import 'create_flashcard_screen.dart';
class AllCardsViewScreen extends StatefulWidget {
  final String subject;
  final List<Flashcard>? initialCards;
  const AllCardsViewScreen({
    super.key,
    required this.subject,
    this.initialCards,
  });
  @override
  State<AllCardsViewScreen> createState() => _AllCardsViewScreenState();
}
class _AllCardsViewScreenState extends State<AllCardsViewScreen>
    with SingleTickerProviderStateMixin {
  final FlashcardService _flashcardService = FlashcardService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Flashcard> _allCards = [];
  List<Flashcard> _filteredCards = [];
  List<String> _categories = [];
  String? _selectedCategory;
  Difficulty? _selectedDifficulty;
  bool _showMasteredOnly = false;
  bool _showDueOnly = false;
  bool _isLoading = true;
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _loadCards();
    _searchController.addListener(_onSearchChanged);
  }
  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<Flashcard> cards;
      if (widget.initialCards != null) {
        cards = widget.initialCards!;
      } else {
        cards = await _flashcardService.getFlashcardsBySubject(widget.subject);
      }
      final categories = await _flashcardService.getCategories();
      setState(() {
        _allCards = cards;
        _filteredCards = cards;
        _categories = categories;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cards: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
  }
  void _applyFilters() {
    setState(() {
      _filteredCards = _allCards.where((card) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = card.question.toLowerCase().contains(query) ||
              card.answer.toLowerCase().contains(query) ||
              card.subject.toLowerCase().contains(query) ||
              (card.category?.toLowerCase().contains(query) ?? false);
          if (!matchesSearch) return false;
        }
        if (_selectedCategory != null && card.category != _selectedCategory) {
          return false;
        }
        if (_selectedDifficulty != null && card.difficulty != _selectedDifficulty) {
          return false;
        }
        if (_showMasteredOnly) {
          final isMastered = card.reviewCount >= 3 && card.difficulty == Difficulty.easy;
          if (!isMastered) return false;
        }
        if (_showDueOnly && !card.isDue) {
          return false;
        }
        return true;
      }).toList();
    });
  }
  void _navigateToStudyMode(int startIndex) {
    final studyCards = [
      _filteredCards[startIndex],
      ..._filteredCards.sublist(0, startIndex),
      ..._filteredCards.sublist(startIndex + 1),
    ];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          flashcards: studyCards,
          subject: widget.subject,
        ),
      ),
    );
  }
  void _navigateToGenerateCards() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CreateFlashcardScreen(),
      ),
    );
    if (result == true) {
      await _loadCards();
    }
  }
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }
  Widget _buildFilterBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
      ),
      padding: EdgeInsets.only(
        left: AppTheme.spacingL,
        right: AppTheme.spacingL,
        top: AppTheme.spacingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Filter Cards',
            style: AppTypography.getTextStyle(context, 'headlineMedium').copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_categories.isNotEmpty) ...[
            Text(
              'Category',
              style: AppTypography.getTextStyle(context, 'titleMedium').copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Wrap(
              spacing: AppTheme.spacingS,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
                ..._categories.map((category) => FilterChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
          ],
          Text(
            'Difficulty',
            style: AppTypography.getTextStyle(context, 'titleMedium').copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedDifficulty == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedDifficulty = null;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              ...Difficulty.values.map((difficulty) => FilterChip(
                label: Text(difficulty.displayName),
                selected: _selectedDifficulty == difficulty,
                onSelected: (selected) {
                  setState(() {
                    _selectedDifficulty = selected ? difficulty : null;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              )),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Status',
            style: AppTypography.getTextStyle(context, 'titleMedium').copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          SwitchListTile(
            title: const Text('Show mastered cards only'),
            value: _showMasteredOnly,
            onChanged: (value) {
              setState(() {
                _showMasteredOnly = value;
                if (value) _showDueOnly = false; // Can't show both
              });
              _applyFilters();
            },
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Show due cards only'),
            value: _showDueOnly,
            onChanged: (value) {
              setState(() {
                _showDueOnly = value;
                if (value) _showMasteredOnly = false; // Can't show both
              });
              _applyFilters();
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedDifficulty = null;
                  _showMasteredOnly = false;
                  _showDueOnly = false;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('Clear All Filters'),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subject,
          style: AppTypography.getTextStyle(context, 'headlineMedium').copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter cards',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _buildSearchHeader(isDark),
                Expanded(
                  child: _filteredCards.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildCardsList(isDark),
                ),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fadeAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _navigateToGenerateCards,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Generate More Cards',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark 
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.secondaryTextColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
                hintStyle: TextStyle(
                  color: isDark 
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.secondaryTextColor,
                ),
              ),
              style: AppTypography.getTextStyle(context, 'bodyLarge'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      '${_filteredCards.length} cards',
                      style: AppTypography.getTextStyle(context, 'labelMedium').copyWith(
                        fontWeight: AppTypography.semiBold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              if (_hasActiveFilters()) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt_rounded,
                        size: 16,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Filtered',
                        style: AppTypography.getTextStyle(context, 'labelMedium').copyWith(
                          fontWeight: AppTypography.semiBold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (_filteredCards.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _navigateToStudyMode(0),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Study All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildCardsList(bool isDark) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 50,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: AppTheme.spacingS,
                bottom: 100, // Space for FAB
              ),
              itemCount: _filteredCards.length,
              itemBuilder: (context, index) {
                final card = _filteredCards[index];
                final isMastered = card.reviewCount >= 3 && card.difficulty == Difficulty.easy;
                return CardListItem(
                  flashcard: card,
                  isMastered: isMastered,
                  cardNumber: index + 1,
                  onTap: () => _navigateToStudyMode(index),
                );
              },
            ),
          ),
        );
      },
    );
  }
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty || _hasActiveFilters()
                    ? Icons.search_off_rounded
                    : Icons.style_rounded,
                size: 64,
                color: isDark 
                    ? AppTheme.darkSecondaryTextColor
                    : AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              _searchQuery.isNotEmpty || _hasActiveFilters()
                  ? 'No cards match your search'
                  : 'No cards available',
              style: AppTypography.getTextStyle(context, 'headlineSmall').copyWith(
                fontWeight: AppTypography.semiBold,
                color: isDark 
                    ? AppTheme.darkPrimaryTextColor
                    : AppTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _searchQuery.isNotEmpty || _hasActiveFilters()
                  ? 'Try adjusting your search or filters'
                  : 'Generate some flashcards to start studying!',
              style: AppTypography.getTextStyle(context, 'bodyLarge').copyWith(
                color: isDark 
                    ? AppTheme.darkSecondaryTextColor
                    : AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            if (_searchQuery.isNotEmpty || _hasActiveFilters())
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategory = null;
                    _selectedDifficulty = null;
                    _showMasteredOnly = false;
                    _showDueOnly = false;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Search & Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: _navigateToGenerateCards,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generate Cards'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedDifficulty != null ||
        _showMasteredOnly ||
        _showDueOnly;
  }
}