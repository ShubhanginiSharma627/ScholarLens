import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('ScholarLens basic widget test', (WidgetTester tester) async {
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
    await tester.pump();
    expect(find.text('ScholarLens'), findsWidgets);
    expect(find.text('AI-Powered Multimodal Tutor'), findsOneWidget);
    expect(find.byIcon(Icons.school), findsOneWidget);
  });
}
