import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/animations/modal_animations.dart';

void main() {
  group('Modal Animations Tests', () {
    testWidgets('ModalAnimations.showEnhancedModal displays modal correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalAnimations.showEnhancedModal(
                    context: context,
                    builder: (context) => const Text('Test Modal'),
                  );
                },
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Verify modal content is displayed
      expect(find.text('Test Modal'), findsOneWidget);
    });

    testWidgets('ModalAnimations.showEnhancedDialog displays dialog correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalAnimations.showEnhancedDialog(
                    context: context,
                    builder: (context) => const Text('Test Dialog'),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content is displayed
      expect(find.text('Test Dialog'), findsOneWidget);
    });

    testWidgets('ModalAnimations.showEnhancedAlertDialog displays alert dialog correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalAnimations.showEnhancedAlertDialog(
                    context: context,
                    title: const Text('Test Title'),
                    content: const Text('Test Content'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
                child: const Text('Show Alert'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show alert dialog
      await tester.tap(find.text('Show Alert'));
      await tester.pumpAndSettle();

      // Verify alert dialog content is displayed
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('BottomSheetAnimations.showEnhancedBottomSheet displays bottom sheet correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomSheetAnimations.showEnhancedBottomSheet(
                    context: context,
                    builder: (context) => const Text('Test Bottom Sheet'),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet content is displayed
      expect(find.text('Test Bottom Sheet'), findsOneWidget);
    });

    test('ModalAnimations.getWidgetPosition returns null for invalid key', () {
      final key = GlobalKey();
      final position = ModalAnimations.getWidgetPosition(key);
      expect(position, isNull);
    });

    test('ModalAnimationConfigs contains expected configurations', () {
      expect(ModalAnimationConfigs.defaultDuration, const Duration(milliseconds: 300));
      expect(ModalAnimationConfigs.fastDuration, const Duration(milliseconds: 200));
      expect(ModalAnimationConfigs.slowDuration, const Duration(milliseconds: 500));
      
      expect(ModalAnimationConfigs.defaultCurve, Curves.easeOutBack);
      expect(ModalAnimationConfigs.fastCurve, Curves.easeOut);
      expect(ModalAnimationConfigs.bouncyCurve, Curves.elasticOut);
    });
  });
}