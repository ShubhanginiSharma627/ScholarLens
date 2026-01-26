import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../lib/screens/profile_screen.dart';
import '../../lib/providers/providers.dart';
import '../../lib/models/models.dart';

void main() {
  group('ProfileScreen Tests', () {
    late AppStateProvider appStateProvider;

    setUp(() {
      appStateProvider = AppStateProvider();
    });

    testWidgets('ProfileScreen displays user information', (WidgetTester tester) async {
      // Initialize app state with test data
      await appStateProvider.initialize();
      await appStateProvider.setUserName('Test User');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppStateProvider>.value(
            value: appStateProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify profile screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Learning Metrics'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows edit button', (WidgetTester tester) async {
      await appStateProvider.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppStateProvider>.value(
            value: appStateProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify edit button is present
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('ProfileScreen shows logout button', (WidgetTester tester) async {
      await appStateProvider.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppStateProvider>.value(
            value: appStateProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify logout button is present
      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('ProfileScreen displays learning metrics', (WidgetTester tester) async {
      await appStateProvider.initialize();
      
      // Update progress with test data
      final testProgress = UserProgress.empty().copyWith(
        dayStreak: 5,
        topicsMastered: 3,
        questionsSolved: 25,
        studyHours: 2.5,
      );
      await appStateProvider.updateUserProgress(testProgress);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppStateProvider>.value(
            value: appStateProvider,
            child: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify metrics are displayed
      expect(find.text('5'), findsWidgets); // Day streak
      expect(find.text('3'), findsWidgets); // Topics mastered
      expect(find.text('25'), findsWidgets); // Questions solved
      expect(find.text('Day Streak'), findsOneWidget);
      expect(find.text('Topics Mastered'), findsOneWidget);
      expect(find.text('Questions Solved'), findsOneWidget);
      expect(find.text('Study Time'), findsOneWidget);
    });
  });
}