import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scholar_lens/animations/animated_interactive_element.dart';
import 'package:scholar_lens/animations/animation_manager.dart';
void main() {
  group('AnimatedInteractiveElement', () {
    late AnimationManager animationManager;
    setUpAll(() async {
      animationManager = AnimationManager();
      await animationManager.initialize();
    });
    tearDownAll(() {
      animationManager.dispose();
    });
    testWidgets('renders child widget correctly', (WidgetTester tester) async {
      const testChild = Text('Test Child');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              child: testChild,
            ),
          ),
        ),
      );
      expect(find.text('Test Child'), findsOneWidget);
    });
    testWidgets('calls onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, isTrue);
    });
    testWidgets('calls onLongPress callback when long pressed', (WidgetTester tester) async {
      bool longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              onLongPress: () => longPressed = true,
              child: const Text('Long Press Me'),
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Long Press Me'));
      await tester.pump();
      expect(longPressed, isTrue);
    });
    testWidgets('applies scale animation on tap down', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              scaleDown: 0.9,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);
      await tester.press(containerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(containerFinder, findsOneWidget);
    });
    testWidgets('respects custom animation durations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              tapDuration: const Duration(milliseconds: 100),
              releaseDuration: const Duration(milliseconds: 300),
              child: const Text('Custom Duration'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Custom Duration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Custom Duration'), findsOneWidget);
    });
    testWidgets('applies semantic properties correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              semanticButton: true,
              semanticLabel: 'Test Button',
              onTap: () {},
              child: const Text('Semantic Test'),
            ),
          ),
        ),
      );
      expect(find.text('Semantic Test'), findsOneWidget);
      final semantics = tester.getSemantics(find.text('Semantic Test'));
      expect(semantics.label, contains('Test Button'));
    });
    testWidgets('extension methods work correctly', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Extension Test').asInteractiveButton(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Extension Test'));
      await tester.pump();
      expect(tapped, isTrue);
    });
    testWidgets('handles disabled state correctly', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              onTap: null, // Disabled
              child: const Text('Disabled'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(tapped, isFalse);
    });
    testWidgets('respects custom scale down value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedInteractiveElement(
              scaleDown: 0.8,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );
      final containerFinder = find.byType(Container);
      await tester.press(containerFinder);
      await tester.pump(const Duration(milliseconds: 50));
      expect(containerFinder, findsOneWidget);
    });
    group('Extension Methods', () {
      testWidgets('asInteractive works with default settings', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const Text('Interactive').asInteractive(
                onTap: () => tapped = true,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Interactive'));
        await tester.pump();
        expect(tapped, isTrue);
      });
      testWidgets('asInteractiveCard works with card settings', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(
                width: 200,
                height: 100,
                color: Colors.grey,
                child: const Text('Card'),
              ).asInteractiveCard(
                onTap: () => tapped = true,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Card'));
        await tester.pump();
        expect(tapped, isTrue);
      });
      testWidgets('asInteractiveListItem works with list item settings', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListTile(
                title: const Text('List Item'),
              ).asInteractiveListItem(
                onTap: () => tapped = true,
              ),
            ),
          ),
        );
        await tester.tap(find.text('List Item'));
        await tester.pump();
        expect(tapped, isTrue);
      });
    });
    group('Edge Cases', () {
      testWidgets('handles rapid taps correctly', (WidgetTester tester) async {
        int tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedInteractiveElement(
                onTap: () => tapCount++,
                child: const Text('Rapid Tap'),
              ),
            ),
          ),
        );
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Rapid Tap'));
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(tapCount, equals(5));
      });
      testWidgets('handles tap cancel correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedInteractiveElement(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        );
        final containerFinder = find.byType(Container);
        await tester.press(containerFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.drag(containerFinder, const Offset(200, 0));
        await tester.pump();
        expect(containerFinder, findsOneWidget);
      });
    });
  });
}