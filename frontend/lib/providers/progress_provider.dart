import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
class ProgressProvider extends ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  UserProgress _progress = UserProgress.empty();
  bool _isLoading = false;
  String? _error;
  UserProgress get progress => _progress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dayStreak => _progress.dayStreak;
  int get topicsMastered => _progress.topicsMastered;
  int get questionsSolved => _progress.questionsSolved;
  double get studyHours => _progress.studyHours;
  String get formattedStudyHours => _progress.formattedStudyHours;
  Map<String, double> get subjectProgress => _progress.subjectProgress;
  List<RecentActivity> get recentActivities => _progress.recentActivities;
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _progress = await _progressService.getUserProgress();
      _clearError();
    } catch (e) {
      _setError('Failed to load progress: $e');
      _progress = UserProgress.empty();
    } finally {
      _setLoading(false);
    }
  }
  Future<void> updateWithSession(LearningSession session) async {
    _setLoading(true);
    try {
      _progress = await _progressService.updateLearningStats(session);
      _clearError();
    } catch (e) {
      _setError('Failed to update progress: $e');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> updateDayStreak() async {
    try {
      _progress = await _progressService.updateDayStreak();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update day streak: $e');
    }
  }
  Future<void> incrementTopicsMastered() async {
    try {
      _progress = await _progressService.incrementTopicsMastered();
      notifyListeners();
    } catch (e) {
      _setError('Failed to increment topics mastered: $e');
    }
  }
  Future<void> addStudyTime(Duration duration) async {
    try {
      _progress = await _progressService.addStudyTime(duration);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add study time: $e');
    }
  }
  Future<void> updateSubjectProgress(String subject, double progress) async {
    try {
      _progress = await _progressService.updateSubjectProgress(subject, progress);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update subject progress: $e');
    }
  }
  Future<void> addRecentActivity(RecentActivity activity) async {
    try {
      _progress = await _progressService.addRecentActivity(activity);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add recent activity: $e');
    }
  }
  double getSubjectProgress(String subject) {
    return _progress.getSubjectProgress(subject);
  }
  List<String> getSubjectsWithProgress() {
    return _progress.subjectProgress.keys.toList();
  }
  Future<void> resetProgress() async {
    try {
      await _progressService.resetProgress();
      _progress = UserProgress.empty();
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset progress: $e');
    }
  }
  Future<void> updateProgress(UserProgress newProgress) async {
    try {
      await _progressService.saveUserProgress(newProgress);
      _progress = newProgress;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update progress: $e');
    }
  }
  Future<void> updateChapterProgress(String textbookId, int chapterNumber, double progress) async {
    try {
      await _progressService.saveChapterProgress(textbookId, chapterNumber, progress);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update chapter progress: $e');
    }
  }
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}