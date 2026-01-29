import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../lib/widgets/common/modern_form_card.dart';
import '../../lib/widgets/common/form_divider.dart';
import '../../lib/widgets/common/modern_button.dart';
import '../../lib/providers/authentication_provider.dart';
import '../../lib/theme/app_theme.dart';

void main() {
  group('Modern Auth UI Components', () {
    testWidgets('ModernFormCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ModernFormCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(ModernFormCard), findsOneWidget);
    });

    testWidgets('FormDivider renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FormDivider(),
          ),
        ),
      );

      expect(find.text('OR CONTINUE WITH'), findsOneWidget);
      expect(find.byType(FormDivider), findsOneWidget);
    });

    testWidgets('ModernButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ModernButton.primary(
              text: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ModernButton), findsOneWidget);
    });

    testWidgets('ModernButton shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ModernButton.primary(
              text: 'Test Button',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test Button'), findsNothing);
    });
  });
}