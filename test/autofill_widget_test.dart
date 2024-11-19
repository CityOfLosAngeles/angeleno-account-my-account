import 'package:angeleno_project/controllers/overlay_provider.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/main.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:angeleno_project/utils/constants.dart';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
//import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'mocks/auth0_user_api_mock.dart';

//@GenerateNiceMocks([MockSpec<Auth0UserApi>()])
//@GenerateMocks([KeyboardVisibilityController])
void main() {
//1)Let's forst simulate logging in to the screen
  late MockAuth0UserApi mockUserApi;
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register();
  //WidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockUserApi = MockAuth0UserApi();
  });

//2)Let's set the temp data from the User Provider
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

  final List<AutofillSuggestion> places = [
    AutofillSuggestion('333 S Hope St, Los Angeles, CA, USA',
        'ChIJEdCfy7LHwoARs9411harle4', '333 S Hope St'),
    AutofillSuggestion('333 South Beaudry Avenue, Los Angeles, CA, USA',
        ' ChIJ-wC9zhnHwoARS9PLhZNJR0M', '333 South Beaudry Avenue'),
    AutofillSuggestion('333 South Alameda Street, Los Angeles, CA, USA',
        'ChIJT8xhvTnGwoARq5cg5tquHVs', '333 South Alameda Street'),
    AutofillSuggestion('333 South Grand Avenue, Los Angeles, CA, USA',
        'ChIJPyEp0EzGwoARCLzP-AdLOsg', '333 South Grand Avenue'),
    AutofillSuggestion('333 South Catalina Street, Los Angeles, CA, USA',
        'ChIJScKIpWPHwoARr6s_WutyxS0', '333 South Catalina Street')
  ];

//Since we added the Typeahead widget, we need to add this to the unit test
//otherwise we'll get an error on this
  testWidgets('Keyboard testing', (WidgetTester tester) async {
    KeyboardVisibilityTesting.setVisibilityForTesting(true);
    //await tester.pumpWidget(MyApp());
    await tester.pump();
  });

  testWidgets('Displays and edits user', (final WidgetTester tester) async {
    const userUpdateMockResponse = 200;
/*
    // Mock fetchSuggestions to return filtered list
    final mockFetchSuggestions = (String search) async {
      return places
          .where((place) => place.description!.contains(search))
          .toList();
    };*/

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

    // Verify that the TyepAheadField search field is present
    expect(find.byType(TypeAheadField<AutofillSuggestion>), findsOneWidget);

/*
    // Enter '333' into the input field (simulate typing)
    final inputTextFieldFinder = find.byKey(const Key('AutofillWidget'));
    await tester.enterText(inputTextFieldFinder, '');
    await tester.enterText(inputTextFieldFinder, '333 S');
    //await tester.pump(); // Trigger the suggestion callback
    await tester
        .pumpAndSettle(); // Trigger the suggestion callback pumpAndSettle() to ensure all animations and asynchronous updates finish
*/
/*
    await tester.enterText(
        find.byType(TypeAheadField(
            itemBuilder: _, onSelected: _, suggestionsCallback: places)),
        '333');*/

    // Verify that the suggestions contain only relevant items
    //  expect(find.text('333 S Hope St'), findsOneWidget); // Should match '333 S'

    //  await tester.enterText(find.byType(TypeAheadField).at(0), places);
//await tester.
    //expect(, matcher)

//Simulate tapping on a suggestion

    // await tester.enterText(
    //   find.byType(TypeAheadField<AutofillSuggestion>).at(0), '');
    // await tester.pump();
  });
}
