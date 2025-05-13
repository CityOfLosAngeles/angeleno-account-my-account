import 'dart:convert';

class ApiException implements Exception {
  final int statusCode;
  final String? body;

  String get error {
    try {
      final errJson = jsonDecode(body!);
      return errJson['error'] as String;
    } catch (err) {
      return 'Error encountered';
    }
  }

  ApiException(this.statusCode, this.body);
}
