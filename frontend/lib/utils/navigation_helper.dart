import 'package:flutter/material.dart';
import '../screens/create_flashcard_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/syllabus_scanner_screen.dart';
import '../screens/all_cards_view_screen.dart';

class NavigationHelper {
  // Simple approach using a global callback
  static void Function(int)? _onTabTapped;
  
  static void initialize(void Function(int) onTabTapped) {
    _onTabTapped = onTabTapped;
  }
  
  static void dispose() {
    _onTabTapped = null;
  }

  static void navigateToTab(BuildContext context, int tabIndex) {
    _onTabTapped?.call(tabIndex);
  }

  static void navigateToCards(BuildContext context) {
    navigateToTab(context, 3); // Cards tab is at index 3
  }

  static void navigateToTutor(BuildContext context) {
    navigateToTab(context, 1); // Tutor tab is at index 1
  }

  static void navigateToAnalytics(BuildContext context) {
    navigateToTab(context, 4); // Analytics tab is at index 4
  }

  static void navigateToHome(BuildContext context) {
    navigateToTab(context, 0); // Home tab is at index 0
  }

  // For screens that should be modals (preserving bottom nav)
  static Future<T?> showModalScreen<T>(
    BuildContext context,
    Widget screen, {
    bool fullscreenDialog = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => screen,
      ),
    );
  }

  // For screens that should be full screen but return to main nav
  static Future<T?> pushScreen<T>(
    BuildContext context,
    Widget screen, {
    bool maintainBottomNav = false,
  }) {
    if (maintainBottomNav) {
      return showModalScreen<T>(context, screen);
    } else {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  static Future<T?> navigateToAllCardsView<T>(
    BuildContext context,
    String subject,
  ) {
    // For now, keep as regular navigation since it's a detailed view
    // In the future, we could implement a nested navigation structure
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => AllCardsViewScreen(subject: subject),
      ),
    );
  }

  static void navigateToCreateFlashcard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateFlashcardScreen(),
      ),
    );
  }

  static void navigateToCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  static void navigateToSyllabusScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SyllabusScannerScreen(),
      ),
    );
  }
}