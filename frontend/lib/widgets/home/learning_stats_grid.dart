import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/progress_provider.dart';
import 'stat_card.dart';

/// Grid widget that displays learning statistics in a 2x2 layout
class LearningStatsGrid extends StatelessWidget {
  const LearningStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            StatCard(
              title: 'Day Streak',
              value: '${progress.dayStreak}',
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Topics Mastered',
              value: '${progress.topicsMastered}',
              icon: Icons.school,
              color: Colors.green,
            ),
            StatCard(
              title: 'Questions Solved',
              value: '${progress.questionsSolved}',
              icon: Icons.quiz,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Study Hours',
              value: progress.formattedStudyHours,
              icon: Icons.access_time,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}