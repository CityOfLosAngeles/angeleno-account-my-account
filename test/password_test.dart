import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/views/screens/password_screen.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'mocks/auth0_user_api_mock.dart';


void main() {

  late MockAuth0UserApi mockUserApi;

  setUp(() {
    mockUserApi = MockAuth0UserApi();
  });

  final userProvider = UserProvider();
  const auth0User = UserProfile(
    sub: 'auth0|id',
    email: 'user@email.com',
    givenName: 'FirstName',
    familyName: 'LastName',
    customClaims: {
      'user_metadata': {
        'addresses': {
          'primary': {
            'address': '123 Main St',
            'address2': 'Suite 200',
            'city': 'Main City',
            'state': 'Main State',
            'zip': '12345'
          }
        },
        'phone': '(555) 555-5555'
      }
    }
  );
  userProvider.setUser(auth0User);
  testWidgets('Password', (final WidgetTester tester) async {
    
    final passwordUpdateMockResponse = {
      'status': 500,
      'body': 'Expected Failure'
    };
    
    when(mockUserApi.updatePassword(any))
        .thenAnswer((_) async => passwordUpdateMockResponse);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider(create: (final _) => OverlayProvider())
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PasswordScreen(auth0UserApi: mockUserApi)
          )
        )
      )
    );

    expect(find.text('Current Password'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);

    final submitButtonFinder = find.byType(ElevatedButton);
    expect(submitButtonFinder, findsOneWidget);
    expect(tester.widget<ElevatedButton>(submitButtonFinder).enabled, false);

    await tester.enterText(find.byType(TextFormField).at(0), 'oldPassword');
    await tester.enterText(find.byType(TextFormField).at(1), 'newPassword123');
    await tester.enterText(find.byType(TextFormField).at(2), 'newPassword123');

    await tester.pump();
    expect(tester.widget<ElevatedButton>(submitButtonFinder).enabled, true);

    // Current Password
    final oldPasswordFinder = find.descendant(
      of: find.byKey(const Key('old_password')),
      matching: find.byType(TextField),
    );

    final oldPasswordField = tester.firstWidget<TextField>(oldPasswordFinder);
    expect(oldPasswordField.obscureText, true);

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle_old_password')));
    await tester.pump();
    // ignore: lines_longer_than_80_chars
    final refreshOldPasswordField = tester.firstWidget<TextField>(oldPasswordFinder);
    expect(refreshOldPasswordField.obscureText, false);

    // New Password
    final newPasswordFinder = find.descendant(
      of: find.byKey(const Key('new_password')),
      matching: find.byType(TextField),
    );

    final newPasswordField = tester.firstWidget<TextField>(newPasswordFinder);
    expect(newPasswordField.obscureText, true);

    await tester.tap(find.byKey(const Key('toggle_new_password')));
    await tester.pump();
    final refreshNewPasswordField = tester
      .firstWidget<TextField>(newPasswordFinder);
    expect(refreshNewPasswordField.obscureText, false);


    // Password match
    final matchPasswordFinder = find.descendant(
      of: find.byKey(const Key('match_password')),
      matching: find.byType(TextField),
    );

    final matchPasswordField = tester
      .firstWidget<TextField>(matchPasswordFinder);
    expect(matchPasswordField.obscureText, true);

    await tester.tap(find.byKey(const Key('toggle_match_password')));
    await tester.pump();
    final refreshMatchPasswordField = tester
      .firstWidget<TextField>(matchPasswordFinder);
    expect(refreshMatchPasswordField.obscureText, false);

    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Expected Failure'), findsOneWidget);

  });
}