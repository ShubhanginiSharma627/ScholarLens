import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../models/learning_session.dart';
import 'learning_session_card.dart';

/// Section widget that displays recent learning sessions as horizontal scrollable cards
class ContinueLearningSection extends StatelessWidget {
  const ContinueLearningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final recentSessions = appState.recentSessions;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Continue Learning',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recentSessions.isNotEmpty)
              TextButton(
                onPressed: () => _handleViewAll(context),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentSessions.isEmpty)
          _buildEmptyState(context)
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentSessions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final session = recentSessions[index];
                return LearningSessionCard(
                  session: session,
                  onTap: () => _handleSessionTap(context, session),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
            Icons.school_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Start Your Learning Journey',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a photo or upload content to begin',
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
    // TODO: Navigate to all sessions screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View all sessions coming soon!')),
    );
  }

  void _handleSessionTap(BuildContext context, LearningSession session) {
    // TODO: Navigate to session details or resume session
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Resume ${session.content.lessonTitle}')),
    );
  }
}