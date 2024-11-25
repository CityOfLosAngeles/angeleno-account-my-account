import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/place_api.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/main.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:angeleno_project/views/screens/password_screen.dart';
import 'package:angeleno_project/views/screens/profile_screen.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'mocks/auth0_user_api_mock.dart';
import 'mocks/place_api_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Auth0UserApi>()])
void main() {
  late MockAuth0UserApi mockUserApi;
  late MockPlaceAPI mockPlaceAPI;
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register();

  setUp(() {
    mockUserApi = MockAuth0UserApi();
    mockPlaceAPI = MockPlaceAPI();
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
          'phone': '(213) 555-5555'
        }
      });
  userProvider.setUser(auth0User);

  test('Testing AuotfillSuggestions FXs', () async {
    print('testing fx');
    const input = 'Lon';
    final suggestions = [
      AutofillSuggestion('1', 'London, UK', 'Some Street'),
      AutofillSuggestion('0', 'Paris, France', 'Another Street'),
    ];

    // Provide a BuildContext to your function (without modifying it)
    Future<List<AutofillSuggestion>> fetchSuggestionsWithMockContext(
        // ignore: prefer_expression_function_bodies
        final String input) async {
      return mockPlaceAPI.fetchSuggestions(
          input, 'en'); // Call the original function
    }

    // Configure the mock to return the list of suggestions
    when(mockPlaceAPI.fetchSuggestions(
            input, 'en')) // Assuming 'en' is the language code
        .thenAnswer((final _) async => suggestions);

    final fetchedSuggestions = await fetchSuggestionsWithMockContext(input);

    // Verify that the API client's fetchSuggestions method was called with the correct arguments
    verify(mockPlaceAPI.fetchSuggestions(input, 'en')).called(1);
    // Verify the returned suggestions list
    expect(fetchedSuggestions, isNotEmpty);
    expect(fetchedSuggestions, suggestions);

    // Verify that the API client's count is incremented
    //expect(mockPlaceAPI.count, 1);
  });

//Since we added the Typeahead widget, we need to add this to the unit test
//otherwise we'll get an error on this
  testWidgets('Setting keyboard Globally Implementation',
      (final WidgetTester tester) async {
    KeyboardVisibilityTesting.setVisibilityForTesting(true);
    await tester.pump();
  });

  testWidgets('Displays and edits user', (final WidgetTester tester) async {
    const userUpdateMockResponse = 200;

    when(mockUserApi.updateUser(any))
        .thenAnswer((final _) async => userUpdateMockResponse);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider(create: (final _) => OverlayProvider())
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('First Name'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(userProvider.isEditing, true);

    await tester.enterText(find.byType(TextFormField).at(0), 'New First Name');
    await tester.enterText(find.byType(TextFormField).at(1), 'New Last Name');
    final inputTextFieldFinder = find.byKey(const Key('phoneField'));
    await tester.enterText(inputTextFieldFinder, '');
    await tester.enterText(inputTextFieldFinder, '2134325435');
    await tester.enterText(find.byType(TextFormField).at(3), 'New Address 2');
    await tester.enterText(find.byType(TextFormField).at(4), 'New City');
    await tester.enterText(find.byType(TextFormField).at(5), 'New State');
    await tester.enterText(find.byType(TextFormField).at(6), 'New Zip');

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.pump();
    final firstNameError = find.text('Please enter a first name');
    expect(firstNameError, findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'New First Name');
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(1), '');
    await tester.pump();
    final lastNameError = find.text('Please enter a last name');
    expect(lastNameError, findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'New Last Name');
    await tester.pump();

    // Dialog preventing user from leaving while editing
    await tester.tap(find.byKey(const Key('menuButton')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.ensureVisible(find.byIcon(Icons.password));
    await tester.tap(find.byIcon(Icons.password));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(ElevatedButton),
      const Offset(-250, 0),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(userProvider.isEditing, false);
    expect(userProvider.user!.firstName, 'New First Name');
    expect(userProvider.user!.lastName, 'New Last Name');
    expect(userProvider.user!.phone, '+12134325435');
    //  expect(userProvider.user!.address, 'New Address');
    expect(userProvider.user!.address2, 'New Address 2');
    expect(userProvider.user!.city, 'New City');
    expect(userProvider.user!.state, 'New State');
    expect(userProvider.user!.zip, 'New Zip');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Dialog with user intention of leaving while editing
    await tester.tap(find.byKey(const Key('menuButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.password));
    await tester.tap(find.byIcon(Icons.password));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Ok'));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordScreen), findsOneWidget);
  });
}
