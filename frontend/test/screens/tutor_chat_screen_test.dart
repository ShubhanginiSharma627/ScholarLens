import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/screens/tutor_chat_screen.dart';
import '../../lib/providers/chat_provider.dart';
import '../../lib/models/chat_message.dart';

void main() {
  group('TutorChatScreen', () {
    late ChatProvider chatProvider;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      chatProvider = ChatProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<ChatProvider>.value(
          value: chatProvider,
          child: const TutorChatScreen(),
        ),
      );
    }

    testWidgets('displays empty state when no messages', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('Start a conversation'), findsOneWidget);
      expect(find.text('Ask me anything about your studies!'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('displays chat input bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show input field and buttons
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask me anything...'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('displays app bar with title and menu', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show app bar
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows loading state during initialization', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('can enter text in input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.tap(textField);
      await tester.enterText(textField, 'Hello AI tutor');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Hello AI tutor'), findsOneWidget);
    });

    testWidgets('displays messages when chat history exists', (tester) async {
      // Add some test messages to the provider
      final userMessage = ChatMessage.user(content: 'Hello');
      final aiMessage = ChatMessage.ai(content: 'Hi there! How can I help?');
      
      await chatProvider.addMessage(userMessage);
      await chatProvider.addMessage(aiMessage);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show messages
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi there! How can I help?'), findsOneWidget);
      
      // Should not show empty state
      expect(find.text('Start a conversation'), findsNothing);
    });

    testWidgets('shows menu options when menu button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Should show menu items
      expect(find.text('Clear Chat'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('send button is disabled when text is empty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find send button - it should be grey when no text
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
      
      // The button container should have grey color when disabled
      final container = tester.widget<Container>(
        find.ancestor(
          of: sendButton,
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(equals(Colors.blue))); // Should not be primary color
    });
  });
}