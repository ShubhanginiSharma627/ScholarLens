import 'package:flutter/material.dart';
import '../models/flashcard.dart';

/// Widget for rating flashcard difficulty (Easy/Medium/Hard)
class DifficultyRatingBar extends StatelessWidget {
  final Function(Difficulty) onRatingSelected;
  final Difficulty? selectedRating;

  const DifficultyRatingBar({
    super.key,
    required this.onRatingSelected,
    this.selectedRating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'How difficult was this card?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRatingButton(
              context,
              Difficulty.easy,
              'Easy',
              Icons.sentiment_very_satisfied,
              Colors.green,
            ),
            _buildRatingButton(
              context,
              Difficulty.medium,
              'Medium',
              Icons.sentiment_neutral,
              Colors.orange,
            ),
            _buildRatingButton(
              context,
              Difficulty.hard,
              'Hard',
              Icons.sentiment_very_dissatisfied,
              Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getDifficultyDescription(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRatingButton(
    BuildContext context,
    Difficulty difficulty,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedRating == difficulty;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRatingSelected(difficulty),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getNextReviewText(difficulty),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getNextReviewText(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Review in 4+ days';
      case Difficulty.medium:
        return 'Review in 2+ days';
      case Difficulty.hard:
        return 'Review tomorrow';
    }
  }

  String _getDifficultyDescription() {
    if (selectedRating == null) {
      return 'Rate this card to schedule the next review';
    }
    
    switch (selectedRating!) {
      case Difficulty.easy:
        return 'Great! This card will appear less frequently';
      case Difficulty.medium:
        return 'Good! This card will appear at regular intervals';
      case Difficulty.hard:
        return 'No worries! This card will appear more frequently';
    }
  }
}