import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/flashcard.dart';
import '../animations/animation_manager.dart';
import '../animations/animation_config.dart';
import '../widgets/difficulty_rating_bar.dart';
class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;
  final bool isFlipped;
  final VoidCallback onFlip;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Function(Difficulty)? onDifficultyRated;
  final bool enableSwipeGestures;
  final bool showDifficultyRating;
  const FlashcardWidget({
    super.key,
    required this.flashcard,
    required this.isFlipped,
    required this.onFlip,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onDifficultyRated,
    this.enableSwipeGestures = true,
    this.showDifficultyRating = true,
  });
  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}
class _FlashcardWidgetState extends State<FlashcardWidget>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _swipeController;
  late AnimationController _difficultyController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _difficultyAnimation;
  final AnimationManager _animationManager = AnimationManager();
  String? _flipAnimationId;
  String? _swipeAnimationId;
  String? _difficultyAnimationId;
  double _swipeStartX = 0.0;
  double _currentSwipeOffset = 0.0;
  bool _isSwipeActive = false;
  bool _hasSwipeThreshold = false;
  Difficulty? _selectedDifficulty;
  bool _showDifficultyRating = false;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _difficultyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInOut,
    ));
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeInOut,
    ));
    _difficultyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _difficultyController,
      curve: Curves.elasticOut,
    ));
    _registerAnimations();
    _swipeController.addStatusListener(_handleSwipeStatus);
    _flipController.addStatusListener(_handleFlipStatus);
  }
  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      _flipAnimationId = _animationManager.registerController(
        controller: _flipController,
        config: AnimationConfigs.flashcardFlip.copyWith(
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 600),
        ),
        category: AnimationCategory.gesture,
      );
      _swipeAnimationId = _animationManager.registerController(
        controller: _swipeController,
        config: AnimationConfigs.flashcardSwipe.copyWith(
          duration: const Duration(milliseconds: 400),
        ),
        category: AnimationCategory.gesture,
      );
      _difficultyAnimationId = _animationManager.registerController(
        controller: _difficultyController,
        config: AnimationConfigs.difficultyRating.copyWith(
          curve: Curves.elasticOut,
        ),
        category: AnimationCategory.microInteraction,
      );
    }
  }
  @override
  void didUpdateWidget(FlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      HapticFeedback.lightImpact();
      if (widget.isFlipped) {
        _flipController.forward();
        if (widget.showDifficultyRating) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              setState(() {
                _showDifficultyRating = true;
              });
              _difficultyController.forward();
            }
          });
        }
      } else {
        _flipController.reverse();
        _hideDifficultyRating();
      }
    }
  }
  @override
  void dispose() {
    if (_flipAnimationId != null) {
      _animationManager.disposeController(_flipAnimationId!);
    }
    if (_swipeAnimationId != null) {
      _animationManager.disposeController(_swipeAnimationId!);
    }
    if (_difficultyAnimationId != null) {
      _animationManager.disposeController(_difficultyAnimationId!);
    }
    _flipController.dispose();
    _swipeController.dispose();
    _difficultyController.dispose();
    super.dispose();
  }
  void _handleSwipeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_currentSwipeOffset > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
      _resetSwipeState();
    }
  }
  void _handleFlipStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.isFlipped) {
      HapticFeedback.selectionClick();
    }
  }
  void _handlePanStart(DragStartDetails details) {
    if (!widget.enableSwipeGestures) return;
    _swipeStartX = details.globalPosition.dx;
    _isSwipeActive = true;
    _hasSwipeThreshold = false;
  }
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipeGestures || !_isSwipeActive) return;
    final deltaX = details.globalPosition.dx - _swipeStartX;
    final screenWidth = MediaQuery.of(context).size.width;
    final normalizedOffset = deltaX / screenWidth;
    setState(() {
      _currentSwipeOffset = normalizedOffset.clamp(-1.0, 1.0);
    });
    final progress = math.min(1.0, _currentSwipeOffset.abs() * 2);
    _swipeController.value = progress;
    if (!_hasSwipeThreshold && _currentSwipeOffset.abs() > 0.3) {
      _hasSwipeThreshold = true;
      HapticFeedback.mediumImpact();
    }
  }
  void _handlePanEnd(DragEndDetails details) {
    if (!widget.enableSwipeGestures || !_isSwipeActive) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipe = _currentSwipeOffset.abs() > 0.3 || velocity.abs() > 500;
    if (shouldSwipe) {
      _swipeController.forward();
    } else {
      _resetSwipeState();
    }
    _isSwipeActive = false;
  }
  void _resetSwipeState() {
    setState(() {
      _currentSwipeOffset = 0.0;
    });
    _swipeController.reset();
  }
  void _handleDifficultySelected(Difficulty difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });
    HapticFeedback.lightImpact();
    _difficultyController.forward().then((_) {
      _difficultyController.reverse();
    });
    widget.onDifficultyRated?.call(difficulty);
    Future.delayed(const Duration(milliseconds: 500), () {
      _hideDifficultyRating();
    });
  }
  void _hideDifficultyRating() {
    if (_showDifficultyRating) {
      setState(() {
        _showDifficultyRating = false;
      });
      _difficultyController.reset();
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFlip,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _flipAnimation,
          _swipeAnimation,
          _scaleAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          return Transform.translate(
            offset: Offset(
              _currentSwipeOffset * MediaQuery.of(context).size.width * 0.8,
              0,
            ),
            child: Transform.scale(
              scale: 1.0 - (_currentSwipeOffset.abs() * 0.05),
              child: Transform.rotate(
                angle: _currentSwipeOffset * 0.1,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnimation.value * math.pi),
                  child: isShowingFront
                      ? _buildFrontCard(context)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: _buildBackCard(context),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildFrontCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.flashcard.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.help_outline,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              widget.flashcard.question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to reveal answer',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (widget.enableSwipeGestures) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Swipe to navigate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildBackCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withValues(alpha: 0.1),
              Colors.green.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.flashcard.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              widget.flashcard.answer,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip(
                  'Reviews',
                  widget.flashcard.reviewCount.toString(),
                  Icons.repeat,
                ),
                _buildStatChip(
                  'Difficulty',
                  widget.flashcard.difficulty.displayName,
                  Icons.trending_up,
                ),
              ],
            ),
            if (_showDifficultyRating && widget.showDifficultyRating) ...[
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _difficultyAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _difficultyAnimation.value,
                    child: Opacity(
                      opacity: _difficultyAnimation.value,
                      child: DifficultyRatingBar(
                        onRatingSelected: _handleDifficultySelected,
                        selectedRating: _selectedDifficulty ?? widget.flashcard.difficulty,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}