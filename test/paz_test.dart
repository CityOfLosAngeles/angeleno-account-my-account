import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/main.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:angeleno_project/views/screens/profile_screen.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:integration_test/integration_test.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'mocks/auth0_user_api_mock.dart';
import 'mocks/maps_autofill_api_test.mocks.dart';

void main() {
//1)Let's forst simulate logging in to the screen
  late MockAuth0UserApi mockUserApi;
  late MockPlaceAPI mockPlaceAPI;
  //final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  //binding.testTextInput.register();

//2)Let's set the temp data from the User Provider
  final userProvider = UserProvider();

  final List<AutofillSuggestion> places = [
    AutofillSuggestion('ChIJEdCfy7LHwoARs9411harle4',
        '333 S Hope St, Los Angeles, CA, USA', '333 S Hope St'),
    AutofillSuggestion(
        'ChIJ-wC9zhnHwoARS9PLhZNJR0M',
        '333 South Beaudry Avenue, Los Angeles, CA, USA',
        '333 South Beaudry Avenue'),
    AutofillSuggestion(
        'ChIJT8xhvTnGwoARq5cg5tquHVs',
        '333 South Alameda Street, Los Angeles, CA, USA',
        '333 South Alameda Street'),
    AutofillSuggestion(
        'ChIJPyEp0EzGwoARCLzP-AdLOsg',
        '333 South Grand Avenue, Los Angeles, CA, USA',
        '333 South Grand Avenue'),
    AutofillSuggestion(
        'ChIJScKIpWPHwoARr6s_WutyxS0',
        '333 South Catalina Street, Los Angeles, CA, USA',
        '333 South Catalina Street')
  ];

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

  setUp(() {
    mockUserApi = MockAuth0UserApi();
    mockPlaceAPI = MockPlaceAPI();
  });

  testWidgets('Keyboard testing', (final WidgetTester tester) async {
    KeyboardVisibilityTesting.setVisibilityForTesting(true);
    //await tester.pumpWidget(MyApp());
    await tester.pump();
  });

  testWidgets('YourClass widget test', (final WidgetTester tester) async {
    // 1. Set up the widget to be tested
    const userUpdateMockResponse = 200;

    when(mockUserApi.updateUser(any))
        .thenAnswer((_) async => userUpdateMockResponse);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider(create: (final _) => OverlayProvider())
        ],
        child: const MyApp(),
      ),
    );

    // Configure the mock to return the list of suggestions
    when(mockPlaceAPI.fetchSuggestions('333', 'en'))
        .thenAnswer((_) async => places);

    // Configure the mock to return the list of suggestions for EMPTY
    when(mockPlaceAPI.fetchSuggestions('paz', 'en'))
        .thenAnswer((_) async => []);

    // Verify that the TyepAheadField search field is present
    expect(find.byType(TypeAheadField<AutofillSuggestion>), findsOneWidget);
    await tester.enterText(
        find.byType(TypeAheadField<AutofillSuggestion>).at(0), '333');

    //final inputTextFieldFinder = find.byKey(const Key('AddressAutofillWidget'));
    // Ensure the widget is present before entering text
    //expect(inputTextFieldFinder, findsOneWidget);

    //await tester.enterText(inputTextFieldFinder, '333');
    await tester
        .pumpAndSettle(); // Wait for the suggestions to be loaded asynchronously

    // Log the widget tree for debugging
    print('Widget Tree after pumpAndSettle:');
    print(tester.takeException());

    // Check the widget tree after pumpAndSettle to see if the suggestions have been rendered
    //final suggestionText =
    // '333'; // Replace with the text you expect to be shown
    //final suggestionFinder = find.text(suggestionText);

    // print('Checking for suggestions...');
    // expect(
    //   suggestionFinder, findsOneWidget); // Ensure the suggestion is visible

    // 1. Call the fetchSuggestions method
    List<AutofillSuggestion> result =
        await mockPlaceAPI.fetchSuggestions('333', 'en');
    //print(result);

    // 2. Verify that the fetchSuggestions method was called with the expected arguments
    expect(result, isNotEmpty); //Check if the suggestions are not empty
    expect(result.length, 5); //Check if the suggestions is 5 as expected
    expect(
        result[1].description, //Confirm the description for 1 of them
        '333 South Beaudry Avenue, Los Angeles, CA, USA');

//Test for empty
    // result = await mockPlaceAPI.fetchSuggestions('paz', 'en');
    // print(result);

    print(tester.element(find.byKey(const Key('AddressAutofillWidget'))));
/*
    // Verify that suggestions are being shown (you can check that the suggestion items are visible)
    expect(find.byType(ListTile),
        findsWidgets); // Ensure that suggestions are present

    // Simulate tapping on the first suggestion item (e.g., ListTile)
    final firstSuggestionFinder = find.byType(ListTile).first;
    await tester.tap(firstSuggestionFinder);
    // Pump again to settle the tap event
    await tester.pumpAndSettle();
*/
/*
    // Find the ListTile corresponding to the suggestion you want to tap
    final suggestionFinder = find
        .descendant(
          of: inputTextFieldFinder,
          matching: find.byType(ListTile),
        )
        .first; // Assuming you want to tap the first suggestion

    // Tap on the suggestion
    await tester.tap(suggestionFinder);
    await tester.pumpAndSettle();*/

    // 3. Tap on the first suggestion
    // await tester.tap(find.text('333 S Hope St'));
    // await tester.pumpAndSettle(); // Wait for any UI updates to complete

    // 5. Verify that suggestions are displayed
    //expect(find.byType(ListTile),
    //  findsNWidgets(5)); // Assuming ListTile is used to display suggestions
  });
}
