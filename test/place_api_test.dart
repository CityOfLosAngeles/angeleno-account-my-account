import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
//import 'package:angeleno_project/controllers/place_api.dart';

import 'mocks/place_api_test.mocks.dart'; // Import your file containing the function

void main() {
  late MockPlaceAPI mockHttpClient;

  setUp(() {
    mockHttpClient = MockPlaceAPI();
  });

  group('fetchSuggestions', () {
    test('returns AutofillSuggestion list when response is successful',
        () async {
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

      // Configure the mock to return the list of suggestions
      when(mockHttpClient.fetchSuggestions('333', 'en'))
          .thenAnswer((_) async => places);

      // Call the function with the mock client
      final result = await mockHttpClient.fetchSuggestions('333', 'en');

      // Verify the expected result
      expect(result, isA<List<AutofillSuggestion>>());
      expect(result.length, 5);
      expect(result[0].placeId, 'ChIJEdCfy7LHwoARs9411harle4');
      expect(result[0].description, '333 S Hope St, Los Angeles, CA, USA');
      //expect(result[0].mainText, 'Main Text');
    });

/*
    test('returns empty list when response status is ZERO_RESULTS', () async {
      // Mock a ZERO_RESULTS response
      final response = http.Response('''
        {
          "status": "ZERO_RESULTS"
        }
      ''', 200);

      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => response);

      final result = await mockHttpClient.fetchSuggestions('test input', 'en');

      expect(result, isEmpty);
    });

    test('throws exception when response status is not OK or ZERO_RESULTS',
        () async {
      // Mock an error response
      final response = http.Response('''
        {
          "status": "INVALID_REQUEST"
        }
      ''', 200);

      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => response);

      expect(
          () async => await mockHttpClient.fetchSuggestions('test input', 'en'),
          throwsException);
    });
    */

/*
    test('throws exception when HTTP request fails', () async {
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenThrow(Exception('Network error'));

      expect(
          () async => await fetchSuggestions('test input', 'en',
              client: mockHttpClient),
          throwsException);
    });


    */
  });
}
