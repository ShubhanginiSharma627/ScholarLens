import 'recent_activity.dart';
class UserProgress {
  final int dayStreak;
  final int topicsMastered;
  final int questionsSolved;
  final double studyHours;
  final Map<String, double> subjectProgress;
  final List<RecentActivity> recentActivities;
  const UserProgress({
    required this.dayStreak,
    required this.topicsMastered,
    required this.questionsSolved,
    required this.studyHours,
    required this.subjectProgress,
    required this.recentActivities,
  });
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      dayStreak: json['day_streak'] as int,
      topicsMastered: json['topics_mastered'] as int,
      questionsSolved: json['questions_solved'] as int,
      studyHours: (json['study_hours'] as num).toDouble(),
      subjectProgress: Map<String, double>.from(
        (json['subject_progress'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      recentActivities: (json['recent_activities'] as List<dynamic>)
          .map((activity) => RecentActivity.fromJson(activity as Map<String, dynamic>))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'day_streak': dayStreak,
      'topics_mastered': topicsMastered,
      'questions_solved': questionsSolved,
      'study_hours': studyHours,
      'subject_progress': subjectProgress,
      'recent_activities': recentActivities.map((activity) => activity.toJson()).toList(),
    };
  }
  factory UserProgress.empty() {
    return const UserProgress(
      dayStreak: 0,
      topicsMastered: 0,
      questionsSolved: 0,
      studyHours: 0.0,
      subjectProgress: {},
      recentActivities: [],
    );
  }
  String get formattedStudyHours {
    if (studyHours < 1.0) {
      final minutes = (studyHours * 60).round();
      return '${minutes}m';
    }
    return '${studyHours.toStringAsFixed(1)}h';
  }
  double getSubjectProgress(String subject) {
    return subjectProgress[subject] ?? 0.0;
  }
  UserProgress copyWith({
    int? dayStreak,
    int? topicsMastered,
    int? questionsSolved,
    double? studyHours,
    Map<String, double>? subjectProgress,
    List<RecentActivity>? recentActivities,
  }) {
    return UserProgress(
      dayStreak: dayStreak ?? this.dayStreak,
      topicsMastered: topicsMastered ?? this.topicsMastered,
      questionsSolved: questionsSolved ?? this.questionsSolved,
      studyHours: studyHours ?? this.studyHours,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }
  UserProgress updateWithSession({
    required int questionsAnswered,
    required Duration sessionDuration,
    required String subject,
    bool topicMastered = false,
  }) {
    final newStudyHours = studyHours + (sessionDuration.inMinutes / 60.0);
    final newQuestionsCount = questionsSolved + questionsAnswered;
    final newTopicsCount = topicMastered ? topicsMastered + 1 : topicsMastered;
    final updatedSubjectProgress = Map<String, double>.from(subjectProgress);
    final currentProgress = updatedSubjectProgress[subject] ?? 0.0;
    updatedSubjectProgress[subject] = (currentProgress + 0.1).clamp(0.0, 1.0);
    return copyWith(
      questionsSolved: newQuestionsCount,
      studyHours: newStudyHours,
      topicsMastered: newTopicsCount,
      subjectProgress: updatedSubjectProgress,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.dayStreak == dayStreak &&
        other.topicsMastered == topicsMastered &&
        other.questionsSolved == questionsSolved &&
        other.studyHours == studyHours &&
        _mapEquals(other.subjectProgress, subjectProgress) &&
        _listEquals(other.recentActivities, recentActivities);
  }
  @override
  int get hashCode {
    return Object.hash(
      dayStreak,
      topicsMastered,
      questionsSolved,
      studyHours,
      Object.hashAll(subjectProgress.entries),
      Object.hashAll(recentActivities),
    );
  }
  @override
  String toString() {
    return 'UserProgress(dayStreak: $dayStreak, topicsMastered: $topicsMastered, questionsSolved: $questionsSolved, studyHours: $studyHours, subjects: ${subjectProgress.length}, activities: ${recentActivities.length})';
  }
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}