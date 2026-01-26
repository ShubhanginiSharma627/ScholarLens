import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/models.dart';

/// Service for managing user learning progress and statistics with local storage
class ProgressService {
  static const String _progressKey = 'user_progress';
  static const String _lastActiveDateKey = 'last_active_date';
  static const String _recentActivitiesKey = 'recent_activities';

  /// Get user progress from local storage
  Future<UserProgress> getUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);
      
      if (progressJson != null) {
        final progressMap = json.decode(progressJson) as Map<String, dynamic>;
        return UserProgress.fromJson(progressMap);
      }
      
      return UserProgress.empty();
    } catch (e) {
      throw Exception('Failed to load user progress: $e');
    }
  }

  /// Save user progress to local storage
  Future<void> saveUserProgress(UserProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = json.encode(progress.toJson());
      await prefs.setString(_progressKey, progressJson);
    } catch (e) {
      throw Exception('Failed to save user progress: $e');
    }
  }

  /// Update learning statistics based on a completed session
  Future<UserProgress> updateLearningStats(LearningSession session) async {
    try {
      final currentProgress = await getUserProgress();
      
      // Update progress with session data
      final updatedProgress = currentProgress.updateWithSession(
        questionsAnswered: session.questionsAnswered,
        sessionDuration: session.duration,
        subject: session.subject,
        topicMastered: session.accuracy >= 0.8, // 80% accuracy threshold for mastery
      );

      // Create recent activity for this session
      final activity = RecentActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Completed ${session.content.lessonTitle}',
        description: 'Answered ${session.questionsAnswered} questions with ${session.accuracyPercentage} accuracy',
        subject: session.subject,
        timestamp: session.endTime,
        type: ActivityType.lesson,
      );

      // Add activity to recent activities (keep only last 10)
      final updatedActivities = [activity, ...updatedProgress.recentActivities.take(9)].toList();
      final finalProgress = updatedProgress.copyWith(recentActivities: updatedActivities);

      await saveUserProgress(finalProgress);
      return finalProgress;
    } catch (e) {
      throw Exception('Failed to update learning statistics: $e');
    }
  }

  /// Update and maintain day streak
  Future<UserProgress> updateDayStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentProgress = await getUserProgress();
      final lastActiveDate = prefs.getString(_lastActiveDateKey);
      final today = DateTime.now();
      final todayString = _formatDate(today);

      // Only update if we haven't already updated today
      if (lastActiveDate != todayString) {
        int newStreak;
        
        if (lastActiveDate != null) {
          final yesterday = today.subtract(const Duration(days: 1));
          final yesterdayString = _formatDate(yesterday);
          
          if (lastActiveDate == yesterdayString) {
            // Consecutive day, increment streak
            newStreak = currentProgress.dayStreak + 1;
          } else {
            // Not consecutive, reset streak to 1
            newStreak = 1;
          }
        } else {
          // First day using the app
          newStreak = 1;
        }

        final updatedProgress = currentProgress.copyWith(dayStreak: newStreak);
        
        await prefs.setString(_lastActiveDateKey, todayString);
        await saveUserProgress(updatedProgress);
        
        return updatedProgress;
      }
      
      return currentProgress;
    } catch (e) {
      throw Exception('Failed to update day streak: $e');
    }
  }

  /// Add a recent activity to the user's activity feed
  Future<UserProgress> addRecentActivity(RecentActivity activity) async {
    try {
      final currentProgress = await getUserProgress();
      
      // Add new activity and keep only the most recent 10
      final updatedActivities = [activity, ...currentProgress.recentActivities.take(9)].toList();
      final updatedProgress = currentProgress.copyWith(recentActivities: updatedActivities);
      
      await saveUserProgress(updatedProgress);
      return updatedProgress;
    } catch (e) {
      throw Exception('Failed to add recent activity: $e');
    }
  }

  /// Get recent activities from storage
  Future<List<RecentActivity>> getRecentActivities() async {
    try {
      final progress = await getUserProgress();
      return progress.recentActivities;
    } catch (e) {
      throw Exception('Failed to get recent activities: $e');
    }
  }

  /// Update subject progress
  Future<UserProgress> updateSubjectProgress(String subject, double progress) async {
    try {
      final currentProgress = await getUserProgress();
      final updatedSubjectProgress = Map<String, double>.from(currentProgress.subjectProgress);
      updatedSubjectProgress[subject] = progress.clamp(0.0, 1.0);
      
      final updatedProgress = currentProgress.copyWith(subjectProgress: updatedSubjectProgress);
      await saveUserProgress(updatedProgress);
      
      return updatedProgress;
    } catch (e) {
      throw Exception('Failed to update subject progress: $e');
    }
  }

  /// Increment topics mastered count
  Future<UserProgress> incrementTopicsMastered() async {
    try {
      final currentProgress = await getUserProgress();
      final updatedProgress = currentProgress.copyWith(
        topicsMastered: currentProgress.topicsMastered + 1,
      );
      
      await saveUserProgress(updatedProgress);
      return updatedProgress;
    } catch (e) {
      throw Exception('Failed to increment topics mastered: $e');
    }
  }

  /// Add study time to the total
  Future<UserProgress> addStudyTime(Duration duration) async {
    try {
      final currentProgress = await getUserProgress();
      final additionalHours = duration.inMinutes / 60.0;
      final updatedProgress = currentProgress.copyWith(
        studyHours: currentProgress.studyHours + additionalHours,
      );
      
      await saveUserProgress(updatedProgress);
      return updatedProgress;
    } catch (e) {
      throw Exception('Failed to add study time: $e');
    }
  }

  /// Get progress for a specific subject
  Future<double> getSubjectProgress(String subject) async {
    try {
      final progress = await getUserProgress();
      return progress.getSubjectProgress(subject);
    } catch (e) {
      throw Exception('Failed to get subject progress: $e');
    }
  }

  /// Get all subjects with progress
  Future<List<String>> getSubjectsWithProgress() async {
    try {
      final progress = await getUserProgress();
      return progress.subjectProgress.keys.toList();
    } catch (e) {
      throw Exception('Failed to get subjects with progress: $e');
    }
  }

  /// Reset all progress data
  Future<void> resetProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_lastActiveDateKey);
      await prefs.remove(_recentActivitiesKey);
    } catch (e) {
      throw Exception('Failed to reset progress: $e');
    }
  }

  /// Check if user has been active today
  Future<bool> hasBeenActiveToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveDate = prefs.getString(_lastActiveDateKey);
      final today = _formatDate(DateTime.now());
      return lastActiveDate == today;
    } catch (e) {
      return false;
    }
  }

  /// Get the last active date
  Future<DateTime?> getLastActiveDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveDateString = prefs.getString(_lastActiveDateKey);
      if (lastActiveDateString != null) {
        final parts = lastActiveDateString.split('-');
        return DateTime(
          int.parse(parts[0]), // year
          int.parse(parts[1]), // month
          int.parse(parts[2]), // day
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Helper method to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}