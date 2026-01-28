import 'package:flutter/material.dart';
import 'package:scholar_lens/theme/app_theme.dart';

/// Action buttons for creating study materials from chapter content
/// Provides quick access to flashcard creation and quiz generation
class StudyActionButtons extends StatelessWidget {
  /// Callback when "Create Flashcards" button is pressed
  final VoidCallback onCreateFlashcards;
  
  /// Callback when "Quiz Me" button is pressed
  final VoidCallback onQuizMe;
  
  /// Whether the buttons should be disabled (e.g., during loading)
  final bool isEnabled;

  const StudyActionButtons({
    super.key,
    required this.onCreateFlashcards,
    required this.onQuizMe,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Study Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Action buttons row
          Row(
            children: [
              // Create Flashcards button with purple background
              Expanded(
                child: _buildActionButton(
                  context: context,
                  onPressed: isEnabled ? onCreateFlashcards : null,
                  icon: Icons.quiz,
                  label: 'Create Flashcards',
                  isPrimary: true,
                  tooltip: 'Generate flashcards from this chapter content',
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              
              // Quiz Me button with default styling
              Expanded(
                child: _buildActionButton(
                  context: context,
                  onPressed: isEnabled ? onQuizMe : null,
                  icon: Icons.assignment,
                  label: 'Quiz Me',
                  isPrimary: false,
                  tooltip: 'Take a quiz on this chapter content',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? Colors.purple 
              : colorScheme.primaryContainer,
          foregroundColor: isPrimary 
              ? Colors.white 
              : colorScheme.onPrimaryContainer,
          elevation: AppTheme.elevationS,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          minimumSize: const Size(0, 48), // Ensure minimum touch target
        ),
      ),
    );
  }
}