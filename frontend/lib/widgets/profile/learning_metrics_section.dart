import 'package:flutter/material.dart';
import '../../models/models.dart';
class LearningMetricsSection extends StatelessWidget {
  final UserProgress userProgress;
  const LearningMetricsSection({
    super.key,
    required this.userProgress,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Metrics',
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
            _buildMetricCard(
              context,
              Icons.local_fire_department,
              '${userProgress.dayStreak}',
              'Day Streak',
              Colors.orange,
            ),
            _buildMetricCard(
              context,
              Icons.school,
              '${userProgress.topicsMastered}',
              'Topics Mastered',
              Colors.blue,
            ),
            _buildMetricCard(
              context,
              Icons.quiz,
              '${userProgress.questionsSolved}',
              'Questions Solved',
              Colors.green,
            ),
            _buildMetricCard(
              context,
              Icons.access_time,
              userProgress.formattedStudyHours,
              'Study Time',
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (userProgress.subjectProgress.isNotEmpty) ...[
          Text(
            'Subject Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...userProgress.subjectProgress.entries.map(
            (entry) => _buildSubjectProgress(context, entry.key, entry.value),
          ),
        ],
      ],
    );
  }
  Widget _buildMetricCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSubjectProgress(BuildContext context, String subject, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}