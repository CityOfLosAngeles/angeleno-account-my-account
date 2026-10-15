import 'dart:convert';
import 'dart:io';

import 'package:angeleno_project/controllers/auth0_user_api.dart';
import 'package:angeleno_project/controllers/user_provider.dart';
import 'package:angeleno_project/models/api_exception.dart';
import 'package:angeleno_project/models/api_response.dart';
import 'package:angeleno_project/models/password_reset.dart';
import 'package:angeleno_project/models/user.dart';
import 'package:http/http.dart' as http;

import '../models/mfa_response.dart';

class Auth0UserApi extends Api {
  final UserProvider userProvider;
  Auth0UserApi(this.userProvider);

  var authToken = '';

  @override
  Future<int> updateUser(final User user) async {
    late int statusCode;

    try {
      final headers = {
        'Content-Type': 'application/json',
        'X-ACCESS-TOKEN': userProvider.getAccessToken()!
      };

      final body = json.encode(user);

      final response = await http
          .post(Uri.parse('/auth0/updateUser'), headers: headers, body: body)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == HttpStatus.ok) {
        print(response.body);
      } else {
        print(response);
      }

      statusCode = response.statusCode;
    } catch (err) {
      print(err);
      // generic server error
      statusCode = HttpStatus.internalServerError;
    }

    return statusCode;
  }

  @override
  Future<Map<String, dynamic>> updatePassword(final PasswordBody body) async {
    late Map<String, dynamic> response;

    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode(body);

    try {
      final request = await http
          .post(Uri.parse('/auth0/updatePassword'),
              headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      response = {
        'status': request.statusCode,
        'body': request.body.isNotEmpty ? request.body : 'Error Encountered'
      };
    } catch (err) {
      print(err);
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
    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    try {
      final request = await http
          .get(Uri.parse('/auth0/authMethods?userId=$userId'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, request.body);
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered');
    }
  }

  @override
  Future<Map<String, dynamic>> enrollMFA(final Map<String, String> body) async {
    late Map<String, dynamic> response;

    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode(body);

    try {
      final request = await http
          .post(Uri.parse('/auth0/enrollMFA'), headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      final mfaRes = MfaResponse.fromJson(
          jsonDecode(request.body) as Map<String, dynamic>);

      if (request.statusCode == HttpStatus.ok ||
          request.statusCode == HttpStatus.unauthorized) {
        response = {'status': request.statusCode, 'body': mfaRes};
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      response = {
        'status': e.statusCode,
        'body': MfaResponse(errorMessage: e.error)
      };
    } catch (err) {
      response = {
        'status': HttpStatus.internalServerError,
        'body': MfaResponse(errorMessage: 'Error Encountered')
      };
    }

    return response;
  }

  @override
  Future<ApiResponse> confirmMFA(final Map<String, String> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode(body);

    try {
      final request = await http
          .post(Uri.parse('/auth0/confirmMFA'), headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, '');
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered.');
    }
  }

  @override
  Future<ApiResponse> unenrollMFA(final Map<String, String> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode(body);

    try {
      final request = await http
          .post(Uri.parse('/auth0/unenrollMFA'),
              headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, '');
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered');
    }
  }

  Future<ApiResponse> challengeMFA(final Map<String, String> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode(body);

    try {
      final request = await http
          .post(Uri.parse('/auth0/challengeMfa'),
              headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, request.body);
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered.');
    }
  }

  Future<ApiResponse> requestMFAToken(final Map<String, String> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode(body);

    try {
      final request = await http
          .post(Uri.parse('/auth0/requestMFAToken'),
              headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, request.body);
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered.');
    }
  }

  @override
  Future<ApiResponse> removeConnection(final String connectionId) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-ACCESS-TOKEN': userProvider.getAccessToken()!
    };

    final reqBody = json.encode({'connectionId': connectionId});

    try {
      final request = await http
          .post(Uri.parse('/auth0/removeConnection'),
              headers: headers, body: reqBody)
          .timeout(const Duration(seconds: 5));

      if (request.statusCode == HttpStatus.ok) {
        return ApiResponse(request.statusCode, '');
      } else {
        throw ApiException(request.statusCode, request.body);
      }
    } on ApiException catch (e) {
      return ApiResponse(e.statusCode, e.error);
    } catch (err) {
      return ApiResponse(HttpStatus.internalServerError, 'Error Encountered');
    }
  }
}
