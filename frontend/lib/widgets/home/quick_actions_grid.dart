import 'package:flutter/material.dart';
import 'quick_action_button.dart';
import '../../screens/tutor_chat_screen.dart';
import '../../screens/syllabus_scanner_screen.dart';
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
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
          childAspectRatio: 1.5,
          children: [
            QuickActionButton(
              title: 'Snap & Solve',
              subtitle: 'Take a photo to learn',
              icon: Icons.camera_alt,
              color: Colors.blue,
              onTap: () => _handleSnapAndSolve(context),
            ),
            QuickActionButton(
              title: 'Upload Syllabus',
              subtitle: 'Plan your studies',
              icon: Icons.upload_file,
              color: Colors.green,
              onTap: () => _handleUploadSyllabus(context),
            ),
            QuickActionButton(
              title: 'Review Flashcards',
              subtitle: 'Practice with cards',
              icon: Icons.style,
              color: Colors.orange,
              onTap: () => _handleReviewFlashcards(context),
            ),
            QuickActionButton(
              title: 'Ask AI Tutor',
              subtitle: 'Get instant help',
              icon: Icons.chat,
              color: Colors.purple,
              onTap: () => _handleAskTutor(context),
            ),
          ],
        ),
      ],
    );
  }
  void _handleSnapAndSolve(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature coming soon!')),
    );
  }
  void _handleUploadSyllabus(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SyllabusScannerScreen(),
      ),
    );
  }
  void _handleReviewFlashcards(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flashcards feature coming soon!')),
    );
  }
  void _handleAskTutor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TutorChatScreen(),
      ),
    );
  }
}