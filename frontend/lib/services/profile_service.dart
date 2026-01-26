import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service for managing user profile and account data
class ProfileService {
  static const String _userProfileKey = 'user_profile';
  static const String _achievementsKey = 'user_achievements';

  /// Get user profile information
  Future<UserProfile> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        final profileMap = json.decode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileMap);
      }
      
      return UserProfile.defaultProfile();
    } catch (e) {
      return UserProfile.defaultProfile();
    }
  }

  /// Save user profile information
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Update user profile with new information
  Future<UserProfile> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? birthDate,
    String? school,
    String? grade,
  }) async {
    final currentProfile = await getUserProfile();
    
    final updatedProfile = currentProfile.copyWith(
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      birthDate: birthDate,
      school: school,
      grade: grade,
      lastUpdated: DateTime.now(),
    );
    
    await saveUserProfile(updatedProfile);
    return updatedProfile;
  }

  /// Get user achievements
  Future<List<UserAchievement>> getUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      
      if (achievementsJson != null) {
        final achievementsList = json.decode(achievementsJson) as List<dynamic>;
        return achievementsList
            .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Save user achievements
  Future<void> saveUserAchievements(List<UserAchievement> achievements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = json.encode(
        achievements.map((achievement) => achievement.toJson()).toList(),
      );
      await prefs.setString(_achievementsKey, achievementsJson);
    } catch (e) {
      throw Exception('Failed to save achievements: $e');
    }
  }

  /// Unlock an achievement
  Future<bool> unlockAchievement(String achievementId, UserProgress progress) async {
    final achievements = await getUserAchievements();
    
    // Check if achievement is already unlocked
    final existingAchievement = achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => UserAchievement.empty(),
    );
    
    if (existingAchievement.isUnlocked) {
      return false; // Already unlocked
    }
    
    // Check if achievement criteria is met
    final achievementDefinition = _getAchievementDefinition(achievementId);
    if (achievementDefinition == null || !_checkAchievementCriteria(achievementDefinition, progress)) {
      return false; // Criteria not met
    }
    
    // Unlock the achievement
    final newAchievement = UserAchievement(
      id: achievementId,
      title: achievementDefinition.title,
      description: achievementDefinition.description,
      icon: achievementDefinition.icon.codePoint,
      color: achievementDefinition.color.value,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    
    // Update achievements list
    final updatedAchievements = achievements.where((a) => a.id != achievementId).toList();
    updatedAchievements.add(newAchievement);
    
    await saveUserAchievements(updatedAchievements);
    return true; // Successfully unlocked
  }

  /// Check for new achievements based on user progress
  Future<List<UserAchievement>> checkForNewAchievements(UserProgress progress) async {
    final newlyUnlocked = <UserAchievement>[];
    
    final achievementDefinitions = _getAllAchievementDefinitions();
    
    for (final definition in achievementDefinitions) {
      final wasUnlocked = await unlockAchievement(definition.id, progress);
      if (wasUnlocked) {
        final achievement = UserAchievement(
          id: definition.id,
          title: definition.title,
          description: definition.description,
          icon: definition.icon.codePoint,
          color: definition.color.value,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlocked.add(achievement);
      }
    }
    
    return newlyUnlocked;
  }

  /// Clear all user data (for logout)
  Future<void> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_achievementsKey);
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  /// Export user data for backup
  Future<Map<String, dynamic>> exportUserData() async {
    final profile = await getUserProfile();
    final achievements = await getUserAchievements();
    
    return {
      'profile': profile.toJson(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Import user data from backup
  Future<void> importUserData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('profile')) {
        final profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
        await saveUserProfile(profile);
      }
      
      if (data.containsKey('achievements')) {
        final achievements = (data['achievements'] as List<dynamic>)
            .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
            .toList();
        await saveUserAchievements(achievements);
      }
    } catch (e) {
      throw Exception('Failed to import user data: $e');
    }
  }

  // Private helper methods
  AchievementDefinition? _getAchievementDefinition(String id) {
    return _getAllAchievementDefinitions().firstWhere(
      (def) => def.id == id,
      orElse: () => AchievementDefinition.empty(),
    );
  }

  bool _checkAchievementCriteria(AchievementDefinition definition, UserProgress progress) {
    switch (definition.id) {
      case 'first_steps':
        return progress.topicsMastered > 0;
      case 'streak_master':
        return progress.dayStreak >= 7;
      case 'quiz_champion':
        return progress.questionsSolved >= 50;
      case 'dedicated_learner':
        return progress.studyHours >= 10.0;
      case 'topic_explorer':
        return progress.topicsMastered >= 10;
      case 'consistency_king':
        return progress.dayStreak >= 30;
      case 'speed_demon':
        return progress.questionsSolved >= 100;
      case 'marathon_learner':
        return progress.studyHours >= 50.0;
      default:
        return false;
    }
  }

  List<AchievementDefinition> _getAllAchievementDefinitions() {
    return [
      AchievementDefinition(
        id: 'first_steps',
        title: 'First Steps',
        description: 'Complete your first lesson',
        icon: Icons.school,
        color: Colors.blue,
      ),
      AchievementDefinition(
        id: 'streak_master',
        title: 'Streak Master',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
      ),
      AchievementDefinition(
        id: 'quiz_champion',
        title: 'Quiz Champion',
        description: 'Answer 50 questions correctly',
        icon: Icons.quiz,
        color: Colors.green,
      ),
      AchievementDefinition(
        id: 'dedicated_learner',
        title: 'Dedicated Learner',
        description: 'Study for 10 hours total',
        icon: Icons.access_time,
        color: Colors.purple,
      ),
      AchievementDefinition(
        id: 'topic_explorer',
        title: 'Topic Explorer',
        description: 'Master 10 different topics',
        icon: Icons.explore,
        color: Colors.teal,
      ),
      AchievementDefinition(
        id: 'consistency_king',
        title: 'Consistency King',
        description: 'Maintain a 30-day streak',
        icon: Icons.emoji_events,
        color: Colors.amber,
      ),
      AchievementDefinition(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Answer 100 questions correctly',
        icon: Icons.flash_on,
        color: Colors.red,
      ),
      AchievementDefinition(
        id: 'marathon_learner',
        title: 'Marathon Learner',
        description: 'Study for 50 hours total',
        icon: Icons.fitness_center,
        color: Colors.indigo,
      ),
    ];
  }
}

/// User profile data model
class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? school;
  final String? grade;
  final DateTime createdAt;
  final DateTime lastUpdated;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.birthDate,
    this.school,
    this.grade,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      school: json['school'] as String?,
      grade: json['grade'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'birth_date': birthDate?.toIso8601String(),
      'school': school,
      'grade': grade,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory UserProfile.defaultProfile() {
    final now = DateTime.now();
    return UserProfile(
      id: 'user_${now.millisecondsSinceEpoch}',
      name: 'Scholar',
      createdAt: now,
      lastUpdated: now,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? birthDate,
    String? school,
    String? grade,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.birthDate == birthDate &&
        other.school == school &&
        other.grade == grade &&
        other.createdAt == createdAt &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      avatarUrl,
      birthDate,
      school,
      grade,
      createdAt,
      lastUpdated,
    );
  }
}

/// User achievement data model
class UserAchievement {
  final String id;
  final String title;
  final String description;
  final int icon; // IconData.codePoint
  final int color; // Color.value
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as int,
      color: json['color'] as int,
      isUnlocked: json['is_unlocked'] as bool,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'color': color,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory UserAchievement.empty() {
    return const UserAchievement(
      id: '',
      title: '',
      description: '',
      icon: 0,
      color: 0,
      isUnlocked: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAchievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.icon == icon &&
        other.color == color &&
        other.isUnlocked == isUnlocked &&
        other.unlockedAt == unlockedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      icon,
      color,
      isUnlocked,
      unlockedAt,
    );
  }
}

/// Achievement definition for checking criteria
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory AchievementDefinition.empty() {
    return const AchievementDefinition(
      id: '',
      title: '',
      description: '',
      icon: Icons.help,
      color: Colors.grey,
    );
  }
}