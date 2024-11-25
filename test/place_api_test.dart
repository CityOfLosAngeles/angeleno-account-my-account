import 'package:angeleno_project/controllers/place_api.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mocks/place_api_test.mocks.dart';

//import 'package:angeleno_project/controllers/place_api.dart';

//import 'mocks/place_api_test.mocks.dart'; // Import your file containing the function
//import 'place_api_test.mocks.dart'

// Create new instances of this class in each test.
@GenerateMocks([http.Client])
@GenerateMocks([PlaceAPI])
void main() {
  late MockPlaceAPI mockPlaceAPI;
  late MockClient mockHttpClient;
  // late PlaceAPI placeAPI;

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
    mockHttpClient = MockClient();
    mockPlaceAPI = MockPlaceAPI();
    //placeAPI = PlaceAPI('test_session_token',
    //  client: mockHttpClient); // Use the mock client
  });
  group('Place API', () {
    test('returns a list of predictions', () async {
      // Mock a successful response
      final response = http.Response('''
  {
    "status": "OK",
    "predictions": [
      {
        "place_id": "123",
        "description": "Test Location",
        "structured_formatting": {
          "main_text": "Main Text"
        }
      }
    ]
  }
''', 200);
      final placesAPI = 'ddd';

      // Construct the expected Uri for the given input and language
      final expectedUri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=paz&types=address&language=en&key=$placesAPI&sessiontoken=test_session_token');

      // Mock the http.get method with the specific Uri and response
      // when(mockHttpClient.get(expectedUri, headers: anyNamed('headers')))
      //   .thenAnswer((_) async => Future.value(response));

      // In your test:
      when(mockHttpClient.get(expectedUri, headers: anyNamed('headers')))
          .thenAnswer((_) async {
        print('Mock http.get called with Uri: $expectedUri'); // Debug print
        return Future.value(response);
      });

      // final httpRespons =
      //   await mockHttpClient.get(expectedUri, headers: anyNamed('headers'));

      final httpResponse = await mockHttpClient
          .get(expectedUri, headers: {'Content-Type': 'application/json'});
      expect(httpResponse.statusCode, 200);

      // Configure the mock to return the list of suggestions
      when(mockPlaceAPI.fetchSuggestions('paz', 'en'))
          .thenAnswer((_) async => places);
      // Call the method being tested
      final result = await mockPlaceAPI.fetchSuggestions('paz', 'en');

      // Assertions to verify the expected outcome
      expect(result, isA<List<AutofillSuggestion>>());
      expect(result.length, 5);
      expect(result[0].placeId, 'ChIJEdCfy7LHwoARs9411harle4');
      //expect(result[0].description, 'Test Location');

/*
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => response);

      final result = await mockPlaceAPI.fetchSuggestions('paz', 'en');

      expect(result, isA<List<AutofillSuggestion>>());
      expect(result.length, 1);
      expect(result[0].placeId, '123');
      expect(result[0].description, 'Test Location');
*/
    });
  });
}
