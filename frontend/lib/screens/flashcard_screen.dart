import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/study_session_progress.dart';
import '../widgets/flashcard/enhanced_flashcard_widget.dart';
import '../widgets/flashcard/modern_progress_tracker.dart';
import '../widgets/difficulty_rating_bar.dart';
class FlashcardScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  final String? subject;
  const FlashcardScreen({
    super.key,
    required this.flashcards,
    this.subject,
  });
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}
class _FlashcardScreenState extends State<FlashcardScreen> 
    with TickerProviderStateMixin {
  late PageController _pageController;
  late StudySessionProgress _sessionProgress;
  late AnimationController _progressAnimationController;
  late AnimationController _uiElementsController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Map<int, Difficulty?> _ratings = {};
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _sessionProgress = StudySessionProgress.initial(
      totalCards: widget.flashcards.length,
      subject: widget.subject,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _uiElementsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiElementsController,
      curve: Curves.easeInOut,
    ));
    _progressAnimationController.forward();
    _uiElementsController.forward();
  }
  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _uiElementsController.dispose();
    super.dispose();
  }
  void _onFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }
  void _onDifficultyRated(Difficulty difficulty) {
    setState(() {
      _ratings[_currentIndex] = difficulty;
      _sessionProgress = _sessionProgress.rateCard(
        widget.flashcards[_currentIndex].id,
        difficulty,
      );
    });
    _progressAnimationController.reset();
    _progressAnimationController.forward();
    if (_currentIndex < widget.flashcards.length - 1) {
      _nextCard();
    }
  }
  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      _uiElementsController.reverse().then((_) {
        setState(() {
          _currentIndex++;
          _isFlipped = false;
          _sessionProgress = _sessionProgress.nextCard();
        });
        _progressAnimationController.reset();
        _progressAnimationController.forward();
        _uiElementsController.forward();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  void _previousCard() {
    if (_currentIndex > 0) {
      _uiElementsController.reverse().then((_) {
        setState(() {
          _currentIndex--;
          _isFlipped = false;
          _sessionProgress = _sessionProgress.previousCard();
        });
        _progressAnimationController.reset();
        _progressAnimationController.forward();
        _uiElementsController.forward();
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
      _sessionProgress = _sessionProgress.jumpToCard(index);
    });
    _progressAnimationController.reset();
    _progressAnimationController.forward();
  }
  Widget _buildAnimatedNavButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: onPressed != null 
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: onPressed != null 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 28,
              color: onPressed != null 
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subject ?? 'Flashcards'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.style,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No flashcards available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create some flashcards to start studying!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject ?? 'Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return ModernProgressTracker(
                  totalCards: widget.flashcards.length,
                  masteredCards: (_sessionProgress.easyCount + _sessionProgress.mediumCount),
                  correctCount: _sessionProgress.correctCount,
                  incorrectCount: _sessionProgress.incorrectCount,
                  completionPercentage: _sessionProgress.completionPercentage * _progressAnimation.value,
                  showCounters: true,
                  showMasteryStats: false, // Hide mastery stats during study session
                );
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: widget.flashcards.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;
                                if (_pageController.position.haveDimensions) {
                                  value = _pageController.page! - index;
                                  value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                                }
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: EnhancedFlashcardWidget(
                                        flashcard: widget.flashcards[index],
                                        isFlipped: index == _currentIndex ? _isFlipped : false,
                                        onFlip: index == _currentIndex ? _onFlip : () {},
                                        onDifficultyRated: index == _currentIndex ? _onDifficultyRated : (_) {},
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Card ${_currentIndex + 1} of ${widget.flashcards.length}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAnimatedNavButton(
                                onPressed: _currentIndex > 0 ? _previousCard : null,
                                icon: Icons.arrow_back_ios,
                                tooltip: 'Previous Card',
                              ),
                              _buildAnimatedNavButton(
                                onPressed: _onFlip,
                                icon: _isFlipped ? Icons.visibility_off : Icons.visibility,
                                tooltip: _isFlipped ? 'Hide Answer' : 'Show Answer',
                              ),
                              _buildAnimatedNavButton(
                                onPressed: _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
                                icon: Icons.arrow_forward_ios,
                                tooltip: 'Next Card',
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 1.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _isFlipped
                            ? Container(
                                key: const ValueKey('difficulty_rating'),
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.25, // Max 25% of available height
                                ),
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: DifficultyRatingBar(
                                    onRatingSelected: _onDifficultyRated,
                                    selectedRating: _ratings[_currentIndex],
                                  ),
                                ),
                              )
                            : Container(
                                key: const ValueKey('empty_space'),
                                height: 0,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}