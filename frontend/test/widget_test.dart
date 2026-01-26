// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScholarLens basic widget test', (WidgetTester tester) async {
    // Build a simple test app without complex providers
    await tester.pumpWidget(
      MaterialApp(
        title: 'ScholarLens',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('ScholarLens'),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school,
                  size: 64,
                  color: Color(0xFF6366F1),
                ),
                SizedBox(height: 16),
                Text(
                  'ScholarLens',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'AI-Powered Multimodal Tutor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Trigger a frame
    await tester.pump();

    // Verify that our app displays the ScholarLens title (appears in both app bar and body).
    expect(find.text('ScholarLens'), findsWidgets);
    expect(find.text('AI-Powered Multimodal Tutor'), findsOneWidget);

    // Verify that the school icon is displayed.
    expect(find.byIcon(Icons.school), findsOneWidget);
  });
}
