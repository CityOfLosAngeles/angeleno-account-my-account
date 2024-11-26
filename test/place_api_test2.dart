import 'dart:convert';

import 'package:angeleno_project/controllers/place_api.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import 'mocks/place_api_test.mocks.dart';

// Manually create a mock class for http.Client
//class MockClient extends Mock implements http.Client {}

void main() {
  late MockClient mockHttpClient;
  late PlaceAPI placeAPI;
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
    mockHttpClient = MockClient();
    placeAPI = PlaceAPI('test_session_token', mockHttpClient);
    mockPlaceAPI = MockPlaceAPI();
    //placeAPI = PlaceAPI("");
  });

  group('PlaceAPI', () {
    test('mock client should not be null or empty', () {
      // Ensure that the client is properly set to the mock client and not null
      expect(placeAPI.client, isNotNull); // Check if the client is not null
      expect(placeAPI.client,
          equals(mockHttpClient)); // Ensure it's the mock client
    });

    test(
        'fetchSuggestions returns AutofillSuggestion list when response is successful',
        () async {
      // Mock a successful response with prediction data
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

      // Mock the http.get method with the specific Uri and headers

      /*
        // Construct the expected Uri for the given input and language
      final expectedUri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=paz&types=address&language=en&key=&sessiontoken=test_session_token');

  
      when(mockHttpClient.get(
        expectedUri,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => response);
      */
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => response);

      // Call the method being tested
      final result = await placeAPI.fetchSuggestions('paz', 'en');

      // Assertions to verify the expected outcome
      expect(result, isA<List<AutofillSuggestion>>());
      expect(result.length, 1);
      expect(result[0].placeId, '123');
      expect(result[0].description, 'Test Location');
    });
  });
/*
  test('fetchSuggestions uses mock client', () async {
    final mockClient = MockClient();
    final placeAPI = PlaceAPI('test_token', client: mockClient);
    final mockResponse =
        http.Response('{"status": "OK", "predictions": []}', 200);
    final expectedUri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=test&types=address&language=en&key=dummy_key&sessiontoken=test_token');

    when(mockClient.get(expectedUri, headers: anyNamed('headers')))
        .thenAnswer((_) async => Future.value(mockResponse));

    await placeAPI.fetchSuggestions('test', 'en');

    verify(mockClient.get(expectedUri, headers: anyNamed('headers'))).called(1);
  });

  */
}
