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

import 'mocks/place_api_test.mocks.dart';

void main() {
//1)Let's forst simulate logging in to the screen

  late MockPlaceAPI mockPlaceAPI;
  //final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  //binding.testTextInput.register();

//2)Let's set the temp data from the User Provider

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

  setUp(() {
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

    // Configure the mock to return the list of suggestions
    when(mockPlaceAPI.fetchSuggestions('333', 'en'))
        .thenAnswer((_) async => places);

    // Configure the mock to return the list of suggestions for EMPTY
    when(mockPlaceAPI.fetchSuggestions('paz', 'en'))
        .thenAnswer((_) async => []);

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
  });
}
