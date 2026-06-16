import 'package:angeleno_project/utils/error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessage Widget', () {
    testWidgets('Displays default error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(),
          ),
        ),
      );

      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('Displays custom error message', (WidgetTester tester) async {
      const customMessage = 'Custom error message';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: customMessage),
          ),
        ),
      );

      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('ErrorMessage uses error color from theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              error: Colors.red,
            ),
          ),
          home: const Scaffold(
            body: ErrorMessage(message: 'Test error'),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test error'));
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('ErrorMessage handles empty message', (WidgetTester tester) async {
      // Empty error message is allowed - component will render but display nothing
      // This can be useful for conditional error display
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: ''),
          ),
        ),
      );

      expect(find.text(''), findsOneWidget);
    });

    testWidgets('ErrorMessage handles long message', (WidgetTester tester) async {
      const longMessage = 'This is a very long error message that contains '
          'multiple words and should still be displayed correctly in the UI';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorMessage(message: longMessage),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
    });
  });
}
