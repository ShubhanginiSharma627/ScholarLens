import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/flashcard.dart';
import '../widgets/flashcard_widget.dart';
import 'animation_manager.dart';
import 'animation_config.dart';
class AnimatedFlashcardDeck extends StatefulWidget {
  final List<Flashcard> flashcards;
  final int currentIndex;
  final bool isLoading;
  final bool showCelebration;
  final VoidCallback? onFlip;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Function(Difficulty)? onDifficultyRated;
  final VoidCallback? onCelebrationComplete;
  final Duration staggerDelay;
  final Duration cardDuration;
  const AnimatedFlashcardDeck({
    super.key,
    required this.flashcards,
    this.currentIndex = 0,
    this.isLoading = false,
    this.showCelebration = false,
    this.onFlip,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onDifficultyRated,
    this.onCelebrationComplete,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.cardDuration = const Duration(milliseconds: 400),
  });
  @override
  State<AnimatedFlashcardDeck> createState() => _AnimatedFlashcardDeckState();
}
class _AnimatedFlashcardDeckState extends State<AnimatedFlashcardDeck>
    with TickerProviderStateMixin {
  final AnimationManager _animationManager = AnimationManager();
  late AnimationController _loadingController;
  late AnimationController _celebrationController;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];
  final List<Animation<Offset>> _cardSlideAnimations = [];
  String? _loadingAnimationId;
  String? _celebrationAnimationId;
  final List<String> _cardAnimationIds = [];
  bool _hasStartedLoading = false;
  bool _hasStartedCelebration = false;
  @override
  void initState() {
    super.initState();
    _animationManager.initialize();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _initializeCardAnimations();
    _registerAnimations();
    _celebrationController.addStatusListener(_handleCelebrationStatus);
    if (widget.isLoading) {
      _startLoadingAnimation();
    }
  }
  void _initializeCardAnimations() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    _cardControllers.clear();
    _cardAnimations.clear();
    _cardSlideAnimations.clear();
    for (int i = 0; i < widget.flashcards.length; i++) {
      final controller = AnimationController(
        duration: widget.cardDuration,
        vsync: this,
      );
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
      _cardControllers.add(controller);
      _cardAnimations.add(fadeAnimation);
      _cardSlideAnimations.add(slideAnimation);
    }
  }
  void _registerAnimations() {
    if (_animationManager.isInitialized) {
      _loadingAnimationId = _animationManager.registerController(
        controller: _loadingController,
        config: AnimationConfigs.loadingSpinner.copyWith(
          duration: const Duration(milliseconds: 800),
        ),
        category: AnimationCategory.feedback,
      );
      _celebrationAnimationId = _animationManager.registerController(
        controller: _celebrationController,
        config: AnimationConfigs.celebration,
        category: AnimationCategory.feedback,
      );
      for (int i = 0; i < _cardControllers.length; i++) {
        final animationId = _animationManager.registerController(
          controller: _cardControllers[i],
          config: AnimationConfigs.cardAppear.copyWith(
            duration: widget.cardDuration,
          ),
          category: AnimationCategory.content,
        );
        _cardAnimationIds.add(animationId);
      }
    }
  }
  @override
  void didUpdateWidget(AnimatedFlashcardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startLoadingAnimation();
      } else {
        _stopLoadingAnimation();
      }
    }
    if (widget.showCelebration != oldWidget.showCelebration) {
      if (widget.showCelebration) {
        _startCelebrationAnimation();
      } else {
        _stopCelebrationAnimation();
      }
    }
    if (widget.flashcards.length != oldWidget.flashcards.length) {
      _initializeCardAnimations();
      _registerAnimations();
    }
  }
  @override
  void dispose() {
    if (_loadingAnimationId != null) {
      _animationManager.disposeController(_loadingAnimationId!);
    }
    if (_celebrationAnimationId != null) {
      _animationManager.disposeController(_celebrationAnimationId!);
    }
    for (final animationId in _cardAnimationIds) {
      _animationManager.disposeController(animationId);
    }
    _loadingController.dispose();
    _celebrationController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  void _startLoadingAnimation() {
    if (_hasStartedLoading) return;
    _hasStartedLoading = true;
    _loadingController.repeat();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !widget.isLoading) {
        _startStaggeredCardAnimation();
      }
    });
  }
  void _stopLoadingAnimation() {
    _loadingController.stop();
    _startStaggeredCardAnimation();
  }
  void _startStaggeredCardAnimation() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }
  void _startCelebrationAnimation() {
    if (_hasStartedCelebration) return;
    _hasStartedCelebration = true;
    HapticFeedback.heavyImpact();
    _celebrationController.forward();
  }
  void _stopCelebrationAnimation() {
    _celebrationController.reset();
    _hasStartedCelebration = false;
  }
  void _handleCelebrationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCelebrationComplete?.call();
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }
    if (widget.showCelebration) {
      return _buildCelebrationState();
    }
    return _buildDeckState();
  }
  Widget _buildLoadingState() {
    return Center(
      child: AnimatedBuilder(
        animation: _loadingController,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: _loadingController.value * 2 * math.pi,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading flashcards...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildCelebrationState() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: _celebrationController.value * 2,
                  colors: [
                    Colors.amber.withValues(alpha: 0.3 * _celebrationController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.0 + (_celebrationController.value * 0.5),
                    child: Transform.rotate(
                      angle: _celebrationController.value * math.pi * 0.5,
                      child: Icon(
                        Icons.celebration,
                        size: 80,
                        color: Colors.amber[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _celebrationController,
                        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Congratulations!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You completed the flashcard session!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ..._buildParticleEffects(),
          ],
        );
      },
    );
  }
  List<Widget> _buildParticleEffects() {
    final particles = <Widget>[];
    const particleCount = 20;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = 100 + (i % 3) * 50;
      particles.add(
        AnimatedBuilder(
          animation: _celebrationController,
          builder: (context, child) {
            final progress = _celebrationController.value;
            final x = math.cos(angle) * distance * progress;
            final y = math.sin(angle) * distance * progress;
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + x,
              top: MediaQuery.of(context).size.height / 2 + y,
              child: Opacity(
                opacity: (1.0 - progress).clamp(0.0, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? Colors.amber : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return particles;
  }
  Widget _buildDeckState() {
    if (widget.flashcards.isEmpty) {
      return const Center(
        child: Text('No flashcards available'),
      );
    }
    return Stack(
      children: [
        for (int i = math.max(0, widget.currentIndex - 2); 
             i < math.min(widget.flashcards.length, widget.currentIndex + 3); 
             i++)
          if (i != widget.currentIndex)
            _buildBackgroundCard(i),
        if (widget.currentIndex < widget.flashcards.length)
          _buildCurrentCard(),
      ],
    );
  }
  Widget _buildBackgroundCard(int index) {
    if (index >= _cardAnimations.length) return const SizedBox.shrink();
    final offset = (index - widget.currentIndex).toDouble();
    final scale = 1.0 - (offset.abs() * 0.05);
    final opacity = 1.0 - (offset.abs() * 0.3);
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: opacity,
          ).animate(_cardAnimations[index]),
          child: SlideTransition(
            position: _cardSlideAnimations[index],
            child: Transform.scale(
              scale: scale * _cardAnimations[index].value,
              child: Transform.translate(
                offset: Offset(offset * 20, offset.abs() * 10),
                child: Opacity(
                  opacity: 0.7,
                  child: FlashcardWidget(
                    flashcard: widget.flashcards[index],
                    isFlipped: false,
                    onFlip: () {},
                    enableSwipeGestures: false,
                    showDifficultyRating: false,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildCurrentCard() {
    final index = widget.currentIndex;
    if (index >= _cardAnimations.length) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        return FadeTransition(
          opacity: _cardAnimations[index],
          child: SlideTransition(
            position: _cardSlideAnimations[index],
            child: FlashcardWidget(
              flashcard: widget.flashcards[index],
              isFlipped: false, // This should be managed by parent
              onFlip: widget.onFlip ?? () {}, // Provide empty callback if null
              onSwipeLeft: widget.onSwipeLeft,
              onSwipeRight: widget.onSwipeRight,
              onDifficultyRated: widget.onDifficultyRated,
            ),
          ),
        );
      },
    );
  }
}
extension FlashcardDeckAnimationExtensions on List<Flashcard> {
  Widget asAnimatedDeck({
    int currentIndex = 0,
    bool isLoading = false,
    bool showCelebration = false,
    VoidCallback? onFlip,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    Function(Difficulty)? onDifficultyRated,
    VoidCallback? onCelebrationComplete,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration cardDuration = const Duration(milliseconds: 400),
  }) {
    return AnimatedFlashcardDeck(
      flashcards: this,
      currentIndex: currentIndex,
      isLoading: isLoading,
      showCelebration: showCelebration,
      onFlip: onFlip,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      onDifficultyRated: onDifficultyRated,
      onCelebrationComplete: onCelebrationComplete,
      staggerDelay: staggerDelay,
      cardDuration: cardDuration,
    );
  }
}
class FlashcardDeckAnimationConfigs {
  static const Duration fastStagger = Duration(milliseconds: 50);
  static const Duration fastCard = Duration(milliseconds: 200);
  static const Duration standardStagger = Duration(milliseconds: 100);
  static const Duration standardCard = Duration(milliseconds: 400);
  static const Duration slowStagger = Duration(milliseconds: 200);
  static const Duration slowCard = Duration(milliseconds: 600);
  static Widget fast(
    List<Flashcard> flashcards, {
    int currentIndex = 0,
    bool isLoading = false,
    bool showCelebration = false,
    VoidCallback? onFlip,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    Function(Difficulty)? onDifficultyRated,
    VoidCallback? onCelebrationComplete,
  }) {
    return flashcards.asAnimatedDeck(
      currentIndex: currentIndex,
      isLoading: isLoading,
      showCelebration: showCelebration,
      onFlip: onFlip,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      onDifficultyRated: onDifficultyRated,
      onCelebrationComplete: onCelebrationComplete,
      staggerDelay: fastStagger,
      cardDuration: fastCard,
    );
  }
  static Widget standard(
    List<Flashcard> flashcards, {
    int currentIndex = 0,
    bool isLoading = false,
    bool showCelebration = false,
    VoidCallback? onFlip,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    Function(Difficulty)? onDifficultyRated,
    VoidCallback? onCelebrationComplete,
  }) {
    return flashcards.asAnimatedDeck(
      currentIndex: currentIndex,
      isLoading: isLoading,
      showCelebration: showCelebration,
      onFlip: onFlip,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      onDifficultyRated: onDifficultyRated,
      onCelebrationComplete: onCelebrationComplete,
      staggerDelay: standardStagger,
      cardDuration: standardCard,
    );
  }
  static Widget dramatic(
    List<Flashcard> flashcards, {
    int currentIndex = 0,
    bool isLoading = false,
    bool showCelebration = false,
    VoidCallback? onFlip,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    Function(Difficulty)? onDifficultyRated,
    VoidCallback? onCelebrationComplete,
  }) {
    return flashcards.asAnimatedDeck(
      currentIndex: currentIndex,
      isLoading: isLoading,
      showCelebration: showCelebration,
      onFlip: onFlip,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      onDifficultyRated: onDifficultyRated,
      onCelebrationComplete: onCelebrationComplete,
      staggerDelay: slowStagger,
      cardDuration: slowCard,
    );
  }
}