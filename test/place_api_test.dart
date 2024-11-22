import 'package:angeleno_project/controllers/place_api.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
//import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks/profile_test.mocks.dart';

//dart run build_runner clean
//dart run build_runner build

@GenerateMocks([PlaceAPI])
void main() {
//1)Let's forst simulate logging in to the screen
  late MockPlaceAPI mockPlaceAPI;

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

  test('Counter value should be incremented', () async {
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
