import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_response.dart';
import 'package:angeleno_project/views/dialogs/mobile.dart';
import 'package:angeleno_project/views/screens/advanced_security_screen.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'mocks/auth0_user_api_mock.dart';

@GenerateNiceMocks([MockSpec<Auth0UserApi>()])
void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('Advanced Security', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200, 
    '{"mfaMethods": [{"type": "totp", "id": "123"}, {"type": "phone", "id": "456", "preferred_authentication_method": "sms"}]}');
    final disableAuthenticatorMockResponse = ApiResponse(200, '');
    final confirmAuthenticatorMockResponse = ApiResponse(200, '');

     final totpEnrollmentMockResponse = {
      'status': 200,
      'token': 'eyJhbG',
      'authenticator_type': 'otp', 
      'secret': 'NQ4FGVKEMQWGIRZVJFSE2STEKN4UQKCD', 
      'barcode': 'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example',
      'barcode_string': 'totpString',
      'oobCode': 'dasddasdasd'
    };

    when(mockUserApi.getAuthenticationMethods(any))
        .thenAnswer((_) async => authenticationMethodsMockResponse);

    when(mockUserApi.unenrollMFA(any))
        .thenAnswer((_) async => disableAuthenticatorMockResponse);

    when(mockUserApi.enrollMFA(any))
      .thenAnswer((_) async => totpEnrollmentMockResponse);

    when(mockUserApi.confirmMFA(any))
      .thenAnswer((_) async => confirmAuthenticatorMockResponse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedSecurityScreen(
              userProvider: userProvider,
              auth0UserApi: mockUserApi
          ),
        )
      ),
    );

    await tester.pumpAndSettle();
    verify(mockUserApi.getAuthenticationMethods(any)).called(1);

    // Mock response has Authenticator enabled
    // so the UI should reflect disable button
    expect(find.byKey(const Key('disableAuthenticator')), findsOneWidget);
    await tester.tap(find.byKey( const Key('disableAuthenticator')));

    await tester.pumpAndSettle();

    // Opens dialog and closes it on Cancel
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // Disables Authenticator
    await tester.tap(find.byKey( const Key('disableAuthenticator')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ok'));
    await tester.pumpAndSettle();

    // Should find the button to enable Authenticator
    expect(find.byKey(const Key('enableAuthenticator')), findsOneWidget);
    await tester.tap(find.byKey( const Key('enableAuthenticator')));
    await tester.pumpAndSettle();

    // Enrollment Dialog
    expect(find.byType(Dialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(MobileDialog), findsNothing);

    await tester.tap(find.byKey( const Key('enableAuthenticator')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'userPassword');

    final authenticatorPasswordFinder = find.descendant(
      of: find.byKey(const Key('passwordField')),
      matching: find.byType(TextField),
    );

    final authenticatorPasswordField = tester.firstWidget<TextField>(authenticatorPasswordFinder);
    expect(authenticatorPasswordField.obscureText, true);

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle_password')));
    await tester.pump();
    // ignore: lines_longer_than_80_chars
    final refreshAuthenticatorPasswordField = tester.firstWidget<TextField>(authenticatorPasswordFinder);
    expect(refreshAuthenticatorPasswordField.obscureText, false);

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('totpCode')), '123456');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Finish'));
    await tester.pumpAndSettle();

    // Snackbar on successful enrollment
    expect(find.byType(SnackBar), findsOneWidget);
    // Authenticator has been re-enabled so we should see the disable button
    expect(find.byKey(const Key('disableAuthenticator')), findsOneWidget);


    // SMS Tests
    expect(find.byKey(const Key('disableSMS')), findsOneWidget);
    await tester.tap(find.byKey( const Key('disableSMS')));

    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byKey( const Key('disableSMS')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ok'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pumpAndSettle();
    
    expect(find.byKey(const Key('enableSMS')), findsOneWidget);
    await tester.tap(find.byKey( const Key('enableSMS')));
    await tester.pumpAndSettle();

    expect(find.byType(MobileDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(MobileDialog), findsNothing);

    await tester.tap(find.byKey( const Key('enableSMS')));
    await tester.pumpAndSettle();

    final inputTextFieldFinder = find.byKey(const Key('phoneField'));
    await tester.enterText(inputTextFieldFinder, '2134325435');

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('passwordField')), 'myPassword');

    final phonePasswordFinder = find.descendant(
      of: find.byKey(const Key('passwordField')),
      matching: find.byType(TextField),
    );

    final phonePasswordField = tester.firstWidget<TextField>(phonePasswordFinder);
    expect(phonePasswordField.obscureText, true);

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle_password')));
    await tester.pump();
    // ignore: lines_longer_than_80_chars
    final refreshPhonePasswordField = tester.firstWidget<TextField>(phonePasswordFinder);
    expect(refreshPhonePasswordField.obscureText, false);

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('phoneCode')), '483234');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byKey(const Key('disableSMS')), findsOneWidget);

    // Voice Tests
    expect(find.byKey(const Key('enableVoice')), findsOneWidget);
    await tester.tap(find.byKey( const Key('enableVoice')));

    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(const Size(400, 600));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpAndSettle();
    expect(find.byType(MobileDialog), findsOneWidget);

    await tester.enterText(inputTextFieldFinder, '2134325435');

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('passwordField')), 'myPassword');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('phoneCode')), '483234');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byKey(const Key('disableVoice')), findsOneWidget);

  });

  testWidgets('Advanced Security - Voice', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200,
        '{"mfaMethods": [{"type": "phone", "id": "456", "preferred_authentication_method": "voice"}],' +
            '"services": [{"clientId": "65165", "name": "Example", "scope": ["openid", "profile", "email"], "grantId": "123"}]}');

    final disableAuthenticatorMockResponse = ApiResponse(200, '');
    final confirmAuthenticatorMockResponse = ApiResponse(200, '');

    when(mockUserApi.getAuthenticationMethods(any))
        .thenAnswer((_) async => authenticationMethodsMockResponse);

    when(mockUserApi.unenrollMFA(any))
        .thenAnswer((_) async => disableAuthenticatorMockResponse);

    when(mockUserApi.confirmMFA(any))
        .thenAnswer((_) async => confirmAuthenticatorMockResponse);

    when(mockUserApi.removeConnection(any))
        .thenAnswer((_) => Future.value(ApiResponse(200, '')));

    await tester.pumpWidget(
      MaterialApp(
          home: Scaffold(
            body: AdvancedSecurityScreen(
                userProvider: userProvider,
                auth0UserApi: mockUserApi
            ),
          )
      ),
    );

    await tester.pumpAndSettle();
    verify(mockUserApi.getAuthenticationMethods(any)).called(1);

    expect(find.byKey(const Key('enableAuthenticator')), findsOneWidget);
    expect(find.byKey(const Key('enableSMS')), findsOneWidget);
    expect(find.byKey(const Key('disableVoice')), findsOneWidget);

    await tester.tap(find.byKey(const Key('disconnect_123')));
    await tester.pumpAndSettle();
    
    expect(find.byType(AlertDialog), findsOneWidget);
    
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    
    expect(find.byType(AlertDialog), findsNothing);
    
    await tester.tap(find.byKey(const Key('disconnect_123')));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byKey(const Key('disconnect_123')), findsNothing);

  });
}