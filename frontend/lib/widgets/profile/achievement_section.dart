import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/profile_service.dart';

/// Achievement section displaying badges, streaks, and milestone accomplishments
class AchievementSection extends StatefulWidget {
  final UserProgress userProgress;

  const AchievementSection({
    super.key,
    required this.userProgress,
  });

  @override
  State<AchievementSection> createState() => _AchievementSectionState();
}

class _AchievementSectionState extends State<AchievementSection> {
  final _profileService = ProfileService();
  List<UserAchievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final achievements = await _profileService.getUserAchievements();
      final newAchievements = await _profileService.checkForNewAchievements(widget.userProgress);
      
      setState(() {
        _achievements = [...achievements, ...newAchievements];
        _isLoading = false;
      });
      
      // Show notifications for new achievements
      for (final achievement in newAchievements) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Achievement Unlocked: ${achievement.title}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_achievements.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No achievements yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep learning to unlock your first achievement!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return _buildAchievementBadge(context, achievement);
            },
          ),
      ],
    );
  }

  Widget _buildAchievementBadge(BuildContext context, UserAchievement achievement) {
    final iconData = IconData(achievement.icon, fontFamily: 'MaterialIcons');
    final color = Color(achievement.color);
    
    return Card(
      elevation: achievement.isUnlocked ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: achievement.isUnlocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 32,
                color: achievement.isUnlocked
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                achievement.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: achievement.isUnlocked
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                achievement.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: achievement.isUnlocked
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}