import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../services/api_service.dart';
import 'flashcard_service.dart';

class AnalyticsService {
  static const String _studySessionsKey = 'study_sessions';
  static const String _weeklyStatsKey = 'weekly_stats';
  final FlashcardService _flashcardService = FlashcardService();
  final ApiService _apiService = ApiService();

  Future<AnalyticsData> getAnalyticsData() async {
    try {
      // Get stats from backend
      final userStats = await _apiService.getUserStats();
      
      // Debug logging
      print('UserStats received: ${userStats.toString()}');
      print('WeakestTopics: ${userStats.weakestTopics}');
      print('Streak: ${userStats.streak}');
      print('Streak type: ${userStats.streak.runtimeType}');
      
      // Get flashcards for additional calculations
      final flashcards = await _flashcardService.getAllFlashcards();
      final studySessions = await _getStudySessions();
      
      // Calculate additional metrics from local data
      final weeklyStudyTime = _getWeeklyStudyTimeData();
      final activityBreakdown = _getActivityBreakdown(studySessions);
      final subjectPerformance = _getSubjectPerformance(flashcards, studySessions);
      final areasToImprove = _getAreasToImprove(flashcards, studySessions);
      
      return AnalyticsData(
        totalStudyTime: _calculateTotalStudyTime(studySessions),
        averageAccuracy: _calculateAverageAccuracy(userStats.quizScores),
        questionsSolved: userStats.totalInteractions,
        performanceChange: _calculatePerformanceChange(userStats.quizScores),
        weeklyStudyTime: weeklyStudyTime,
        activityBreakdown: activityBreakdown,
        subjectPerformance: subjectPerformance,
        areasToImprove: areasToImprove,
        streak: userStats.streak ?? 1, // Pass the value or default to 1
        topTopics: userStats.topics,
        weakestTopics: userStats.weakestTopics, // Pass nullable value directly
      );
    } catch (e) {
      // Debug logging
      print('Analytics API error: $e');
      // Fallback to local data if API fails
      return await _getLocalAnalyticsData();
    }
  }

  Future<AnalyticsData> _getLocalAnalyticsData() async {
    final flashcards = await _flashcardService.getAllFlashcards();
    final studySessions = await _getStudySessions();
    
    return AnalyticsData(
      totalStudyTime: _calculateTotalStudyTime(studySessions),
      averageAccuracy: _calculateAverageAccuracy([]),
      questionsSolved: studySessions.length,
      performanceChange: _calculatePerformanceChange([]),
      weeklyStudyTime: _getWeeklyStudyTimeData(),
      activityBreakdown: _getActivityBreakdown(studySessions),
      subjectPerformance: _getSubjectPerformance(flashcards, studySessions),
      areasToImprove: _getAreasToImprove(flashcards, studySessions),
      streak: 1, // Default to 1 for local data
      topTopics: {},
      weakestTopics: null, // Pass null for local data
    );
  }

  Future<List<StudySession>> _getStudySessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_studySessionsKey) ?? [];
    return sessionsJson
        .map((json) => StudySession.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> recordStudySession(StudySession session) async {
    final sessions = await _getStudySessions();
    sessions.add(session);
    
    // Keep only last 100 sessions to avoid storage bloat
    if (sessions.length > 100) {
      sessions.removeRange(0, sessions.length - 100);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = sessions
        .map((session) => jsonEncode(session.toJson()))
        .toList();
    await prefs.setStringList(_studySessionsKey, sessionsJson);
    
    // Update weekly stats
    await _updateWeeklyStats(session);
  }

  Future<Map<String, dynamic>> _getWeeklyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_weeklyStatsKey);
    if (statsJson == null) return {};
    return jsonDecode(statsJson);
  }

  Future<void> _updateWeeklyStats(StudySession session) async {
    final stats = await _getWeeklyStats();
    final weekKey = _getWeekKey(session.timestamp);
    
    if (!stats.containsKey(weekKey)) {
      stats[weekKey] = {
        'totalTime': 0.0,
        'totalSessions': 0,
        'correctAnswers': 0,
        'totalAnswers': 0,
      };
    }
    
    stats[weekKey]['totalTime'] += session.duration;
    stats[weekKey]['totalSessions'] += 1;
    if (session.isCorrect) {
      stats[weekKey]['correctAnswers'] += 1;
    }
    stats[weekKey]['totalAnswers'] += 1;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyStatsKey, jsonEncode(stats));
  }

  String _getWeekKey(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return '${startOfWeek.year}-W${startOfWeek.month}-${startOfWeek.day}';
  }

  double _calculateTotalStudyTime(List<StudySession> sessions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    return sessions
        .where((session) => session.timestamp.isAfter(weekAgo))
        .fold(0.0, (sum, session) => sum + session.duration);
  }

  double _calculateAverageAccuracy(List<double> quizScores) {
    if (quizScores.isEmpty) return 0.0;
    
    final sum = quizScores.fold(0.0, (sum, score) => sum + score);
    return sum / quizScores.length;
  }

  double _calculatePerformanceChange(List<double> quizScores) {
    if (quizScores.length < 2) return 0.0;
    
    // Compare recent scores with earlier scores
    final recentScores = quizScores.length > 5 
        ? quizScores.sublist(quizScores.length - 5)
        : quizScores;
    final earlierScores = quizScores.length > 10
        ? quizScores.sublist(0, quizScores.length - 5)
        : quizScores.sublist(0, (quizScores.length / 2).floor());
    
    if (earlierScores.isEmpty) return 0.0;
    
    final recentAvg = recentScores.fold(0.0, (sum, score) => sum + score) / recentScores.length;
    final earlierAvg = earlierScores.fold(0.0, (sum, score) => sum + score) / earlierScores.length;
    
    return recentAvg - earlierAvg;
  }

  List<WeeklyStudyData> _getWeeklyStudyTimeData() {
    final now = DateTime.now();
    final weekData = <WeeklyStudyData>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      // For now, return some sample data based on actual usage patterns
      final studyTime = (i % 2 == 0) ? 2.5 + (i * 0.5) : 1.5 + (i * 0.3);
      weekData.add(WeeklyStudyData(dayName, studyTime));
    }
    
    return weekData;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Map<String, double> _getActivityBreakdown(List<StudySession> sessions) {
    if (sessions.isEmpty) {
      return {
        'Flashcards': 100.0,
        'Mock Exams': 0.0,
        'AI Tutor': 0.0,
        'Snap & Solve': 0.0,
      };
    }
    
    final activityCounts = <String, int>{};
    for (final session in sessions) {
      activityCounts[session.activityType] = 
          (activityCounts[session.activityType] ?? 0) + 1;
    }
    
    final total = sessions.length;
    return activityCounts.map((key, value) => 
        MapEntry(key, (value / total) * 100));
  }

  Map<String, double> _getSubjectPerformance(
    List<Flashcard> flashcards, 
    List<StudySession> sessions
  ) {
    final subjectScores = <String, List<bool>>{};
    
    for (final session in sessions) {
      final flashcard = flashcards.firstWhere(
        (card) => card.id == session.flashcardId,
        orElse: () => Flashcard.create(
          subject: 'Unknown',
          question: '',
          answer: '',
        ),
      );
      
      if (!subjectScores.containsKey(flashcard.subject)) {
        subjectScores[flashcard.subject] = [];
      }
      subjectScores[flashcard.subject]!.add(session.isCorrect);
    }
    
    return subjectScores.map((subject, scores) {
      final correctCount = scores.where((correct) => correct).length;
      final accuracy = scores.isNotEmpty ? (correctCount / scores.length) * 100 : 0.0;
      return MapEntry(subject, accuracy);
    });
  }

  List<ImprovementArea> _getAreasToImprove(
    List<Flashcard> flashcards,
    List<StudySession> sessions
  ) {
    final subjectPerformance = _getSubjectPerformance(flashcards, sessions);
    
    return subjectPerformance.entries
        .map((entry) => ImprovementArea(
              subject: entry.key,
              currentScore: entry.value.round(),
              change: 0, // TODO: Calculate actual change
            ))
        .where((area) => area.currentScore < 80) // Focus on areas below 80%
        .toList()
      ..sort((a, b) => a.currentScore.compareTo(b.currentScore));
  }
}

class AnalyticsData {
  final double totalStudyTime;
  final double averageAccuracy;
  final int questionsSolved;
  final double performanceChange;
  final List<WeeklyStudyData> weeklyStudyTime;
  final Map<String, double> activityBreakdown;
  final Map<String, double> subjectPerformance;
  final List<ImprovementArea> areasToImprove;
  final int? streak; // Make nullable to handle runtime null
  final Map<String, int> topTopics;
  final List<WeakTopic>? weakestTopics; // Keep nullable

  AnalyticsData({
    required this.totalStudyTime,
    required this.averageAccuracy,
    required this.questionsSolved,
    required this.performanceChange,
    required this.weeklyStudyTime,
    required this.activityBreakdown,
    required this.subjectPerformance,
    required this.areasToImprove,
    this.streak, // Make optional
    required this.topTopics,
    this.weakestTopics, // Keep optional
  });
}

class StudySession {
  final String id;
  final String flashcardId;
  final DateTime timestamp;
  final double duration; // in hours
  final bool isCorrect;
  final String activityType;

  StudySession({
    required this.id,
    required this.flashcardId,
    required this.timestamp,
    required this.duration,
    required this.isCorrect,
    required this.activityType,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'],
      flashcardId: json['flashcardId'],
      timestamp: DateTime.parse(json['timestamp']),
      duration: json['duration'].toDouble(),
      isCorrect: json['isCorrect'],
      activityType: json['activityType'] ?? 'Flashcards',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flashcardId': flashcardId,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration,
      'isCorrect': isCorrect,
      'activityType': activityType,
    };
  }
}

class WeeklyStudyData {
  final String day;
  final double hours;

  WeeklyStudyData(this.day, this.hours);
}

class ImprovementArea {
  final String subject;
  final int currentScore;
  final int change;

  ImprovementArea({
    required this.subject,
    required this.currentScore,
    required this.change,
  });
}