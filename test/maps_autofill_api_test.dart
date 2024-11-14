import 'package:angeleno_project/controllers/place_api.dart';
import 'package:angeleno_project/models/autofill_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'mocks/maps_autofill_api_test.mocks.dart';

//Command to initiate test
//flutter test test/maps_autofill_api_test.dart

@GenerateMocks([PlaceAPI])
//@GenerateNiceMocks([MockSpec<PlaceAPI>()])
void main() {
  group('fetchAddress', () {
    //1st test, get suggestions
    test('Testing to receive the suggestions', () async {
      final client = MockPlaceAPI();
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

      when(client.fetchSuggestions('333', 'en'))
          .thenAnswer((_) async => places);

      expect(await client.fetchSuggestions('333', 'en'),
          isA<List<AutofillSuggestion>>());
    });

//test#2 test api GetPlace
  });
}
