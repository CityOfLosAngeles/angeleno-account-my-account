import 'package:angeleno_project/utils/base_mfa_dialog_state.dart';
import 'package:angeleno_project/utils/error_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Concrete implementation for testing the abstract class
class TestDialog extends StatefulWidget {
  const TestDialog({super.key});

  @override
  State<TestDialog> createState() => _TestDialogState();
}

class _TestDialogState extends BaseDialogState<TestDialog> {
  @override
  Widget get dialogBody => const Text('Test Body');

  @override
  List<Widget> get dialogNext => [
    TextButton(
      onPressed: () {
        navigateToNextPage();
      },
      child: const Text('Next'),
    ),
    TextButton(
      onPressed: () {},
      child: const Text('Finish'),
    ),
  ];
}

void main() {
  group('BaseDialogState', () {
    testWidgets('Initial state has correct default values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));

      expect(state.pageIndex, 0);
      expect(state.errorMessage, '');
      expect(state.obscurePassword, true);
      expect(state.inFlightRequest, false);
      expect(state.authenticators, isEmpty);
      expect(state.requireAdditionalAuthentication, false);
      expect(state.methodBeingEnrolled, '');
    });

    testWidgets('navigateToNextPage increments pageIndex', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));
      expect(state.pageIndex, 0);

      state.navigateToNextPage();
      await tester.pumpAndSettle();

      expect(state.pageIndex, 1);
    });

    testWidgets('Cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => const TestDialog(),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(TestDialog), findsOneWidget);

      // Find and tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TestDialog), findsNothing);
    });

    testWidgets('Back button decrements pageIndex', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));
      
      // Navigate to page 1
      state.navigateToNextPage();
      await tester.pumpAndSettle();
      expect(state.pageIndex, 1);

      // Click back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(state.pageIndex, 0);
    });

    testWidgets('Back button also resets inFlightRequest', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));
      
      // Navigate to page 1 and set inFlightRequest
      state.navigateToNextPage();
      state.inFlightRequest = true;
      await tester.pumpAndSettle();

      expect(state.inFlightRequest, true);

      // Click back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(state.inFlightRequest, false);
    });

    testWidgets('Shows dialog body', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('Shows AlertDialog on large screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Shows fullscreen Dialog on small screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('passwordField controller is properly initialized', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));
      expect(state.passwordField, isNotNull);
      expect(state.passwordField.text, isEmpty);
    });

    testWidgets('passwordField controller is disposed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));
      final controller = state.passwordField;

      // Remove widget to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      
      // Controller should be disposed
      expect(() => controller.text, throwsFlutterError);
    });

    testWidgets('dialogActions contains Cancel and Next buttons on first page', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('dialogActions contains Cancel, Back and next button on subsequent pages', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestDialog(),
        ),
      );

      final state = tester.state<_TestDialogState>(find.byType(TestDialog));
      state.navigateToNextPage();
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });
  });

  group('BaseDialogState passwordPrompt', () {
    // Create a custom dialog to test passwordPrompt
    class PasswordPromptDialog extends StatefulWidget {
      const PasswordPromptDialog({super.key});

      @override
      State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
    }

    class _PasswordPromptDialogState extends BaseDialogState<PasswordPromptDialog> {
      bool onSubmitCalled = false;

      @override
      Widget get dialogBody => passwordPrompt(
        'Enter your password',
        () {
          onSubmitCalled = true;
        },
      );

      @override
      List<Widget> get dialogNext => [];
    }

    testWidgets('passwordPrompt displays prompt text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('passwordPrompt shows password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('passwordPrompt field is obscured by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.obscureText, true);
    });

    testWidgets('toggle password visibility button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      final state = tester.state<_PasswordPromptDialogState>(
        find.byType(PasswordPromptDialog)
      );
      expect(state.obscurePassword, true);

      await tester.tap(find.byKey(const Key('toggle_password')));
      await tester.pumpAndSettle();

      expect(state.obscurePassword, false);

      await tester.tap(find.byKey(const Key('toggle_password')));
      await tester.pumpAndSettle();

      expect(state.obscurePassword, true);
    });

    testWidgets('passwordPrompt calls onSubmit when form is submitted', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      final state = tester.state<_PasswordPromptDialogState>(
        find.byType(PasswordPromptDialog)
      );
      expect(state.onSubmitCalled, false);

      // Enter text and submit
      await tester.enterText(find.byType(TextFormField), 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(state.onSubmitCalled, true);
    });

    testWidgets('passwordPrompt validates empty password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      
      // Validate with empty value
      final errorEmpty = textField.validator!('');
      expect(errorEmpty, 'Password is required');

      // Validate with whitespace only
      final errorWhitespace = textField.validator!('   ');
      expect(errorWhitespace, 'Password is required');

      // Validate with null
      final errorNull = textField.validator!(null);
      expect(errorNull, 'Password is required');

      // Validate with valid password
      final errorValid = textField.validator!('password123');
      expect(errorValid, isNull);
    });

    testWidgets('passwordPrompt shows error message when set', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PasswordPromptDialog(),
        ),
      );

      final state = tester.state<_PasswordPromptDialogState>(
        find.byType(PasswordPromptDialog)
      );

      // Initially no error
      expect(find.byType(ErrorMessage), findsNothing);

      // Set error message
      state.setState(() {
        state.errorMessage = 'Invalid password';
      });
      await tester.pumpAndSettle();

      expect(find.text('Invalid password'), findsOneWidget);
    });
  });
}
