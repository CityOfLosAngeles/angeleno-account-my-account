import 'package:angeleno_project/models/api_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResponse', () {
    test('Constructor initializes correctly with statusCode and body', () {
      final apiResponse = ApiResponse(200, 'Success');

      expect(apiResponse.statusCode, 200);
      expect(apiResponse.body, 'Success');
    });

    test('Constructor handles different status codes', () {
      final apiResponse404 = ApiResponse(404, 'Not Found');
      expect(apiResponse404.statusCode, 404);
      expect(apiResponse404.body, 'Not Found');

      final apiResponse500 = ApiResponse(500, 'Internal Server Error');
      expect(apiResponse500.statusCode, 500);
      expect(apiResponse500.body, 'Internal Server Error');
    });

    test('Constructor handles empty body', () {
      final apiResponse = ApiResponse(204, '');

      expect(apiResponse.statusCode, 204);
      expect(apiResponse.body, '');
    });

    test('ApiResponse implements Exception', () {
      final apiResponse = ApiResponse(400, 'Bad Request');

      expect(apiResponse, isA<Exception>());
    });

    test('Constructor handles JSON body strings', () {
      final apiResponse = ApiResponse(
        200,
        '{"message": "Success", "data": {"id": 123}}'
      );

      expect(apiResponse.statusCode, 200);
      expect(apiResponse.body, contains('message'));
      expect(apiResponse.body, contains('Success'));
    });
  });
}
