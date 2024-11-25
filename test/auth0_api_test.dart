import 'dart:io';
import 'package:angeleno_project/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'mocks/auth0_user_api_mock.dart';


class MockClient extends Mock implements http.Client {}

void main() {

  late MockAuth0UserApi mockUserApi;

  setUp(() {
    mockUserApi = MockAuth0UserApi();
  });

  test('updateUser returns status code 200 on success', () async {

    final user = User(
      userId: '123456',
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      address: '123 Main St',
      address2: 'Apt 2',
      city: 'City',
      state: 'State',
      zip: '12345',
      phone: '123-456-7890',
      metadata: {'key': 'value'}
    );

    when(mockUserApi.getOAuthToken()).thenAnswer((_) async => 'dummy_token');

    when(mockUserApi.updateUser(user))
        .thenAnswer((_) async =>
        200);

    final statusCode = await mockUserApi.updateUser(user);

    expect(statusCode, equals(HttpStatus.ok));
  });

}
