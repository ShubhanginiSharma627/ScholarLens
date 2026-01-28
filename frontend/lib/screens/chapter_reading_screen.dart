import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:scholar_lens/widgets/chapter_reading_header.dart';
import 'package:scholar_lens/widgets/study_tools_bar.dart';
import 'package:scholar_lens/widgets/content_display_area.dart';
import 'package:scholar_lens/widgets/study_action_buttons.dart';
import 'package:scholar_lens/utils/focus_management_utils.dart';
import 'package:scholar_lens/utils/accessibility_utils.dart';
import 'package:scholar_lens/animations/animations.dart';

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
    with TickerProviderStateMixin, RestorationMixin, FocusManagementMixin {
  
  // State management
  late ChapterReadingState _readingState;
  late _AppLifecycleObserver _lifecycleObserver;
  
  // Services
  late ProgressService _progressService;
  late TutorService _tutorService;
  late FlashcardService _flashcardService;
  
  // Controllers for animations and scrolling
  late AnimationController _fadeController;
  late ScrollController _scrollController;
  
  // Focus management
  late FocusNode _headerFocusNode;
  late FocusNode _toolsBarFocusNode;
  late FocusNode _contentFocusNode;
  late FocusNode _navigationFocusNode;
  late FocusNode _actionButtonsFocusNode;
  
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
    // Create lifecycle observer
    _lifecycleObserver = _AppLifecycleObserver(
      onPaused: _handleAppPaused,
      onResumed: _handleAppResumed,
    );
    
    // Listen to app lifecycle changes for background saving
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
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
    _tutorService = TutorServiceFactory.createProduction(); // Use factory to create concrete implementation
    _flashcardService = FlashcardService();
  }

  void _initializeControllers() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scrollController = ScrollController();
    
    // Initialize focus nodes
    _headerFocusNode = createFocusNode(debugLabel: 'Chapter Header');
    _toolsBarFocusNode = createFocusNode(debugLabel: 'Study Tools Bar');
    _contentFocusNode = createFocusNode(debugLabel: 'Content Display');
    _navigationFocusNode = createFocusNode(debugLabel: 'Section Navigation');
    _actionButtonsFocusNode = createFocusNode(debugLabel: 'Action Buttons');
    
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
    await _loadExistingProgressWithRetry();
  }

  Future<void> _loadExistingProgressWithRetry({int retryCount = 0}) async {
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
      debugPrint('Error loading existing progress (attempt ${retryCount + 1}): $e');
      
      if (retryCount < 2) {
        // Retry with exponential backoff
        final delaySeconds = (1 << retryCount);
        await Future.delayed(Duration(seconds: delaySeconds));
        
        if (mounted) {
          await _loadExistingProgressWithRetry(retryCount: retryCount + 1);
        }
      } else {
        // After 2 failed attempts, show error but continue with default state
        _handleContentLoadingError('Failed to load saved progress', e);
      }
    }
  }

  void _handleContentLoadingError(String message, dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message. Starting with a fresh session.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadExistingProgress(),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<List<TextHighlight>> _loadSavedHighlights() async {
    try {
      // In a real implementation, this would load from local storage
      // For now, return empty list
      return [];
    } catch (e) {
      debugPrint('Error loading saved highlights: $e');
      // Return empty list on error to allow app to continue
      return [];
    }
  }

  Future<List<SectionBookmark>> _loadSavedBookmarks() async {
    try {
      // In a real implementation, this would load from local storage
      // For now, return empty list
      return [];
    } catch (e) {
      debugPrint('Error loading saved bookmarks: $e');
      // Return empty list on error to allow app to continue
      return [];
    }
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
    await _saveReadingProgressWithRetry();
  }

  Future<void> _saveReadingProgressWithRetry({int retryCount = 0}) async {
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
      
      // Clear any queued retry attempts on success
      _clearProgressSaveQueue();
      
    } catch (e) {
      debugPrint('Error saving reading progress (attempt ${retryCount + 1}): $e');
      
      if (retryCount < 3) {
        // Exponential backoff: wait 2^retryCount seconds
        final delaySeconds = (1 << retryCount);
        await Future.delayed(Duration(seconds: delaySeconds));
        
        if (mounted) {
          await _saveReadingProgressWithRetry(retryCount: retryCount + 1);
        }
      } else {
        // After 3 failed attempts, show user notification and queue for later retry
        _handleProgressSaveFailure(e);
        _queueProgressSave();
      }
    }
  }

  void _handleProgressSaveFailure(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to save reading progress. Your progress will be saved when connection is restored.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry Now',
            onPressed: () => _saveReadingProgress(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _clearProgressSaveQueue() {
    // Clear any pending retry timers
    // In a real implementation, you would cancel any pending timers here
  }

  Future<void> _saveCompleteState(ChapterReadingState state) async {
    await _saveCompleteStateWithRetry(state);
  }

  Future<void> _saveCompleteStateWithRetry(ChapterReadingState state, {int retryCount = 0}) async {
    try {
      // In a real implementation, save to SharedPreferences or secure storage
      final stateJson = state.serialize();
      final key = state.restorationKey;
      
      // Save serialized state
      // await SharedPreferences.getInstance().then((prefs) => 
      //   prefs.setString(key, stateJson));
      
    } catch (e) {
      debugPrint('Error saving complete state (attempt ${retryCount + 1}): $e');
      
      if (retryCount < 2) {
        // Retry with exponential backoff
        final delaySeconds = (1 << retryCount);
        await Future.delayed(Duration(seconds: delaySeconds));
        
        if (mounted) {
          await _saveCompleteStateWithRetry(state, retryCount: retryCount + 1);
        }
      } else {
        // After 2 failed attempts, log error but don't show user notification
        // (this is less critical than progress saving)
        debugPrint('Failed to save complete state after ${retryCount + 1} attempts: $e');
      }
    }
  }

  void _queueProgressSave() {
    // Implement retry mechanism for failed saves with exponential backoff
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _saveReadingProgress();
      }
    });
  }

  Future<void> _saveHighlights() async {
    try {
      // Save highlights with retry mechanism
      final saveResults = await Future.wait(
        _readingState.highlights.map((highlight) => _saveHighlightWithRetry(highlight)),
        eagerError: false,
      );
      
      // Check if any saves failed
      final failedCount = saveResults.where((result) => result == false).length;
      if (failedCount > 0) {
        _handleHighlightSaveFailure(failedCount);
      }
    } catch (e) {
      debugPrint('Error saving highlights: $e');
      _handleHighlightSaveFailure(_readingState.highlights.length);
    }
  }

  void _handleHighlightSaveFailure(int failedCount) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save $failedCount highlight${failedCount > 1 ? 's' : ''}. They will be retried automatically.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry Now',
            onPressed: () => _saveHighlights(),
          ),
        ),
      );
    }
  }

  Future<bool> _saveHighlightWithRetry(TextHighlight highlight, {int retryCount = 0}) async {
    try {
      // In a real implementation, save to local storage
      // await _highlightStorage.save(highlight);
      return true;
    } catch (e) {
      if (retryCount < 3) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return await _saveHighlightWithRetry(highlight, retryCount: retryCount + 1);
      } else {
        debugPrint('Failed to save highlight after 3 retries: ${highlight.id}');
        return false;
      }
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      // Save bookmarks with retry mechanism
      final saveResults = await Future.wait(
        _readingState.bookmarks.map((bookmark) => _saveBookmarkWithRetry(bookmark)),
        eagerError: false,
      );
      
      // Check if any saves failed
      final failedCount = saveResults.where((result) => result == false).length;
      if (failedCount > 0) {
        _handleBookmarkSaveFailure(failedCount);
      }
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
      _handleBookmarkSaveFailure(_readingState.bookmarks.length);
    }
  }

  void _handleBookmarkSaveFailure(int failedCount) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save $failedCount bookmark${failedCount > 1 ? 's' : ''}. They will be retried automatically.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry Now',
            onPressed: () => _saveBookmarks(),
          ),
        ),
      );
    }
  }

  Future<bool> _saveBookmarkWithRetry(SectionBookmark bookmark, {int retryCount = 0}) async {
    try {
      // In a real implementation, save to local storage
      // await _bookmarkStorage.save(bookmark);
      return true;
    } catch (e) {
      if (retryCount < 3) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return await _saveBookmarkWithRetry(bookmark, retryCount: retryCount + 1);
      } else {
        debugPrint('Failed to save bookmark after 3 retries: ${bookmark.id}');
        return false;
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

  /// Check if the current section is bookmarked
  bool _isCurrentSectionBookmarked() {
    final currentSection = _readingState.currentSection;
    if (currentSection == null) return false;
    
    return _readingState.bookmarks.any((bookmark) =>
        bookmark.sectionNumber == currentSection.sectionNumber);
  }

  /// Check if AI tutor service is available
  bool _isAITutorAvailable() {
    // In a real implementation, this would check service status
    // For now, assume it's available unless there's an error
    return true;
  }

  /// Enhanced AI tutor integration with chapter context
  Future<void> _openAITutor() async {
    await _openAITutorWithRetry();
  }

  Future<void> _openAITutorWithRetry({int retryCount = 0}) async {
    try {
      final currentSection = _readingState.currentSection;
      if (currentSection == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No section content available')),
        );
        return;
      }

      // Check service availability first
      final isAvailable = await _tutorService.isServiceAvailable();
      if (!isAvailable) {
        _handleAITutorUnavailable();
        return;
      }

      // Get current section highlights for additional context
      final sectionHighlights = _getSectionHighlights(currentSection.sectionNumber);
      final highlightTexts = sectionHighlights.map((h) => h.highlightedText).toList();

      // Navigate to tutor with comprehensive context
      await Navigator.pushNamed(
        context,
        '/tutor',
        arguments: {
          'textbook': widget.textbook,
          'textbook_title': widget.textbook.title,
          'chapter': widget.chapterNumber,
          'chapter_number': widget.chapterNumber,
          'section': currentSection,
          'section_title': currentSection.title,
          'section_content': currentSection.content,
          'context': currentSection.content,
          'highlights': highlightTexts,
          'key_points': _readingState.keyPoints,
          'reading_progress': _readingState.readingProgress,
          'mode': 'chapter_reading', // Indicate this is from chapter reading
        },
      );
    } catch (e) {
      debugPrint('Error opening AI tutor (attempt ${retryCount + 1}): $e');
      
      if (retryCount < 2) {
        // Retry with delay
        await Future.delayed(Duration(seconds: retryCount + 1));
        if (mounted) {
          await _openAITutorWithRetry(retryCount: retryCount + 1);
        }
      } else {
        _handleAITutorError(e);
      }
    }
  }

  void _handleAITutorUnavailable() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Tutor Unavailable'),
          content: const Text(
            'The AI Tutor service is temporarily unavailable. You can continue reading and try again later, or use the study tools to create flashcards and quizzes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Reading'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createFlashcards();
              },
              child: const Text('Create Flashcards'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openAITutor();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _handleAITutorError(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open AI Tutor: ${_getErrorMessage(error)}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _openAITutor,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Get highlights for a specific section
  List<TextHighlight> _getSectionHighlights(int sectionNumber) {
    return _readingState.highlights
        .where((highlight) => highlight.sectionNumber == sectionNumber)
        .toList();
  }

  /// Show options for a tapped highlight
  void _showHighlightOptions(TextHighlight highlight) {
    context.showEnhancedOptions<String>(
      title: 'Highlight Options',
      options: [
        BottomSheetOption<String>(
          title: 'Change Color',
          subtitle: 'Modify highlight color',
          icon: Icons.palette,
          value: 'change_color',
        ),
        BottomSheetOption<String>(
          title: 'Remove',
          subtitle: 'Delete this highlight',
          icon: Icons.delete,
          value: 'remove',
        ),
      ],
    ).then((result) {
      if (result == 'change_color') {
        _changeHighlightColor(highlight);
      } else if (result == 'remove') {
        _removeHighlight(highlight.id);
      }
    });
  }

  /// Show color picker for changing highlight color
  void _changeHighlightColor(TextHighlight highlight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Highlight Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HighlightColorType.values.map((colorType) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _updateHighlightColor(highlight, colorType.color);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorType.color,
                  shape: BoxShape.circle,
                  border: highlight.highlightColor == colorType.color
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : null,
                ),
                child: highlight.highlightColor == colorType.color
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Update highlight color
  void _updateHighlightColor(TextHighlight highlight, Color newColor) {
    final updatedHighlight = highlight.copyWith(highlightColor: newColor);
    final updatedState = _readingState.updateHighlight(updatedHighlight);
    _updateReadingState(updatedState);
  }

  // Study tools integration
  Future<void> _createFlashcards() async {
    await _createFlashcardsWithRetry();
  }

  Future<void> _createFlashcardsWithRetry({int retryCount = 0}) async {
    try {
      final currentSection = _readingState.currentSection;
      
      // Prepare comprehensive context for flashcard creation
      final flashcardContext = {
        'textbook': widget.textbook,
        'textbook_id': widget.textbook.id,
        'textbook_title': widget.textbook.title,
        'chapter': widget.chapterNumber,
        'chapter_number': widget.chapterNumber,
        'current_section': currentSection,
        'current_section_index': _readingState.currentSectionIndex,
        'sections': _readingState.sections,
        'highlights': _readingState.highlights,
        'bookmarks': _readingState.bookmarks,
        'key_points': _readingState.keyPoints,
        'reading_progress': _readingState.readingProgress,
        'mode': 'chapter_reading', // Indicate source context
        'session_data': {
          'reading_time': _readingState.readingTime,
          'completed_sections': _readingState.sections
              .where((section) => section.isCompleted)
              .map((section) => section.sectionNumber)
              .toList(),
        },
      };

      await Navigator.pushNamed(
        context,
        '/create-flashcards',
        arguments: flashcardContext,
      );
    } catch (e) {
      debugPrint('Error navigating to flashcard creation (attempt ${retryCount + 1}): $e');
      
      if (retryCount < 2) {
        // Retry with delay
        await Future.delayed(Duration(seconds: retryCount + 1));
        if (mounted) {
          await _createFlashcardsWithRetry(retryCount: retryCount + 1);
        }
      } else {
        _handleFlashcardServiceError(e);
      }
    }
  }

  void _handleFlashcardServiceError(dynamic error) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Flashcard Service Error'),
          content: Text(
            'Unable to create flashcards: ${_getErrorMessage(error)}\n\n'
            'You can continue reading and try again later, or use the quiz feature instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Reading'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startQuiz();
              },
              child: const Text('Try Quiz Instead'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createFlashcards();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _startQuiz() async {
    await _startQuizWithRetry();
  }

  Future<void> _startQuizWithRetry({int retryCount = 0}) async {
    try {
      final currentSection = _readingState.currentSection;
      
      // Prepare comprehensive context for quiz generation
      final quizContext = {
        'textbook': widget.textbook,
        'textbook_id': widget.textbook.id,
        'textbook_title': widget.textbook.title,
        'chapter': widget.chapterNumber,
        'chapter_number': widget.chapterNumber,
        'current_section': currentSection,
        'current_section_index': _readingState.currentSectionIndex,
        'sections': _readingState.sections,
        'highlights': _readingState.highlights,
        'bookmarks': _readingState.bookmarks,
        'key_points': _readingState.keyPoints,
        'reading_progress': _readingState.readingProgress,
        'mode': 'chapter_reading', // Indicate source context
        'quiz_scope': 'chapter', // Indicate quiz should cover entire chapter
        'session_data': {
          'reading_time': _readingState.readingTime,
          'completed_sections': _readingState.sections
              .where((section) => section.isCompleted)
              .map((section) => section.sectionNumber)
              .toList(),
          'highlighted_content': _readingState.highlights
              .map((highlight) => highlight.highlightedText)
              .toList(),
        },
      };

      await Navigator.pushNamed(
        context,
        '/quiz',
        arguments: quizContext,
      );
    } catch (e) {
      debugPrint('Error navigating to quiz (attempt ${retryCount + 1}): $e');
      
      if (retryCount < 2) {
        // Retry with delay
        await Future.delayed(Duration(seconds: retryCount + 1));
        if (mounted) {
          await _startQuizWithRetry(retryCount: retryCount + 1);
        }
      } else {
        _handleQuizServiceError(e);
      }
    }
  }

  void _handleQuizServiceError(dynamic error) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Service Error'),
          content: Text(
            'Unable to start quiz: ${_getErrorMessage(error)}\n\n'
            'You can continue reading and try again later, or use the flashcard feature instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Reading'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createFlashcards();
              },
              child: const Text('Try Flashcards Instead'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startQuiz();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  /// Helper method to extract user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();
      if (errorString.contains('SocketException') || errorString.contains('Network')) {
        return 'Network connection failed';
      } else if (errorString.contains('TimeoutException') || errorString.contains('timeout')) {
        return 'Request timed out';
      } else if (errorString.contains('FormatException')) {
        return 'Invalid response format';
      }
    }
    return 'An unexpected error occurred';
  }
  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.createAccessibleScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FocusManagementUtils.createKeyboardNavigationHandler(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.escape): () => _handleBackNavigation(),
          LogicalKeySet(LogicalKeyboardKey.keyH): () => _toggleHighlightMode(),
          LogicalKeySet(LogicalKeyboardKey.keyB): () => _addBookmark(),
          LogicalKeySet(LogicalKeyboardKey.keyA): () => _openAITutor(),
          LogicalKeySet(LogicalKeyboardKey.keyF): () => _createFlashcards(),
          LogicalKeySet(LogicalKeyboardKey.keyQ): () => _startQuiz(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): () => _navigateToPreviousSection(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): () => _navigateToNextSection(),
        },
        child: SafeArea(
          child: FocusManagementUtils.createFocusTraversalGroup(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  // Header with navigation and progress
                  FocusManagementUtils.createFocusOrder(
                    order: 1.0,
                    child: _buildHeader(),
                  ),
                  
                  // Main content area
                  Expanded(
                    child: FocusManagementUtils.createFocusOrder(
                      order: 2.0,
                      child: _buildMainContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Get chapter metadata from initial progress or mock data
    final chapterTitle = widget.initialProgress?.chapterTitle ?? 'Chapter ${widget.chapterNumber}';
    final pageRange = widget.initialProgress?.pageRange ?? 'pp. 1-25';
    final estimatedReadingTime = widget.initialProgress?.estimatedReadingTimeMinutes ?? 15;
    
    return ChapterReadingHeader(
      textbook: widget.textbook,
      readingState: _readingState,
      onBackPressed: _handleBackNavigation,
      chapterTitle: chapterTitle,
      pageRange: pageRange,
      estimatedReadingTime: estimatedReadingTime,
      isChapterCompleted: _readingState.isChapterCompleted,
    );
  }
  Widget _buildMainContent() {
    return FocusManagementUtils.createFocusTraversalGroup(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Study tools bar
            FocusManagementUtils.createFocusOrder(
              order: 2.1,
              child: Focus(
                focusNode: _toolsBarFocusNode,
                child: StudyToolsBar(
                  isHighlightMode: _readingState.isHighlightMode,
                  onHighlightToggle: () {
                    _updateReadingState(_readingState.toggleHighlightMode());
                    AccessibilityUtils.announceMessage(
                      _readingState.isHighlightMode 
                          ? 'Highlight mode activated'
                          : 'Highlight mode deactivated'
                    );
                  },
                  onBookmarkPressed: () {
                    _addBookmark();
                    AccessibilityUtils.announceMessage('Section bookmarked');
                  },
                  onAITutorPressed: _openAITutor,
                  isCurrentSectionBookmarked: _isCurrentSectionBookmarked(),
                  isAITutorAvailable: true,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Key points section placeholder
            FocusManagementUtils.createFocusOrder(
              order: 2.2,
              child: _buildKeyPointsPlaceholder(),
            ),
            
            const SizedBox(height: 16),
            
            // Content display area
            FocusManagementUtils.createFocusOrder(
              order: 2.3,
              child: Focus(
                focusNode: _contentFocusNode,
                child: ContentDisplayArea(
                  sections: _readingState.sections,
                  currentSectionIndex: _readingState.currentSectionIndex,
                  highlights: _readingState.highlights,
                  isHighlightMode: _readingState.isHighlightMode,
                  onTextHighlighted: _addHighlight,
                  onHighlightTapped: _showHighlightOptions,
                  onHighlightRemoved: _removeHighlight,
                  onHighlightColorChanged: _updateHighlightColor,
                  onScrollChanged: (offset, maxExtent) {
                    // Handle scroll changes for progress tracking
                  },
                  onSectionCompleted: (sectionIndex) {
                    final updatedState = _readingState.markSectionCompleted(sectionIndex);
                    _updateReadingState(updatedState);
                    AccessibilityUtils.announceMessage('Section completed');
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Section navigator placeholder
            FocusManagementUtils.createFocusOrder(
              order: 2.4,
              child: Focus(
                focusNode: _navigationFocusNode,
                child: _buildSectionNavigatorPlaceholder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Study action buttons
            FocusManagementUtils.createFocusOrder(
              order: 2.5,
              child: Focus(
                focusNode: _actionButtonsFocusNode,
                child: StudyActionButtons(
                  onCreateFlashcards: _createFlashcards,
                  onQuizMe: _startQuiz,
                  isEnabled: true,
                ),
              ),
            ),
          ],
        ),
      ),
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


  // Keyboard shortcut methods
  void _toggleHighlightMode() {
    _updateReadingState(_readingState.toggleHighlightMode());
    AccessibilityUtils.announceMessage(
      _readingState.isHighlightMode 
          ? 'Highlight mode activated'
          : 'Highlight mode deactivated'
    );
  }

  void _navigateToPreviousSection() {
    if (_readingState.hasPreviousSection) {
      final newState = _readingState.updateCurrentSection(
        _readingState.currentSectionIndex - 1,
      );
      _updateReadingState(newState);
      AccessibilityUtils.announceMessage(
        'Moved to section ${newState.currentSectionIndex + 1}'
      );
      // Focus the content area after navigation
      FocusManagementUtils.requestFocusWithDelay(_contentFocusNode);
    }
  }

  void _navigateToNextSection() {
    if (_readingState.hasNextSection) {
      final newState = _readingState.updateCurrentSection(
        _readingState.currentSectionIndex + 1,
      );
      _updateReadingState(newState);
      AccessibilityUtils.announceMessage(
        'Moved to section ${newState.currentSectionIndex + 1}'
      );
      // Focus the content area after navigation
      FocusManagementUtils.requestFocusWithDelay(_contentFocusNode);
    }
  }

  @override
  void dispose() {
    // Final save before disposal
    _saveState();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    
    // Dispose controllers
    _fadeController.dispose();
    _scrollController.dispose();
    _restorationId.dispose();
    
    super.dispose();
  }
}

/// Helper class to observe app lifecycle changes
class _AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onPaused;
  final VoidCallback onResumed;

  _AppLifecycleObserver({
    required this.onPaused,
    required this.onResumed,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        onPaused();
        break;
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }
}