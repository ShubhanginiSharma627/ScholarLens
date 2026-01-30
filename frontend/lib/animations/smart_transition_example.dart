import 'package:flutter/material.dart';
import 'smart_transition.dart';
import 'animation_config.dart';
class SmartTransitionExample {
  static void navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      SmartTransition.slide(
        child: const ProfileScreen(),
        direction: const Offset(1.0, 0.0), // Slide from right
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
  static void navigateToCreateFlashcard(BuildContext context) {
    Navigator.of(context).push(
      SmartTransition.slideUp(
        child: const CreateFlashcardScreen(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }
  static void navigateToCamera(BuildContext context) {
    Navigator.of(context).push(
      SmartTransition.fade(
        child: const CameraScreen(),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      ),
    );
  }
  static void navigateToTextbookDetail(
    BuildContext context, 
    UploadedTextbook textbook,
  ) {
    Navigator.of(context).push(
      SmartTransition.hero(
        child: TextbookDetailScreen(textbook: textbook),
        heroTag: 'textbook-${textbook.id}',
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }
  static void navigateAdaptive(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      SmartTransition.adaptive(
        child: destination,
        context: context,
      ),
    );
  }
  static void navigateWithExtensions(BuildContext context) {
    context.pushSlide(
      const ProfileScreen(),
      direction: const Offset(1.0, 0.0),
    );
    context.pushFade(const CameraScreen());
    context.pushScale(const CreateFlashcardScreen());
    context.pushSlideUp(const CreateFlashcardScreen());
    context.pushHero(
      const ProfileScreen(),
      heroTag: 'profile-hero',
    );
    context.pushAdaptive(const ProfileScreen());
  }
  static void navigateWithConfigs(BuildContext context) {
    Navigator.of(context).push(
      SmartTransitionConfigs.bottomNavTab(const ProfileScreen()),
    );
    Navigator.of(context).push(
      SmartTransitionConfigs.modal(const CreateFlashcardScreen()),
    );
    Navigator.of(context).push(
      SmartTransitionConfigs.camera(const CameraScreen()),
    );
    Navigator.of(context).push(
      SmartTransitionConfigs.back(const ProfileScreen()),
    );
    Navigator.of(context).push(
      SmartTransitionConfigs.dialog(const CreateFlashcardScreen()),
    );
  }
  static void navigateCustom(BuildContext context) {
    Navigator.of(context).push(
      SmartTransition(
        child: const TutorChatScreen(),
        type: TransitionType.slide,
        duration: const Duration(milliseconds: 400), // Custom duration
        curve: Curves.elasticOut, // Custom curve
        slideDirection: const Offset(0.0, 1.0), // Slide from bottom
        maintainState: true,
        fullscreenDialog: false,
      ),
    );
  }
}
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Screen')),
    );
  }
}
class CreateFlashcardScreen extends StatelessWidget {
  const CreateFlashcardScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Flashcard')),
      body: const Center(child: Text('Create Flashcard Screen')),
    );
  }
}
class CameraScreen extends StatelessWidget {
  const CameraScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: const Center(child: Text('Camera Screen')),
    );
  }
}
class TextbookDetailScreen extends StatelessWidget {
  final UploadedTextbook textbook;
  const TextbookDetailScreen({Key? key, required this.textbook}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(textbook.title)),
      body: Center(child: Text('Textbook: ${textbook.title}')),
    );
  }
}
class TutorChatScreen extends StatelessWidget {
  const TutorChatScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Chat')),
      body: const Center(child: Text('Tutor Chat Screen')),
    );
  }
}
class UploadedTextbook {
  final String id;
  final String title;
  const UploadedTextbook({required this.id, required this.title});
}