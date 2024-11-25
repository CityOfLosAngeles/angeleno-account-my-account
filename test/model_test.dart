import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_exception.dart';
import 'package:angeleno_project/models/connected_applications_model.dart';
import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  late UserProvider userProvider;

  setUp(() {
    userProvider = UserProvider();
  });

  group('ApiException', () {
    test('Should return error message from JSON body', () {
      const int statusCode = 404;
      const String responseBody = '{"error": "Resource not found"}';
      final ApiException apiException = ApiException(statusCode, responseBody);

      final error = apiException.error;

      expect(error, 'Resource not found');
    });

    test('Should return default error message when JSON decoding fails', () {
      const int statusCode = 500;
      const String responseBody = 'Internal Server Error';
      final ApiException apiException = ApiException(statusCode, responseBody);

      final error = apiException.error;

      expect(error, 'Error encountered');
    });

    test('Should return default error message when body is null', () {

      const int statusCode = 400;
      final ApiException apiException = ApiException(statusCode, null);

      final error = apiException.error;

      expect(error, 'Error encountered');
    });

    test('Should return error message when body contains error in body', () {

      const int statusCode = 418;
      const String responseBody = '{"error": "I\'m a teapot"}';
      final ApiException apiException = ApiException(statusCode, responseBody);

      final error = apiException.error;

      expect(error, "I'm a teapot");
    });
  });

  group('PasswordBody', () {
    test('toJson() should return a valid map', () {
      // Arrange
      final passwordBody = PasswordBody(
        email: 'test@example.com',
        oldPassword: 'oldPassword123',
        newPassword: 'newPassword456',
        userId: '123456789',
      );

      // Act
      final json = passwordBody.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['email'], 'test@example.com');
      expect(json['oldPassword'], 'oldPassword123');
      expect(json['newPassword'], 'newPassword456');
      expect(json['userId'], '123456789');
    });
  });

  group('User', () {

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
      metadata: {'key': 'value'},
    );
    test('toJson() should return a valid map', () {

      final json = user.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['userId'], '123456');
      expect(json['email'], 'test@example.com');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['address'], '123 Main St');
      expect(json['address2'], 'Apt 2');
      expect(json['city'], 'City');
      expect(json['state'], 'State');
      expect(json['zip'], '12345');
      expect(json['phone'], '123-456-7890');
      expect(json['metadata'], {'key': 'value'});
    });

    test('toString() should return a valid string representation', () {

      final stringRep = user.toString();
      
      // ignore: lines_longer_than_80_chars
      expect(stringRep, '{id: 123456, email: test@example.com, firstName: John, lastName: Doe, zip: 12345, address: 123 Main St, address2: Apt 2, city: City, state: State, phone: 123-456-7890}');
    });

    test('User copy method should work correctly', () {
      final userCopy = User.copy(user);

      expect(userCopy, equals(user));
    });

    test('Equality comparison should work correctly', () {

      final user1 = User(
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
        metadata: {'key': 'value'},
      );

      final user2 = User(
        userId: '123456',
        email: 'test@example.com',
        firstName: 'Karen',
        lastName: 'Doe',
        address: '123 Main St',
        address2: 'Apt 2',
        city: 'City',
        state: 'State',
        zip: '12345',
        phone: '123-456-7890',
        metadata: {'key': 'value'},
      );

      expect(user1, equals(user));
      expect(user1, isNot(equals(user2)));
    });

    test('Hash code calculation should work correctly', () {

      final user1 = User(
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
        metadata: {'key': 'value'},
      );

      expect(user1.hashCode, equals(user.hashCode));
    });
  });

  group('UserProvider', () {
    test('setCleanUser sets clean user correctly', () {
      final user = User(
        userId: 'testId',
        email: 'testEmail',
        firstName: 'testFirstName',
        lastName: 'testLastName',
        zip: 'testZip',
        address: 'testAddress',
        address2: 'testAddress2',
        city: 'testCity',
        state: 'testState',
        phone: 'testPhone',
        metadata: {},
      );

      userProvider.setCleanUser(user);

      expect(userProvider.cleanUser, equals(user));
    });

  });

  group('Service', () {
    test('fromJson creates correct Service object', () {
      final json = {
        'clientId': '123',
        'name': 'Test Service',
        'scope': ['email', 'openid', 'profile'],
        'logo_uri': 'https://example.com/logo.png',
        'grantId': '456'
      };

      final service = Service.fromJson(json);

      expect(service.id, '123');
      expect(service.name, 'Test Service');
      expect(service.scope, ['email', 'profile']);
      expect(service.icon, 'https://example.com/logo.png');
      expect(service.grantId, '456');
    });

    test('toJson creates correct JSON', () {
      final service = Service(
          id: '123',
          name: 'Test Service',
          scope: ['email', 'profile'],
          icon: 'https://example.com/logo.png',
          grantId: '456'
      );

      final json = service.toJson();

      expect(json['clientId'], '123');
      expect(json['name'], 'Test Service');
      expect(json['scope'], ['email', 'profile']);
      expect(json['logo_uri'], 'https://example.com/logo.png');
      expect(json['grantId'], '456');
    });

    test('fromJson handles missing logo_uri', () {
      final json = {
        'clientId': '123',
        'name': 'Test Service',
        'scope': ['email', 'openid', 'profile'],
        'grantId': '456'
      };

      final service = Service.fromJson(json);

      expect(service.icon, '');
    });
  });
}