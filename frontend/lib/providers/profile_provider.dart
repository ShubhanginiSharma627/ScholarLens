import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/profile_service.dart' as profile_service;
class ProfileProvider extends ChangeNotifier {
  final profile_service.ProfileService _profileService = profile_service.ProfileService();
  profile_service.UserProfile? _userProfile;
  List<profile_service.UserAchievement> _achievements = [];
  bool _isLoading = false;
  String? _error;
  profile_service.UserProfile? get userProfile => _userProfile;
  List<profile_service.UserAchievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadProfile();
      await _loadAchievements();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize profile: $e');
    } finally {
      _setLoading(false);
    }
  }
  Future<void> _loadProfile() async {
    try {
      _userProfile = await _profileService.getUserProfile();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }
  Future<void> _loadAchievements() async {
    try {
      _achievements = await _profileService.getUserAchievements();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load achievements: $e');
    }
  }
  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? birthDate,
    String? school,
    String? grade,
  }) async {
    try {
      _userProfile = await _profileService.updateProfile(
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        birthDate: birthDate,
        school: school,
        grade: grade,
      );
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Failed to update profile: $e');
      rethrow;
    }
  }
  Future<List<profile_service.UserAchievement>> checkForNewAchievements(UserProgress progress) async {
    try {
      final newAchievements = await _profileService.checkForNewAchievements(progress);
      if (newAchievements.isNotEmpty) {
        _achievements = [..._achievements, ...newAchievements];
        notifyListeners();
      }
      return newAchievements;
    } catch (e) {
      _setError('Failed to check achievements: $e');
      return [];
    }
  }
  Future<bool> unlockAchievement(String achievementId, UserProgress progress) async {
    try {
      final wasUnlocked = await _profileService.unlockAchievement(achievementId, progress);
      if (wasUnlocked) {
        await _loadAchievements(); // Reload to get updated list
      }
      return wasUnlocked;
    } catch (e) {
      _setError('Failed to unlock achievement: $e');
      return false;
    }
  }
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      return await _profileService.exportUserData();
    } catch (e) {
      _setError('Failed to export data: $e');
      rethrow;
    }
  }
  Future<void> importUserData(Map<String, dynamic> data) async {
    try {
      await _profileService.importUserData(data);
      await initialize(); // Reload all data
      _clearError();
    } catch (e) {
      _setError('Failed to import data: $e');
      rethrow;
    }
  }
  Future<void> clearAllData() async {
    try {
      await _profileService.clearAllUserData();
      _userProfile = null;
      _achievements = [];
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Failed to clear data: $e');
      rethrow;
    }
  }
  List<profile_service.UserAchievement> get unlockedAchievements {
    return _achievements.where((achievement) => achievement.isUnlocked).toList();
  }
  List<profile_service.UserAchievement> get lockedAchievements {
    return _achievements.where((achievement) => !achievement.isUnlocked).toList();
  }
  int get totalAchievements => _achievements.length;
  int get unlockedCount => unlockedAchievements.length;
  double get achievementProgress => totalAchievements > 0 ? unlockedCount / totalAchievements : 0.0;
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