import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scholar_lens/models/uploaded_textbook.dart';
import 'package:scholar_lens/models/chapter_reading_state.dart';
import 'package:scholar_lens/models/chapter_section.dart';
import 'package:scholar_lens/models/text_highlight.dart';
import 'package:scholar_lens/models/section_bookmark.dart';
import 'package:scholar_lens/providers/progress_provider.dart';
import 'package:scholar_lens/services/progress_service.dart';
import 'package:scholar_lens/services/tutor_service.dart';
import 'package:scholar_lens/services/flashcard_service.dart';

/// Main screen for reading textbook chapters with integrated study tools
class ChapterReadingScreen extends StatefulWidget {
  final UploadedTextbook textbook;
  final int chapterNumber;
  final ChapterProgress? initialProgress;

  const ChapterReadingScreen({
    super.key,
    required this.textbook,
    required this.chapterNumber,
    this.initialProgress,
  });

  @override
  State<ChapterReadingScreen> createState() => _ChapterReadingScreenState();
}

class _ChapterReadingScreenState extends State<ChapterReadingScreen>
    with TickerProviderStateMixin, RestorationMixin {
  
  // State management
  late ChapterReadingState _readingState;
  
  // Services
  late ProgressService _progressService;
  late TutorService _tutorService;
  late FlashcardService _flashcardService;
  
  // Controllers for animations and scrolling
  late AnimationController _fadeController;
  late ScrollController _scrollController;
  
  // Reading session tracking
  DateTime? _sessionStartTime;
  DateTime? _lastProgressUpdate;
  
  // Restoration
  final RestorableString _restorationId = RestorableString('');
  
  @override
  String? get restorationId => _restorationId.value;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
    _loadInitialState();
    _setupLifecycleListeners();
  }

  void _setupLifecycleListeners() {
    // Listen to app lifecycle changes for background saving
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(
      onPaused: _handleAppPaused,
      onResumed: _handleAppResumed,
    ));
  }

  void _handleAppPaused() {
    // Save state when app goes to background
    _saveState();
  }

  void _handleAppResumed() {
    // Update session start time when app resumes
    _sessionStartTime = DateTime.now();
  }
  void _initializeServices() {
    _progressService = ProgressService();
    _tutorService = TutorService();
    _flashcardService = FlashcardService();
  }

  void _initializeControllers() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scrollController = ScrollController();
    
    // Set up restoration ID
    _restorationId.value = 'chapter_reading_${widget.textbook.id}_${widget.chapterNumber}';
  }

  void _loadInitialState() {
    // Start reading session tracking
    _sessionStartTime = DateTime.now();
    _lastProgressUpdate = DateTime.now();
    
    // Create initial state with mock data for now
    // In a real implementation, this would load from storage or API
    final mockSections = _createMockSections();
    
    _readingState = ChapterReadingState.initial(
      textbookId: widget.textbook.id,
      chapterNumber: widget.chapterNumber,
      sections: mockSections,
      keyPoints: _createMockKeyPoints(),
    );
    
    // Load any existing progress
    _loadExistingProgress();
    
    // Start fade-in animation
    _fadeController.forward();
  }

  Future<void> _loadExistingProgress() async {
    try {
      // Load saved highlights
      final savedHighlights = await _loadSavedHighlights();
      
      // Load saved bookmarks
      final savedBookmarks = await _loadSavedBookmarks();
      
      // Load reading progress
      final savedProgress = await _progressService.getChapterProgress(
        widget.textbook.id,
        widget.chapterNumber,
      );
      
      // Update state with loaded data
      if (savedHighlights.isNotEmpty || savedBookmarks.isNotEmpty || savedProgress != null) {
        setState(() {
          _readingState = _readingState.copyWith(
            highlights: savedHighlights,
            bookmarks: savedBookmarks,
            readingProgress: savedProgress ?? _readingState.readingProgress,
          );
        });
      }
    } catch (e) {
      // Handle loading errors gracefully
      debugPrint('Error loading existing progress: $e');
    }
  }

  Future<List<TextHighlight>> _loadSavedHighlights() async {
    // In a real implementation, this would load from local storage
    // For now, return empty list
    return [];
  }

  Future<List<SectionBookmark>> _loadSavedBookmarks() async {
    // In a real implementation, this would load from local storage
    // For now, return empty list
    return [];
  }

  List<ChapterSection> _createMockSections() {
    // Mock data - in real implementation, this would come from the textbook content
    return [
      ChapterSection(
        sectionNumber: 1,
        title: 'Introduction',
        content: 'This is the introduction section content...',
        keyTerms: ['term1', 'term2'],
        isCompleted: false,
      ),
      ChapterSection(
        sectionNumber: 2,
        title: 'Main Concepts',
        content: 'This section covers the main concepts...',
        keyTerms: ['concept1', 'concept2'],
        isCompleted: false,
      ),
      ChapterSection(
        sectionNumber: 3,
        title: 'Summary',
        content: 'This section summarizes the chapter...',
        keyTerms: ['summary', 'conclusion'],
        isCompleted: false,
      ),
    ];
  }
  List<String> _createMockKeyPoints() {
    return [
      'Understand the fundamental concepts',
      'Learn the key terminology',
      'Apply the concepts to real-world scenarios',
      'Analyze the implications and consequences',
    ];
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorationId, 'restoration_id');
    
    // Restore reading state from storage
    if (!initialRestore) {
      _restoreReadingState();
    }
  }

  Future<void> _restoreReadingState() async {
    try {
      // Load saved state from local storage using restoration key
      final restorationKey = _readingState.restorationKey;
      
      // In a real implementation, this would load from SharedPreferences or similar
      // For now, just load the existing progress
      await _loadExistingProgress();
      
    } catch (e) {
      debugPrint('Error restoring reading state: $e');
    }
  }

  void _saveState() {
    // Save current state to local storage
    _saveReadingProgress();
    _saveHighlights();
    _saveBookmarks();
  }

  Future<void> _saveReadingProgress() async {
    try {
      // Save to progress service
      await _progressService.saveChapterProgress(
        widget.textbook.id,
        widget.chapterNumber,
        _readingState.readingProgress,
      );
      
      // Update reading time
      if (_sessionStartTime != null) {
        final sessionDuration = DateTime.now().difference(_sessionStartTime!);
        final updatedState = _readingState.updateReadingTime(sessionDuration);
        
        // Save complete state to local storage for restoration
        await _saveCompleteState(updatedState);
        
        setState(() {
          _readingState = updatedState;
        });
      }
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
      // Queue for retry
      _queueProgressSave();
    }
  }

  Future<void> _saveCompleteState(ChapterReadingState state) async {
    try {
      // In a real implementation, save to SharedPreferences or secure storage
      final stateJson = state.serialize();
      final key = state.restorationKey;
      
      // Save serialized state
      // await SharedPreferences.getInstance().then((prefs) => 
      //   prefs.setString(key, stateJson));
      
    } catch (e) {
      debugPrint('Error saving complete state: $e');
    }
  }

  void _queueProgressSave() {
    // Implement retry mechanism for failed saves
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _saveReadingProgress();
      }
    });
  }

  Future<void> _saveHighlights() async {
    try {
      // Save highlights with retry mechanism
      for (final highlight in _readingState.highlights) {
        await _saveHighlightWithRetry(highlight);
      }
    } catch (e) {
      debugPrint('Error saving highlights: $e');
    }
  }

  Future<void> _saveHighlightWithRetry(TextHighlight highlight, {int retryCount = 0}) async {
    try {
      // In a real implementation, save to local storage
      // await _highlightStorage.save(highlight);
    } catch (e) {
      if (retryCount < 3) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        await _saveHighlightWithRetry(highlight, retryCount: retryCount + 1);
      } else {
        debugPrint('Failed to save highlight after 3 retries: ${highlight.id}');
      }
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      // Save bookmarks with retry mechanism
      for (final bookmark in _readingState.bookmarks) {
        await _saveBookmarkWithRetry(bookmark);
      }
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> _saveBookmarkWithRetry(SectionBookmark bookmark, {int retryCount = 0}) async {
    try {
      // In a real implementation, save to local storage
      // await _bookmarkStorage.save(bookmark);
    } catch (e) {
      if (retryCount < 3) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        await _saveBookmarkWithRetry(bookmark, retryCount: retryCount + 1);
      } else {
        debugPrint('Failed to save bookmark after 3 retries: ${bookmark.id}');
      }
    }
  }

  void _handleBackNavigation() {
    _saveState();
    Navigator.of(context).pop();
  }

  void _updateReadingState(ChapterReadingState newState) {
    setState(() {
      _readingState = newState;
    });
    
    // Update progress provider
    context.read<ProgressProvider>().updateChapterProgress(
      widget.textbook.id,
      widget.chapterNumber,
      newState.readingProgress,
    );
    
    // Auto-save progress periodically
    _autoSaveProgress();
  }

  void _autoSaveProgress() {
    final now = DateTime.now();
    if (_lastProgressUpdate == null || 
        now.difference(_lastProgressUpdate!).inMinutes >= 1) {
      _lastProgressUpdate = now;
      _saveReadingProgress();
    }
  }

  // Highlight management methods
  void _addHighlight(String selectedText, int startOffset, int endOffset) {
    final currentSection = _readingState.currentSection;
    if (currentSection == null) return;

    final highlight = TextHighlight.create(
      textbookId: widget.textbook.id,
      chapterNumber: widget.chapterNumber,
      sectionNumber: currentSection.sectionNumber,
      highlightedText: selectedText,
      startOffset: startOffset,
      endOffset: endOffset,
    );

    final updatedState = _readingState.addHighlight(highlight);
    _updateReadingState(updatedState);
  }

  void _removeHighlight(String highlightId) {
    final updatedState = _readingState.removeHighlight(highlightId);
    _updateReadingState(updatedState);
  }

  // Bookmark management methods
  void _addBookmark({String note = ''}) {
    final currentSection = _readingState.currentSection;
    if (currentSection == null) return;

    final bookmark = SectionBookmark.create(
      textbookId: widget.textbook.id,
      chapterNumber: widget.chapterNumber,
      sectionNumber: currentSection.sectionNumber,
      sectionTitle: currentSection.title,
      note: note,
    );

    final updatedState = _readingState.addBookmark(bookmark);
    _updateReadingState(updatedState);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Section bookmarked!')),
    );
  }

  void _removeBookmark(String bookmarkId) {
    final updatedState = _readingState.removeBookmark(bookmarkId);
    _updateReadingState(updatedState);
  }

  // AI Tutor integration
  Future<void> _openAITutor() async {
    try {
      final currentSection = _readingState.currentSection;
      if (currentSection == null) return;

      // Navigate to tutor with context
      await Navigator.pushNamed(
        context,
        '/tutor',
        arguments: {
          'textbook': widget.textbook,
          'chapter': widget.chapterNumber,
          'section': currentSection,
          'context': currentSection.content,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Tutor is temporarily unavailable')),
      );
    }
  }

  // Study tools integration
  Future<void> _createFlashcards() async {
    try {
      await Navigator.pushNamed(
        context,
        '/create-flashcards',
        arguments: {
          'textbook': widget.textbook,
          'chapter': widget.chapterNumber,
          'sections': _readingState.sections,
          'highlights': _readingState.highlights,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create flashcards')),
      );
    }
  }

  Future<void> _startQuiz() async {
    try {
      await Navigator.pushNamed(
        context,
        '/quiz',
        arguments: {
          'textbook': widget.textbook,
          'chapter': widget.chapterNumber,
          'sections': _readingState.sections,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start quiz')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              // Header with navigation and progress
              _buildHeader(),
              
              // Main content area
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back navigation
          Row(
            children: [
              IconButton(
                onPressed: _handleBackNavigation,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to ${widget.textbook.title}',
              ),
              Expanded(
                child: Text(
                  'Back to ${widget.textbook.title}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Chapter title and completion status
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chapter ${widget.chapterNumber}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_readingState.isChapterCompleted)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          _buildProgressBar(),
        ],
      ),
    );
  }
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress: ${_readingState.progressPercentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Reading time: ${_readingState.formattedReadingTime}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _readingState.readingProgress,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Study tools bar placeholder
          _buildStudyToolsPlaceholder(),
          
          const SizedBox(height: 16),
          
          // Key points section placeholder
          _buildKeyPointsPlaceholder(),
          
          const SizedBox(height: 16),
          
          // Content display placeholder
          _buildContentPlaceholder(),
          
          const SizedBox(height: 16),
          
          // Section navigator placeholder
          _buildSectionNavigatorPlaceholder(),
          
          const SizedBox(height: 16),
          
          // Study action buttons placeholder
          _buildStudyActionButtonsPlaceholder(),
        ],
      ),
    );
  }
  Widget _buildStudyToolsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: Icons.highlight_alt,
            label: 'Highlight',
            isActive: _readingState.isHighlightMode,
            onPressed: () {
              _updateReadingState(_readingState.toggleHighlightMode());
            },
          ),
          _buildToolButton(
            icon: Icons.bookmark_add,
            label: 'Bookmark',
            onPressed: _addBookmark,
          ),
          _buildToolButton(
            icon: Icons.psychology,
            label: 'Ask AI',
            onPressed: _openAITutor,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: isActive 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : null,
            foregroundColor: isActive 
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  Widget _buildKeyPointsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Learning Points',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_readingState.keyPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildContentPlaceholder() {
    final currentSection = _readingState.currentSection;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Section ${_readingState.currentSectionIndex + 1} of ${_readingState.totalSections}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (currentSection != null) ...[
            Text(
              currentSection.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentSection.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ] else
            Text(
              'No content available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildSectionNavigatorPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _readingState.hasPreviousSection
                    ? () {
                        final newState = _readingState.updateCurrentSection(
                          _readingState.currentSectionIndex - 1,
                        );
                        _updateReadingState(newState);
                      }
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              Text(
                'Section ${_readingState.currentSectionIndex + 1}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton.icon(
                onPressed: _readingState.hasNextSection
                    ? () {
                        final newState = _readingState.updateCurrentSection(
                          _readingState.currentSectionIndex + 1,
                        );
                        _updateReadingState(newState);
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // TODO: Show all sections overview
            },
            child: const Text('All Sections'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyActionButtonsPlaceholder() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _createFlashcards,
            icon: const Icon(Icons.quiz),
            label: const Text('Create Flashcards'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startQuiz,
            icon: const Icon(Icons.assignment),
            label: const Text('Quiz Me'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
  @override
  void dispose() {
    // Final save before disposal
    _saveState();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(
      onPaused: _handleAppPaused,
      onResumed: _handleAppResumed,
    ));
    
    // Dispose controllers
    _fadeController.dispose();
    _scrollController.dispose();
    _restorationId.dispose();
    
    super.dispose();
  }
}