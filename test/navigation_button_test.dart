import 'package:angeleno_project/widgets/navigation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigationButton Widget', () {
    testWidgets('Renders correctly with required properties', (WidgetTester tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.home),
              text: const Text('Home'),
              onPressed: () {
                buttonPressed = true;
              },
              isActive: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.byType(NavigationButton));
      await tester.pumpAndSettle();

      expect(buttonPressed, true);
    });

    testWidgets('Displays icon and text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.settings),
              text: const Text('Settings'),
              onPressed: () {},
              isActive: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Triggers onPressed callback when tapped', (WidgetTester tester) async {
      var callbackInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.info),
              text: const Text('Info'),
              onPressed: () {
                callbackInvoked = true;
              },
              isActive: false,
            ),
          ),
        ),
      );

      expect(callbackInvoked, false);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(callbackInvoked, true);
    });

    testWidgets('Applies default background color when isActive is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.home),
              text: const Text('Active'),
              onPressed: () {},
              isActive: true,
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final backgroundColor = button.style?.backgroundColor?.resolve({});
      
      // When isActive is true, backgroundColor should be null (default)
      expect(backgroundColor, isNull);
    });

    testWidgets('Applies transparent background when isActive is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.home),
              text: const Text('Inactive'),
              onPressed: () {},
              isActive: false,
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final backgroundColor = button.style?.backgroundColor?.resolve({});
      
      expect(backgroundColor, Colors.transparent);
    });

    testWidgets('Button has correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.home),
              text: const Text('Test'),
              onPressed: () {},
              isActive: false,
            ),
          ),
        ),
      );

      final outerPadding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(Padding),
        ).first,
      );
      expect(outerPadding.padding, const EdgeInsets.fromLTRB(10, 0, 10, 0));
    });

    testWidgets('Button content has correct layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.person),
              text: const Text('Profile'),
              onPressed: () {},
              isActive: true,
            ),
          ),
        ),
      );

      // Verify Row exists with icon and text
      final row = find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Row),
      );
      expect(row, findsOneWidget);

      // Verify icon and text are children of the Row
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.person),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.text('Profile'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('SizedBox fills available width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationButton(
              icon: const Icon(Icons.home),
              text: const Text('Test'),
              onPressed: () {},
              isActive: false,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, double.infinity);
    });
  });
}
