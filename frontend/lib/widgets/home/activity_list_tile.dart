import 'package:flutter/material.dart';

import '../../models/recent_activity.dart';

/// List tile widget for displaying recent activity with leading icon, title, and timestamp
class ActivityListTile extends StatelessWidget {
  final RecentActivity activity;
  final VoidCallback onTap;

  const ActivityListTile({
    super.key,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getActivityColor(activity.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getActivityIcon(activity.type),
          color: _getActivityColor(activity.type),
          size: 20,
        ),
      ),
      title: Text(
        activity.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSubjectColor(activity.subject).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.subject,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getSubjectColor(activity.subject),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Text(
        activity.formattedTime,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Gets appropriate icon for activity type
  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.lesson:
        return Icons.school;
      case ActivityType.quiz:
        return Icons.quiz;
      case ActivityType.flashcard:
        return Icons.style;
      case ActivityType.chat:
        return Icons.chat;
      case ActivityType.upload:
        return Icons.upload_file;
    }
  }

  /// Gets appropriate color for activity type
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.lesson:
        return Colors.blue;
      case ActivityType.quiz:
        return Colors.green;
      case ActivityType.flashcard:
        return Colors.orange;
      case ActivityType.chat:
        return Colors.purple;
      case ActivityType.upload:
        return Colors.teal;
    }
  }

  /// Gets appropriate color for subject
  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return Colors.blue;
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Colors.green;
      case 'history':
        return Colors.brown;
      case 'english':
      case 'literature':
        return Colors.purple;
      case 'geography':
        return Colors.teal;
      case 'computer science':
      case 'programming':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }
}