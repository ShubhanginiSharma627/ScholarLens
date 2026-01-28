import 'package:flutter/material.dart';
import 'smart_transition.dart';

/// Example usage of SmartTransition to replace MaterialPageRoute
/// 
/// This file demonstrates how to migrate from MaterialPageRoute to SmartTransition
/// for enhanced navigation animations throughout the Scholar Lens app.
class SmartTransitionExample {
  
  /// Example 1: Basic slide transition (replaces MaterialPageRoute)
  /// 
  /// Before:
  /// ```dart
  /// Navigator.of(context).push(
  ///   MaterialPageRoute(
  ///     builder: (context) => const ProfileScreen(),
  ///   ),
  /// );
  /// ```
  /// 
  /// After:
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

  /// Example 2: Modal presentation with slide-up
  /// 
  /// For modal screens like CreateFlashcardScreen:
  static void navigateToCreateFlashcard(BuildContext context) {
    Navigator.of(context).push(
      SmartTransition.slideUp(
        child: const CreateFlashcardScreen(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }

  /// Example 3: Camera screen with fade transition
  /// 
  /// For camera and scanner screens to avoid jarring changes:
  static void navigateToCamera(BuildContext context) {
    Navigator.of(context).push(
      SmartTransition.fade(
        child: const CameraScreen(),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Example 4: Hero transition for shared elements
  /// 
  /// For screens with shared visual elements:
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

  /// Example 5: Adaptive transition that chooses based on context
  /// 
  /// Let SmartTransition choose the best transition:
  static void navigateAdaptive(BuildContext context, Widget destination) {
    Navigator.of(context).push(
      SmartTransition.adaptive(
        child: destination,
        context: context,
        // Will automatically choose:
        // - Slide for phone navigation
        // - Fade for camera screens
        // - SlideUp for modals
        // - Scale for dialogs
      ),
    );
  }

  /// Example 6: Using extension methods for cleaner syntax
  /// 
  /// The extension methods provide even cleaner syntax:
  static void navigateWithExtensions(BuildContext context) {
    // Slide transition
    context.pushSlide(
      const ProfileScreen(),
      direction: const Offset(1.0, 0.0),
    );

    // Fade transition
    context.pushFade(const CameraScreen());

    // Scale transition
    context.pushScale(const CreateFlashcardScreen());

    // Slide-up modal
    context.pushSlideUp(const CreateFlashcardScreen());

    // Hero transition
    context.pushHero(
      const ProfileScreen(),
      heroTag: 'profile-hero',
    );

    // Adaptive transition
    context.pushAdaptive(const ProfileScreen());
  }

  /// Example 7: Using predefined configurations
  /// 
  /// For common navigation patterns:
  static void navigateWithConfigs(BuildContext context) {
    // Bottom navigation tab
    Navigator.of(context).push(
      SmartTransitionConfigs.bottomNavTab(const ProfileScreen()),
    );

    // Modal presentation
    Navigator.of(context).push(
      SmartTransitionConfigs.modal(const CreateFlashcardScreen()),
    );

    // Camera screen
    Navigator.of(context).push(
      SmartTransitionConfigs.camera(const CameraScreen()),
    );

    // Back navigation
    Navigator.of(context).push(
      SmartTransitionConfigs.back(const ProfileScreen()),
    );

    // Dialog
    Navigator.of(context).push(
      SmartTransitionConfigs.dialog(const CreateFlashcardScreen()),
    );
  }

  /// Example 8: Custom transition with duration and curve customization
  /// 
  /// For specific animation requirements:
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

/// Placeholder classes for the examples (these would be actual screens in the app)
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