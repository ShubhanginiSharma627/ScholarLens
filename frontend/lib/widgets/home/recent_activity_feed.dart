import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../providers/progress_provider.dart';
import '../../models/recent_activity.dart';
import 'activity_list_tile.dart';

/// Widget that displays recent activities as list tiles with timestamps and descriptions
class RecentActivityFeed extends StatelessWidget {
  const RecentActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final recentActivities = progress.recentActivities;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recentActivities.isNotEmpty)
              TextButton(
                onPressed: () => _handleViewAll(context),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentActivities.isEmpty)
          _buildEmptyState(context)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(recentActivities.length, 5), // Show max 5 items
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = recentActivities[index];
              return ActivityListTile(
                activity: activity,
                onTap: () => _handleActivityTap(context, activity),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your learning activities will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleViewAll(BuildContext context) {
    // TODO: Navigate to all activities screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View all activities coming soon!')),
    );
  }

  void _handleActivityTap(BuildContext context, RecentActivity activity) {
    // TODO: Navigate to activity details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View ${activity.title} details')),
    );
  }
}