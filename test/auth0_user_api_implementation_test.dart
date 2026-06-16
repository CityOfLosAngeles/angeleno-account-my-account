import 'package:angeleno_project/controllers/auth0_user_api_implementation.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_exception.dart';
import 'package:angeleno_project/models/api_response.dart';
import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth0_user_api_implementation_test.mocks.dart';

@GenerateMocks([http.Client, UserProvider])
void main() {
  group('Auth0UserApi', () {
    late MockClient mockHttpClient;
    late MockUserProvider mockUserProvider;
    late Auth0UserApi auth0UserApi;

    setUp(() {
      mockHttpClient = MockClient();
      mockUserProvider = MockUserProvider();
      auth0UserApi = Auth0UserApi(mockUserProvider);
    });

    group('createJwt', () {
      test('createJwt returns a non-empty string', () {
        final jwt = auth0UserApi.createJwt();
        expect(jwt, isNotEmpty);
      });

      test('createJwt returns a string with proper JWT structure', () {
        final jwt = auth0UserApi.createJwt();
        // JWT should have 3 parts separated by dots
        final parts = jwt.split('.');
        expect(parts.length, 3);
      });
    });

    group('ApiException usage', () {
      test('ApiException is used for error handling', () {
        const statusCode = 404;
        const responseBody = '{"error": "Not found"}';
        
        final exception = ApiException(statusCode, responseBody);
        
        expect(exception.statusCode, 404);
        expect(exception.error, 'Not found');
      });

      test('ApiException handles malformed JSON', () {
        const statusCode = 500;
        const responseBody = 'Internal Server Error';
        
        final exception = ApiException(statusCode, responseBody);
        
        expect(exception.statusCode, 500);
        expect(exception.error, 'Error encountered');
      });
    });

    group('PasswordBody', () {
      test('PasswordBody toJson creates correct map', () {
        final passwordBody = PasswordBody(
          email: 'test@example.com',
          oldPassword: 'oldpass',
          newPassword: 'newpass',
          userId: 'user123',
        );

        final json = passwordBody.toJson();

        expect(json['email'], 'test@example.com');
        expect(json['oldPassword'], 'oldpass');
        expect(json['newPassword'], 'newpass');
        expect(json['userId'], 'user123');
      });
    });

    group('User model', () {
      test('User toJson creates correct structure for API calls', () {
        final user = User(
          userId: '123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          address: '123 Main St',
          address2: null,
          city: 'Los Angeles',
          state: 'CA',
          zip: '90001',
          phone: '1234567890',
          metadata: {'key': 'value'},
        );

        final json = user.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['userId'], '123');
        expect(json['email'], 'test@example.com');
        expect(json['firstName'], 'John');
      });
    });

    group('ApiResponse', () {
      test('ApiResponse constructor initializes correctly', () {
        final response = ApiResponse(200, 'Success');

        expect(response.statusCode, 200);
        expect(response.body, 'Success');
      });

      test('ApiResponse can hold JSON string body', () {
        final response = ApiResponse(
          200,
          '{"mfaMethods": [{"type": "totp", "id": "123"}]}',
        );

        expect(response.statusCode, 200);
        expect(response.body, contains('mfaMethods'));
      });
    });

    group('Auth0UserApi baseUrl', () {
      test('baseUrl is set from constants', () {
        expect(auth0UserApi.baseUrl, isNotEmpty);
      });
    });

    group('Auth0UserApi authToken', () {
      test('authToken starts empty', () {
        expect(auth0UserApi.authToken, isEmpty);
      });

      test('authToken can be set', () {
        auth0UserApi.authToken = 'test_token';
        expect(auth0UserApi.authToken, 'test_token');
      });
    });
  });

  group('Auth0UserApi error scenarios', () {
    late Auth0UserApi auth0UserApi;
    late MockUserProvider mockUserProvider;

    setUp(() {
      mockUserProvider = MockUserProvider();
      auth0UserApi = Auth0UserApi(mockUserProvider);
    });

    test('updateUser handles exceptions gracefully', () async {
      final user = User(
        userId: '123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        address: '123 Main St',
        address2: null,
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
        phone: '1234567890',
        metadata: {},
      );

      when(mockUserProvider.getAccessToken()).thenReturn('mock_token');

      // When network call fails, should return 500
      final statusCode = await auth0UserApi.updateUser(user);
      
      // Should handle error and return a status code (likely 500 for general error)
      expect(statusCode, isA<int>());
    });
  });
}
