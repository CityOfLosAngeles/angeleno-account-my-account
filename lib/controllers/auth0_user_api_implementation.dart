import 'dart:convert';
import 'dart:io';

import 'package:angeleno_project/models/api_exception.dart';
import 'package:angeleno_project/models/api_response.dart';
import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/utils/constants.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:angeleno_project/controllers/auth0_user_api.dart';
import 'package:angeleno_project/models/user.dart';

class Auth0UserApi extends Api {

  var authToken = '';

  String createJwt() {
    final jwt = JWT(
      {
        'exp': DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch ~/ 1000,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'aud': 'https://www.googleapis.com/oauth2/v4/token',
        'target_audience': cloudFunctionURL
      },
      issuer: serviceAccountEmail,
      subject: serviceAccountEmail,
      header: {
        'alg':'RS256',
        'typ':'JWT'
      }
    );

    final privKey = serviceAccountSecret
        .replaceAll(r'\n', '\n');

    final rsaPrivKey = RSAPrivateKey(privKey);

    return jwt.sign(rsaPrivKey, algorithm: JWTAlgorithm.RS256);

  }

  Future<String> getOAuthToken() async {

    if (authToken.isNotEmpty) {
      final decodedToken = JWT.decode(authToken);
      final tokenExpiration = decodedToken.payload['exp'] as int;
      if (DateTime
          .now()
          .millisecondsSinceEpoch ~/ 1000 < tokenExpiration) {
        return authToken;
      }
    }

    try {
      final jwt = createJwt();

      final response = await http.post(
          Uri.parse('https://www.googleapis.com/oauth2/v4/token'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': 'Bearer $jwt'
          },
          // ignore: lines_longer_than_80_chars
          body: 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$jwt'
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == HttpStatus.ok) {
        final jsonRes = jsonDecode(response.body);
        authToken = jsonRes['id_token'] as String;
        return authToken;
      }
    } catch (err) {
      print(err);
    }

    throw Exception('No token received');
  }

  @override
  Future<int> updateUser(final User user) async {
    late int statusCode;

    try {
      final token = await getOAuthToken();

      if (token.isEmpty) {
        throw const FormatException('Empty token received');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      final body = json.encode(user);

      final response = await http.post(
          Uri.parse('/auth0/updateUser'),
          headers: headers,
          body: body
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == HttpStatus.ok) {
        print(response.body);
      } else {
        print(response);
      }

      statusCode = response.statusCode;
    } catch (err) {
      print (err);
      // generic server error
      statusCode = HttpStatus.internalServerError;
    }

    return statusCode;
  }

  @override
  Future<Map<String, dynamic>> updatePassword(final PasswordBody body) async {
    late Map<String, dynamic> response;

    final token = await getOAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final reqBody = json.encode(body);

    try {
      final request = await http.post(
          Uri.parse('/auth0/updatePassword'),
          headers: headers,
          body: reqBody
      ).timeout(const Duration(seconds: 5));

      response = {
        'status': request.statusCode,
        'body': request.body.isNotEmpty ? request.body : 'Error Encountered'
      };
    } catch (err) {
      print (err);
      // generic server error
      response = {
        'status': HttpStatus.internalServerError,
        'body': 'Error Encountered'
      };
    }

    return response;
  }

  @override
  Future<ApiResponse> getAuthenticationMethods(final String userId) async {

    final token = await getOAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    try {
      final request = await http.get(
          Uri.parse('/auth0/authMethods/$userId'),
          headers: headers
      ).timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, request.body);
      } else {
        throw ApiException(request.statusCode, request.body);
      }

    } on ApiException catch(e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered');
    }
  }

  @override
  Future<Map<String, dynamic>>
    enrollMFA(final Map<String, String> body) async {
    late Map<String, dynamic> response;

    final token = await getOAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final reqBody = json.encode(body);

    try {
      final request = await http.post(
          Uri.parse('/auth0/enrollMFA'),
          headers: headers,
          body: reqBody
      ).timeout(const Duration(seconds: 5));

      final jsonBody = jsonDecode(request.body);
      final barcode = jsonBody['barcode_uri'] ?? '';
      final token = jsonBody['token'] ?? '';
      final tokenSecret = jsonBody['secret'] ?? '';
      final oobCode = jsonBody['oob_code'] ?? '';

      if (request.statusCode == HttpStatus.ok) {
        response = {
          'status': request.statusCode,
          'body': request.body,
          'barcode': barcode,
          'token': token,
          'barcode_string': tokenSecret,
          'oobCode': oobCode
        };
      } else {
        throw ApiException(request.statusCode, request.body);
      }

    } on ApiException catch(e) {
      response = {
        'status': e.statusCode,
        'body': e.error
      };
    } catch (err) {
      response = {
        'status': HttpStatus.internalServerError,
        'body': 'Error Encountered'
      };
    }

    return response;
  }

  @override
  Future<ApiResponse> confirmMFA(final Map<String, String> body) async {

    final token = await getOAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final reqBody = json.encode(body);

    try {
      final request = await http.post(
          Uri.parse('/auth0/confirmMFA'),
          headers: headers,
          body: reqBody
      ).timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, '');
      } else {
        throw ApiException(request.statusCode, request.body);
      }

    }  on ApiException catch(e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered.');
    }
  }

  @override
  Future<ApiResponse> unenrollMFA(final Map<String, String> body) async {

    final token = await getOAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final reqBody = json.encode(body);

    try {
      final request = await http.post(
          Uri.parse('/auth0/unenrollMFA'),
          headers: headers,
          body: reqBody
      ).timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, '');
      } else {
        throw ApiException(request.statusCode, request.body);
      }

    }  on ApiException catch(e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered');
    }
  }

  @override
  Future<ApiResponse> removeConnection(final String connectionId) async {

    final token = await getOAuthToken();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final reqBody = json.encode({
      'connectionId': connectionId
    });

    try {
      final request = await http.post(
          Uri.parse('/auth0/removeConnection'),
          headers: headers,
          body: reqBody
      ).timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, '');
      } else {
        throw ApiException(request.statusCode, request.body);
      }

    }  on ApiException catch(e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered');
    }
  }
}