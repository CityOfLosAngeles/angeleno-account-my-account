import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_exception.dart' as api_exception;
import 'package:angeleno_project/models/connected_applications_model.dart';
import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angeleno_project/models/mfa_response.dart';
import 'package:angeleno_project/models/mfa_method.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';


void main() {

  late UserProvider userProvider;

  setUp(() {
    userProvider = UserProvider();
  });

  group('ApiException', () {
    test('Should return error message from JSON body', () {
      const int statusCode = 404;
      const String responseBody = '{"error": "Resource not found"}';
      final api_exception.ApiException apiException = api_exception.ApiException(statusCode, responseBody);

      final error = apiException.error;

      expect(error, 'Resource not found');
    });

    test('Should return default error message when JSON decoding fails', () {
      const int statusCode = 500;
      const String responseBody = 'Internal Server Error';
      final api_exception.ApiException apiException = api_exception.ApiException(statusCode, responseBody);

      final error = apiException.error;

      expect(error, 'Error encountered');
    });

    test('Should return default error message when body is null', () {

      const int statusCode = 400;
      final api_exception.ApiException apiException = api_exception.ApiException(statusCode, null);

      final error = apiException.error;

      expect(error, 'Error encountered');
    });

    test('Should return error message when body contains error in body', () {

      const int statusCode = 418;
      const String responseBody = '{"error": "I\'m a teapot"}';
      final api_exception.ApiException apiException = api_exception.ApiException(statusCode, responseBody);

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
    test('User constructor initializes correctly', () {
      final user = User(
        userId: '123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        address: '123 Main St',
        address2: 'Apt 4B',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
        phone: '1234567890',
        metadata: {'key': 'value'},
      );

      expect(user.userId, '123');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.address, '123 Main St');
      expect(user.address2, 'Apt 4B');
      expect(user.city, 'Los Angeles');
      expect(user.state, 'CA');
      expect(user.zip, '90001');
      expect(user.phone, '1234567890');
      expect(user.metadata, {'key': 'value'});
    });

    test('User.copy creates a deep copy', () {
      final original = User(
        userId: '123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        address: '123 Main St',
        address2: 'Apt 4B',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
        phone: '1234567890',
        metadata: {'key': 'value'},
      );

      final copy = User.copy(original);

      expect(copy, original);
      expect(copy.hashCode, original.hashCode);
    });

    test('toJson converts User to a Map', () {
      final user = User(
        userId: '123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        address: '123 Main St',
        address2: 'Apt 4B',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
        phone: '1234567890',
        metadata: {'key': 'value'},
      );

      final json = user.toJson();

      expect(json, {
        'userId': '123',
        'email': 'test@example.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'address': '123 Main St',
        'address2': 'Apt 4B',
        'city': 'Los Angeles',
        'state': 'CA',
        'zip': '90001',
        'phone': '1234567890',
        'metadata': {'key': 'value'},
      });
    });

    test('Equality operator works correctly', () {
      final user1 = User(
        userId: '123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        address: '123 Main St',
        address2: 'Apt 4B',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
        phone: '1234567890',
        metadata: {'key': 'value'},
      );

      final user2 = User.copy(user1);

      expect(user1 == user2, true);
    });
  });

  group('Address', () {
    test('Address constructor initializes correctly', () {
      final address = Address(
        address: '123 Main St',
        address2: 'Apt 4B',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
      );

      expect(address.address, '123 Main St');
      expect(address.address2, 'Apt 4B');
      expect(address.city, 'Los Angeles');
      expect(address.state, 'CA');
      expect(address.zip, '90001');
    });

    test('toJson converts Address to a Map', () {
      final address = Address(
        address: '123 Main St',
        address2: 'Apt 4B',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90001',
      );

      final json = address.toJson();

      expect(json, {
        'address': '123 Main St',
        'address2': 'Apt 4B',
        'city': 'Los Angeles',
        'state': 'CA',
        'zip': '90001',
      });
    });

    test('fromJson creates Address from a Map', () {
      final json = {
        'address': '123 Main St',
        'address2': 'Apt 4B',
        'city': 'Los Angeles',
        'state': 'CA',
        'zip': '90001',
      };

      final address = Address.fromJson(json);

      expect(address.address, '123 Main St');
      expect(address.address2, 'Apt 4B');
      expect(address.city, 'Los Angeles');
      expect(address.state, 'CA');
      expect(address.zip, '90001');
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

  group('MFA Response', () {
    test('fromJson creates an instance with correct values', () {
      final json = {
        'token': 'test_token',
        'barcode_uri': 'test_barcode',
        'secret': 'test_secret',
        'oob_code': 'test_oob_code',
        'error': 'test_error'
      };

      final response = MfaResponse.fromJson(json);

      expect(response.token, 'test_token');
      expect(response.barcode, 'test_barcode');
      expect(response.barcodeString, 'test_secret');
      expect(response.oobCode, 'test_oob_code');
      expect(response.errorMessage, 'test_error');
    });

    test('fromJson handles missing fields gracefully', () {
      final Map<String, dynamic>json = {};

      final response = MfaResponse.fromJson(json);

      expect(response.token, '');
      expect(response.barcode, '');
      expect(response.barcodeString, '');
      expect(response.oobCode, '');
      expect(response.errorMessage, '');
    });

    test('toString returns correct string representation', () {
      final response = MfaResponse(
          token: 'test_token',
          barcode: 'test_barcode',
          barcodeString: 'test_secret',
          oobCode: 'test_oob_code'
      );

      expect(response.toString(), '{barcode: test_barcode, token: test_token, barcodeString: test_secret, oobCode: test_oob_code}');
    });

    test('constructor initializes fields with default values', () {
      final response = MfaResponse();

      expect(response.token, '');
      expect(response.barcode, '');
      expect(response.barcodeString, '');
      expect(response.oobCode, '');
      expect(response.errorMessage, '');
    });

    test('constructor initializes fields with provided values', () {
      final response = MfaResponse(
          token: 'test_token',
          barcode: 'test_barcode',
          barcodeString: 'test_secret',
          oobCode: 'test_oob_code',
          errorMessage: 'test_error'
      );

      expect(response.token, 'test_token');
      expect(response.barcode, 'test_barcode');
      expect(response.barcodeString, 'test_secret');
      expect(response.oobCode, 'test_oob_code');
      expect(response.errorMessage, 'test_error');
    });
  });

  group('MFA Method', () {
    test('fromJson creates an instance with correct values', () {
      final json = {
        'id': 'test_id',
        'authenticator_type': 'test_type',
        'active': true,
        'oob_channel': 'test_channel',
        'name': 'test_name'
      };

      final method = MfaMethod.fromJson(json);

      expect(method.id, 'test_id');
      expect(method.authenticatorType, 'test_type');
      expect(method.active, true);
      expect(method.oobChannel, 'test_channel');
      expect(method.name, 'test_name');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = {
        'id': 'test_id',
        'authenticator_type': 'test_type',
        'active': true
      };

      final method = MfaMethod.fromJson(json);

      expect(method.id, 'test_id');
      expect(method.authenticatorType, 'test_type');
      expect(method.active, true);
      expect(method.oobChannel, '');
      expect(method.name, '');
    });

    test('toJson returns correct map representation', () {
      final method = MfaMethod(
          id: 'test_id',
          authenticatorType: 'test_type',
          active: true,
          oobChannel: 'test_channel',
          name: 'test_name'
      );

      final json = method.toJson();

      expect(json['id'], 'test_id');
      expect(json['authenticator_type'], 'test_type');
      expect(json['active'], true);
      expect(json['oob_channel'], 'test_channel');
      expect(json['name'], 'test_name');
    });

    test('constructor initializes fields with default values', () {
      final method = MfaMethod();

      expect(method.id, '');
      expect(method.authenticatorType, '');
      expect(method.active, false);
      expect(method.oobChannel, '');
      expect(method.name, '');
    });

    test('constructor initializes fields with provided values', () {
      final method = MfaMethod(
          id: 'test_id',
          authenticatorType: 'test_type',
          active: true,
          oobChannel: 'test_channel',
          name: 'test_name'
      );

      expect(method.id, 'test_id');
      expect(method.authenticatorType, 'test_type');
      expect(method.active, true);
      expect(method.oobChannel, 'test_channel');
      expect(method.name, 'test_name');
    });
  });

  group('UserProvider setUser', () {
    test('Handles valid metadata with primary address', () {
      final userProvider = UserProvider();
      final userProfile = UserProfile(
        sub: '123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
        customClaims: {
          'user_metadata': {
            'addresses': {
              'primary': {
                'address': '123 Main St',
                'address2': 'Apt 4B',
                'city': 'Los Angeles',
                'state': 'CA',
                'zip': '90001',
              },
            },
            'phone': '1234567890',
          },
        },
      );

      userProvider.setUser(userProfile);

      final user = userProvider.user!;
      expect(user.address, '123 Main St');
      expect(user.address2, 'Apt 4B');
      expect(user.city, 'Los Angeles');
      expect(user.state, 'CA');
      expect(user.zip, '90001');
      expect(user.phone, '1234567890');
    });

    test('Handles missing metadata gracefully', () {
      final userProvider = UserProvider();
      final userProfile = UserProfile(
        sub: '123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
        customClaims: null,
      );

      userProvider.setUser(userProfile);

      final user = userProvider.user!;
      expect(user.address, isEmpty);
      expect(user.address2, isEmpty);
      expect(user.city, isEmpty);
      expect(user.state, isEmpty);
      expect(user.zip, isEmpty);
      expect(user.phone, isEmpty);
    });

    test('Handles metadata without addresses', () {
      final userProvider = UserProvider();
      final userProfile = UserProfile(
        sub: '123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
        customClaims: {
          'user_metadata': {
            'phone': '1234567890',
          },
        },
      );

      userProvider.setUser(userProfile);

      final user = userProvider.user!;
      expect(user.address, isEmpty);
      expect(user.address2, isEmpty);
      expect(user.city, isEmpty);
      expect(user.state, isEmpty);
      expect(user.zip, isEmpty);
      expect(user.phone, '1234567890');
    });

    test('Handles metadata with empty primary address', () {
      final userProvider = UserProvider();
      final userProfile = UserProfile(
        sub: '123',
        email: 'test@example.com',
        givenName: 'John',
        familyName: 'Doe',
        customClaims: {
          'user_metadata': {
            'addresses': {
              'primary': <String, dynamic>{},
            },
            'phone': '1234567890',
          },
        },
      );

      userProvider.setUser(userProfile);

      final user = userProvider.user!;
      expect(user.address, isEmpty);
      expect(user.address2, isEmpty);
      expect(user.city, isEmpty);
      expect(user.state, isEmpty);
      expect(user.zip, isEmpty);
      expect(user.phone, '1234567890');
    });
  });
}