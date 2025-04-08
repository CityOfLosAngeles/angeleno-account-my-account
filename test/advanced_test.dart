import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_response.dart';
import 'package:angeleno_project/models/mfa_response.dart';
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

  testWidgets('Advanced Security - TOTP and SMS', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200,
    '{"mfaMethods": [{"type": "totp", "id": "123"}, {"type": "phone", "id": "456", "preferred_authentication_method": "sms", "phone_number": "2135432454"}]}');
    final disableAuthenticatorMockResponse = ApiResponse(200, '');
    final confirmAuthenticatorMockResponse = ApiResponse(200, '');

     final totpEnrollmentMockResponse = {
      'status': 200,
      'body': MfaResponse(
         barcode: 'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example',
         token: 'eyJhbG',
         barcodeString: 'totpString',
         oobCode: 'dasddasdasd'
       )
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

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
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

    // SMS Tests - Enabled
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
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
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

    // Voice Tests - Disabled state
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
  });

  testWidgets('Advanced Security - Voice', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200,
        '{"mfaMethods": [{"type": "phone", "id": "456", "preferred_authentication_method": "voice","phone_number": "2135432454"}],' +
            '"services": [{"clientId": "65165", "name": "Example", "scope": ["openid", "profile", "email"], "grantId": "123"}]}');

    final enrollMFAResponse = <String, dynamic> {
      'status': 200,
      'body': MfaResponse(
        barcode: 'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example',
        token: 'eyJhbG',
        barcodeString: 'totpString',
        oobCode: 'dasddasdasd'
      )
    };

    final disableAuthenticatorMockResponse = ApiResponse(200, '');
    final confirmAuthenticatorMockResponse = ApiResponse(200, '');

    when(mockUserApi.getAuthenticationMethods(any))
        .thenAnswer((_) async => authenticationMethodsMockResponse);

    when(mockUserApi.unenrollMFA(any))
        .thenAnswer((_) async => disableAuthenticatorMockResponse);

    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => enrollMFAResponse);

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

    // Voice
    await tester.tap(find.byKey( const Key('disableVoice')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byKey( const Key('disableVoice')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ok'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('enableVoice')), findsOneWidget);
    await tester.tap(find.byKey( const Key('enableVoice')));
    await tester.pumpAndSettle();

    expect(find.byType(MobileDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(MobileDialog), findsNothing);

    await tester.tap(find.byKey( const Key('enableVoice')));
    await tester.pumpAndSettle();

    final inputTextFieldFinder = find.byKey(const Key('phoneField'));
    await tester.enterText(inputTextFieldFinder, '2134325435');

    await tester.pumpAndSettle();
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

  testWidgets('Voice/SMS - wrong password', (final WidgetTester tester) async {

    final enrollMFAResponse = <String, dynamic> {
      'status': 400,
      'body': MfaResponse(
        errorMessage: 'An error occurred'
      )
    };

    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => enrollMFAResponse);

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

    expect(find.byKey(const Key('enableVoice')), findsOneWidget);
    await tester.tap(find.byKey( const Key('enableVoice')));
    await tester.pumpAndSettle();

    final inputTextFieldFinder = find.byKey(const Key('phoneField'));
    await tester.enterText(inputTextFieldFinder, '2134325435');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('passwordField')), 'wrongPassword');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    // await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text('An error occurred'), findsOneWidget);
  });

  testWidgets('Authenticator - wrong password', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200,
        '{"mfaMethods": []}');

    when(mockUserApi.getAuthenticationMethods(any))
        .thenAnswer((_) async => authenticationMethodsMockResponse);

    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => {
      'status': 404,
      'body': MfaResponse(
          errorMessage: 'Error found!'
      )
    });

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
    await tester.tap(find.byKey( const Key('enableAuthenticator')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'WrongPassword');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();


    expect(find.text('Error found!'), findsOneWidget);
  });

  testWidgets('Authenticator - additional MFA required', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200,
        '{"mfaMethods": [{"type": "phone", "id": "456", "preferred_authentication_method": "sms", "phone_number": "2135432454"}]}');

    when(mockUserApi.getAuthenticationMethods(any))
        .thenAnswer((_) async => authenticationMethodsMockResponse);

    when(mockUserApi.challengeMFA(any))
        .thenAnswer((_) async => ApiResponse(
        200,
        '{"oob_code": "123456"}'
    ));

    when(mockUserApi.requestMFAToken(any))
        .thenAnswer((_) async => ApiResponse(
        200,
        '{"access_token": "eymyaccesstoken"}'
      ));

    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => {
      'status': 401,
      'body': MfaResponse(
          token: 'eyJhbG...'
      )
    });

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
    await tester.tap(find.byKey( const Key('enableAuthenticator')));
    await tester.pumpAndSettle();


    expect(find.byType(Dialog), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'userPassword');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pump();

    expect(find.text('Please select an authentication method to verify your request:'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'SMS Message to 2135432454'));
    await tester.pump();

    expect(find.text('Enter the code sent to your phone:'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('additionalMfaCode')),'123456');


    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => {
      'status': 200,
      'body': MfaResponse(
          token: 'eyJhbG...',
          barcode: 'otpauth://totp/Example:',
          barcodeString: 'JBSWY3DPEHP',
          oobCode: 'dasddasdasd'
      )
    });

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Set up your authenticator by scanning code below:'), findsOneWidget);

  });

  testWidgets('Mobile - additional MFA required', (final WidgetTester tester) async {
    final authenticationMethodsMockResponse = ApiResponse(200,
        '{"mfaMethods": [{"type": "totp", "id": "123"}]}');

    when(mockUserApi.getAuthenticationMethods(any))
        .thenAnswer((_) async => authenticationMethodsMockResponse);

    when(mockUserApi.challengeMFA(any))
        .thenAnswer((_) async => ApiResponse(
        200,
        '{"oob_code": "123456"}'
    ));

    when(mockUserApi.requestMFAToken(any))
        .thenAnswer((_) async => ApiResponse(
        200,
        '{"access_token": "eymyaccesstoken"}'
    ));

    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => {
      'status': 401,
      'body': MfaResponse(
          token: 'eyJhbG...'
      )
    });

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

    expect(find.byKey(const Key('enableSMS')), findsOneWidget);
    await tester.tap(find.byKey( const Key('enableSMS')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);

    final inputTextFieldFinder = find.byKey(const Key('phoneField'));
    await tester.enterText(inputTextFieldFinder, '2134325435');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();


    await tester.enterText(find.byType(TextFormField), 'userPassword');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pump();

    expect(find.text('Please select an authentication method to verify your request:'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Authenticator (TOTP) application'));
    await tester.pump();

    expect(find.text('Enter the code provided by your Authenticator:'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('additionalMfaCode')),'123456');


    when(mockUserApi.enrollMFA(any))
        .thenAnswer((_) async => {
      'status': 200,
      'body': MfaResponse(
          token: 'eyJhbG...',
          oobCode: 'dasddasdasd'
      )
    });

    await tester.tap(find.widgetWithText(TextButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the code sent to 2134325435:'), findsOneWidget);

  });
}