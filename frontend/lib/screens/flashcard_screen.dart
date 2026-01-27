import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/study_session_progress.dart';
import '../widgets/flashcard/enhanced_flashcard_widget.dart';
import '../widgets/flashcard/modern_progress_tracker.dart';
import '../widgets/difficulty_rating_bar.dart';

/// Screen for reviewing flashcards with navigation and progress tracking
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

class _FlashcardScreenState extends State<FlashcardScreen> {
  late PageController _pageController;
  late StudySessionProgress _sessionProgress;
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
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      // Update session progress with real-time tracking
      _sessionProgress = _sessionProgress.rateCard(
        widget.flashcards[_currentIndex].id,
        difficulty,
      );
    });
    
    // Auto-advance to next card after rating
    if (_currentIndex < widget.flashcards.length - 1) {
      _nextCard();
    }
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        // Update session progress for navigation
        _sessionProgress = _sessionProgress.nextCard();
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        // Update session progress for navigation
        _sessionProgress = _sessionProgress.previousCard();
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
      // Update session progress when page changes
      _sessionProgress = _sessionProgress.jumpToCard(index);
    });
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
              // TODO: Navigate to create flashcard screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern progress tracker with real-time updates
          ModernProgressTracker(
            totalCards: widget.flashcards.length,
            masteredCards: _sessionProgress.easyCount + _sessionProgress.mediumCount,
            correctCount: _sessionProgress.correctCount,
            incorrectCount: _sessionProgress.incorrectCount,
            completionPercentage: _sessionProgress.completionPercentage,
            showCounters: true,
            showMasteryStats: false, // Hide mastery stats during study session
          ),
          
          // Flashcard display
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.flashcards.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EnhancedFlashcardWidget(
                    flashcard: widget.flashcards[index],
                    isFlipped: _isFlipped,
                    onFlip: _onFlip,
                    onDifficultyRated: _onDifficultyRated,
                  ),
                );
              },
            ),
          ),
          
          // Card counter display
          Container(
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
          
          // Navigation controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _previousCard : null,
                  icon: const Icon(Icons.arrow_back_ios),
                  iconSize: 32,
                ),
                IconButton(
                  onPressed: _onFlip,
                  icon: Icon(_isFlipped ? Icons.visibility_off : Icons.visibility),
                  iconSize: 32,
                ),
                IconButton(
                  onPressed: _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                  iconSize: 32,
                ),
              ],
            ),
          ),
          
          // Difficulty rating (only show when flipped)
          if (_isFlipped)
            Container(
              padding: const EdgeInsets.all(16),
              child: DifficultyRatingBar(
                onRatingSelected: _onDifficultyRated,
                selectedRating: _ratings[_currentIndex],
              ),
            ),
        ],
      ),
    );
  }
}